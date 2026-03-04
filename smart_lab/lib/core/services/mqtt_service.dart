import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:logger/logger.dart';

import '../constants/mqtt_topics.dart';
import '../../features/dashboard/domain/entities/sensor_data.dart';
import '../../features/alerts/domain/entities/alert.dart';

/// MQTT 服务
/// 
/// 负责与物联网设备的实时通信
/// - 订阅传感器遥测数据
/// - 订阅报警事件
/// - 发布控制指令
class MqttService {
  // 生产服务器地址（MQTT 暂时禁用，后续部署 EMQX 后启用）
  static const String _broker = '47.109.158.254';
  static const int _port = 1883; // MQTT 标准端口（非 TLS）
  static const String _clientId = 'smartlab_app_';
  
  final Logger _logger = Logger();
  
  MqttServerClient? _client;
  bool _isConnected = false;
  
  // 数据流控制器
  final _sensorDataController = StreamController<SensorData>.broadcast();
  final _alertController = StreamController<Alert>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();
  
  // 公开的数据流
  Stream<SensorData> get sensorDataStream => _sensorDataController.stream;
  Stream<Alert> get alertStream => _alertController.stream;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  
  bool get isConnected => _isConnected;
  
  /// 连接到 MQTT Broker
  Future<bool> connect({
    required String username,
    required String password,
  }) async {
    try {
      final clientId = '$_clientId${DateTime.now().millisecondsSinceEpoch}';
      
      _client = MqttServerClient.withPort(_broker, clientId, _port);
      _client!
        ..logging(on: false)
        ..keepAlivePeriod = 30
        ..onConnected = _onConnected
        ..onDisconnected = _onDisconnected
        ..onSubscribed = _onSubscribed
        ..autoReconnect = true
        ..onAutoReconnect = _onAutoReconnect
        ..onAutoReconnected = _onAutoReconnected;
      
      // TLS 配置（MQTT 服务部署后启用）
      _client!.secure = false; // 暂时禁用 TLS
      // _client!.securityContext = ...; // 生产环境需配置证书
      
      final connMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .authenticateAs(username, password)
          .withWillTopic('lab/client/disconnected')
          .withWillMessage(clientId)
          .withWillQos(MqttQos.atLeastOnce)
          .startClean();
      
      _client!.connectionMessage = connMessage;
      
      _logger.i('MQTT: 正在连接到 $_broker:$_port');
      
      await _client!.connect();
      
      if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
        _isConnected = true;
        _connectionStateController.add(true);
        _subscribeToTopics();
        _setupMessageHandler();
        return true;
      }
      
      return false;
    } catch (e) {
      _logger.e('MQTT 连接失败: $e');
      _isConnected = false;
      _connectionStateController.add(false);
      return false;
    }
  }
  
  /// 断开连接
  void disconnect() {
    _client?.disconnect();
    _isConnected = false;
    _connectionStateController.add(false);
  }
  
  /// 订阅主题
  void _subscribeToTopics() {
    if (_client == null) return;
    
    // 订阅遥测数据 (所有实验室的所有设备)
    _client!.subscribe(MqttTopics.telemetryWildcard, MqttQos.atLeastOnce);
    
    // 订阅报警事件
    _client!.subscribe(MqttTopics.alertWildcard, MqttQos.exactlyOnce);
    
    // 订阅设备状态
    _client!.subscribe(MqttTopics.statusWildcard, MqttQos.atLeastOnce);
    
    _logger.i('MQTT: 已订阅主题');
  }
  
  /// 设置消息处理器
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
  
  /// 处理接收到的消息
  void _handleMessage(String topic, String data) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      
      if (topic.contains('/telemetry')) {
        // 处理遥测数据
        final sensorData = SensorData.fromJson(json);
        _sensorDataController.add(sensorData);
        _logger.d('MQTT: 收到遥测数据 - ${sensorData.deviceId}');
      } else if (topic.contains('/alert')) {
        // 处理报警事件
        final alert = Alert.fromJson(json);
        _alertController.add(alert);
        _logger.w('MQTT: 收到报警 - ${alert.type}');
      }
    } catch (e) {
      _logger.e('MQTT 消息解析失败: $e');
    }
  }
  
  /// 发布控制指令
  Future<bool> publishCommand({
    required String buildingId,
    required String roomId,
    required String deviceType,
    required String deviceId,
    required Map<String, dynamic> command,
  }) async {
    if (!_isConnected || _client == null) {
      _logger.w('MQTT: 未连接，无法发送指令');
      return false;
    }
    
    try {
      final topic = 'lab/$buildingId/$roomId/$deviceType/$deviceId/cmd';
      final payload = jsonEncode({
        'timestamp': DateTime.now().toIso8601String(),
        'command': command,
      });
      
      final builder = MqttClientPayloadBuilder();
      builder.addString(payload);
      
      _client!.publishMessage(
        topic,
        MqttQos.exactlyOnce,
        builder.payload!,
      );
      
      _logger.i('MQTT: 已发送指令到 $topic');
      return true;
    } catch (e) {
      _logger.e('MQTT 发送指令失败: $e');
      return false;
    }
  }
  
  // ==================== 回调函数 ====================
  
  void _onConnected() {
    _logger.i('MQTT: 连接成功');
    _isConnected = true;
    _connectionStateController.add(true);
  }
  
  void _onDisconnected() {
    _logger.w('MQTT: 连接断开');
    _isConnected = false;
    _connectionStateController.add(false);
  }
  
  void _onSubscribed(String topic) {
    _logger.d('MQTT: 已订阅 $topic');
  }
  
  void _onAutoReconnect() {
    _logger.i('MQTT: 正在自动重连...');
  }
  
  void _onAutoReconnected() {
    _logger.i('MQTT: 自动重连成功');
    _subscribeToTopics();
  }
  
  /// 释放资源
  void dispose() {
    disconnect();
    _sensorDataController.close();
    _alertController.close();
    _connectionStateController.close();
  }
}
