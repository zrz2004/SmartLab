import 'dart:async';
import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../../features/alerts/domain/entities/alert.dart';
import '../../features/dashboard/domain/entities/sensor_data.dart';
import '../constants/mqtt_topics.dart';

class MqttService {
  static const String _broker = '47.109.158.254';
  static const int _port = 1883;
  static const String _clientId = 'smartlab_app_';

  final Logger _logger = Logger();
  MqttServerClient? _client;
  bool _isConnected = false;

  final _sensorDataController = StreamController<SensorData>.broadcast();
  final _alertController = StreamController<Alert>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  Stream<SensorData> get sensorDataStream => _sensorDataController.stream;
  Stream<Alert> get alertStream => _alertController.stream;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  bool get isConnected => _isConnected;

  Future<bool> connect({
    required String username,
    required String password,
  }) async {
    try {
      final clientId = '$_clientId${DateTime.now().millisecondsSinceEpoch}';
      _client = MqttServerClient.withPort(_broker, clientId, _port)
        ..logging(on: false)
        ..keepAlivePeriod = 30
        ..onConnected = _onConnected
        ..onDisconnected = _onDisconnected
        ..onSubscribed = _onSubscribed
        ..autoReconnect = true
        ..onAutoReconnect = _onAutoReconnect
        ..onAutoReconnected = _onAutoReconnected
        ..secure = false;

      _client!.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .authenticateAs(username, password)
          .withWillTopic('lab/client/disconnected')
          .withWillMessage(clientId)
          .withWillQos(MqttQos.atLeastOnce)
          .startClean();

      _logger.i('MQTT connecting to $_broker:$_port');
      await _client!.connect();

      if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
        _isConnected = true;
        _connectionStateController.add(true);
        _subscribeToTopics();
        _setupMessageHandler();
        return true;
      }
      return false;
    } catch (error) {
      _logger.e('MQTT connect failed: $error');
      _isConnected = false;
      _connectionStateController.add(false);
      return false;
    }
  }

  void disconnect() {
    _client?.disconnect();
    _isConnected = false;
    _connectionStateController.add(false);
  }

  void _subscribeToTopics() {
    if (_client == null) return;
    _client!.subscribe(MqttTopics.telemetryWildcard, MqttQos.atLeastOnce);
    _client!.subscribe(MqttTopics.alertWildcard, MqttQos.exactlyOnce);
    _client!.subscribe(MqttTopics.statusWildcard, MqttQos.atLeastOnce);
    _logger.i('MQTT topics subscribed');
  }

  void _setupMessageHandler() {
    _client!.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (final message in messages) {
        final topic = message.topic;
        final payload = message.payload as MqttPublishMessage;
        final data = MqttPublishPayload.bytesToStringAsString(payload.payload.message);
        _handleMessage(topic, data);
      }
    });
  }

  void _handleMessage(String topic, String data) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      if (topic.contains('/telemetry')) {
        _sensorDataController.add(SensorData.fromJson(json));
      } else if (topic.contains('/alert')) {
        _alertController.add(Alert.fromJson(json));
      }
    } catch (error) {
      _logger.e('MQTT decode failed: $error');
    }
  }

  Future<bool> publishCommand({
    required String buildingId,
    required String roomId,
    required String deviceType,
    required String deviceId,
    required Map<String, dynamic> command,
  }) async {
    if (!_isConnected || _client == null) {
      _logger.w('MQTT not connected, command skipped');
      return false;
    }

    try {
      final topic = 'lab/$buildingId/$roomId/$deviceType/$deviceId/cmd';
      final payload = jsonEncode({
        'timestamp': DateTime.now().toIso8601String(),
        'command': command,
      });

      final builder = MqttClientPayloadBuilder()..addString(payload);
      _client!.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
      _logger.i('MQTT command published to $topic');
      return true;
    } catch (error) {
      _logger.e('MQTT publish failed: $error');
      return false;
    }
  }

  void _onConnected() {
    _logger.i('MQTT connected');
    _isConnected = true;
    _connectionStateController.add(true);
  }

  void _onDisconnected() {
    _logger.w('MQTT disconnected');
    _isConnected = false;
    _connectionStateController.add(false);
  }

  void _onSubscribed(String topic) {
    _logger.d('MQTT subscribed: $topic');
  }

  void _onAutoReconnect() {
    _logger.i('MQTT auto reconnecting');
  }

  void _onAutoReconnected() {
    _logger.i('MQTT auto reconnected');
    _subscribeToTopics();
  }

  void dispose() {
    disconnect();
    _sensorDataController.close();
    _alertController.close();
    _connectionStateController.close();
  }
}
