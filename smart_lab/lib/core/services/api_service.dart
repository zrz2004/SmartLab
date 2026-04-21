import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../constants/api_endpoints.dart';

class ApiService {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://47.109.158.254:3000/api/v1',
  );
  static const Duration _timeout = Duration(seconds: 30);

  final Logger _logger = Logger();
  late final Dio _dio;

  String? _accessToken;
  String? _refreshToken;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: _timeout,
        receiveTimeout: _timeout,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          _logger.d('API request: ${options.method} ${options.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d('API response: ${response.statusCode}');
          handler.next(response);
        },
        onError: (error, handler) async {
          _logger.e('API error: ${error.message}');

          if (error.response?.statusCode == 401 && _refreshToken != null) {
            try {
              await _refreshAccessToken();
              final requestOptions = error.requestOptions;
              requestOptions.headers['Authorization'] = 'Bearer $_accessToken';
              final retryResponse = await _dio.fetch(requestOptions);
              handler.resolve(retryResponse);
              return;
            } catch (_) {
              _accessToken = null;
              _refreshToken = null;
            }
          }

          handler.next(error);
        },
      ),
    );
  }

  void setTokens({
    required String accessToken,
    required String refreshToken,
  }) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  Future<void> _refreshAccessToken() async {
    final response = await _dio.post(
      ApiEndpoints.refreshToken,
      data: {'refresh_token': _refreshToken},
      options: Options(headers: {'Authorization': null}),
    );

    if (response.statusCode == 200) {
      _accessToken = response.data['access_token'] as String?;
      _refreshToken = response.data['refresh_token'] as String?;
    }
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.login,
      data: {
        'username': username,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = Map<String, dynamic>.from(response.data as Map);
      setTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );
      return data;
    }

    throw DioException(
      requestOptions: response.requestOptions,
      message: '登录失败',
    );
  }

  Future<Map<String, dynamic>> registerUser({
    required String username,
    required String password,
    required String name,
    required String email,
    String? phone,
    String requestedRole = 'undergraduate',
  }) async {
    final response = await _dio.post(
      ApiEndpoints.register,
      data: {
        'username': username,
        'password': password,
        'name': name,
        'email': email,
        'phone': phone,
        'requested_role': requestedRole,
      },
      options: Options(headers: {'Authorization': null}),
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> logout() async {
    await _dio.post(ApiEndpoints.logout);
    _accessToken = null;
    _refreshToken = null;
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _dio.get(ApiEndpoints.profile);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> getPendingRegistrations() async {
    final response = await _dio.get(ApiEndpoints.pendingRegistrations);
    return List<Map<String, dynamic>>.from(response.data as List);
  }

  Future<Map<String, dynamic>> approveRegistration({
    required String requestId,
    required List<String> labIds,
    required String role,
  }) async {
    final response = await _dio.post(
      '${ApiEndpoints.pendingRegistrations}/$requestId/approve',
      data: {
        'lab_ids': labIds,
        'role': role,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> rejectRegistration({
    required String requestId,
    required String reason,
  }) async {
    final response = await _dio.post(
      '${ApiEndpoints.pendingRegistrations}/$requestId/reject',
      data: {'reason': reason},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> getPermissionsMe() async {
    final response = await _dio.get(ApiEndpoints.permissionsMe);
    return List<Map<String, dynamic>>.from(response.data as List);
  }

  Future<List<Map<String, dynamic>>> getAccessibleLabs() async {
    final response = await _dio.get(ApiEndpoints.accessibleLabs);
    return List<Map<String, dynamic>>.from(response.data as List);
  }

  Future<Map<String, dynamic>> selectLab(String labId) async {
    final response = await _dio.post(
      ApiEndpoints.selectLab,
      data: {'lab_id': labId},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getLabContext(String labId) async {
    final response = await _dio.get(ApiEndpoints.labContext(labId));
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> uploadMedia({
    required List<int> fileBytes,
    required String fileName,
    required String labId,
    required String sceneType,
    required String deviceType,
    String? targetId,
  }) async {
    final formData = FormData.fromMap({
      'lab_id': labId,
      'scene_type': sceneType,
      'device_type': deviceType,
      'target_id': targetId,
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: fileName,
      ),
    });

    final response = await _dio.post(
      ApiEndpoints.mediaUpload,
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> createAiInspection({
    required Map<String, dynamic> payload,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.aiInspections,
      data: payload,
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getAiInspection(String inspectionId) async {
    final response = await _dio.get('${ApiEndpoints.aiInspections}/$inspectionId');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> getDevices({
    String? roomId,
    String? type,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.devices,
      queryParameters: {
        if (roomId != null) 'roomId': roomId,
        if (type != null) 'type': type,
      },
    );

    return List<Map<String, dynamic>>.from(response.data as List);
  }

  Future<Map<String, dynamic>> getDeviceDetail(String deviceId) async {
    final response = await _dio.get('${ApiEndpoints.devices}/$deviceId');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<bool> controlDevice({
    required String deviceId,
    required String action,
    String? twoFactorToken,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.controlSwitch,
      data: {
        'deviceId': deviceId,
        'action': action,
        if (twoFactorToken != null) 'token': twoFactorToken,
      },
    );

    return response.statusCode == 200;
  }

  Future<List<Map<String, dynamic>>> getTelemetryHistory({
    required String deviceId,
    required DateTime start,
    required DateTime end,
    String interval = '1h',
  }) async {
    final response = await _dio.get(
      ApiEndpoints.telemetryHistory,
      queryParameters: {
        'deviceId': deviceId,
        'start': start.millisecondsSinceEpoch ~/ 1000,
        'end': end.millisecondsSinceEpoch ~/ 1000,
        'interval': interval,
      },
    );

    return List<Map<String, dynamic>>.from(response.data as List);
  }

  Future<List<Map<String, dynamic>>> getChemicalInventory({
    String? status,
    String? cabinetId,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.chemicalInventory,
      queryParameters: {
        if (status != null) 'status': status,
        if (cabinetId != null) 'cabinetId': cabinetId,
      },
    );

    return List<Map<String, dynamic>>.from(response.data as List);
  }

  Future<Map<String, dynamic>> getChemicalDetail(String chemicalId) async {
    final response = await _dio.get('${ApiEndpoints.chemicalInventory}/$chemicalId');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> getChemicalLogs({
    String? chemicalId,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '${ApiEndpoints.chemicalInventory}/logs',
      queryParameters: {
        if (chemicalId != null) 'chemicalId': chemicalId,
        'limit': limit,
      },
    );

    return List<Map<String, dynamic>>.from(response.data as List);
  }

  Future<List<Map<String, dynamic>>> getAlerts({
    String? level,
    bool? acknowledged,
    int limit = 50,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.alerts,
      queryParameters: {
        if (level != null) 'level': level,
        if (acknowledged != null) 'acknowledged': acknowledged,
        'limit': limit,
      },
    );

    return List<Map<String, dynamic>>.from(response.data as List);
  }

  Future<bool> acknowledgeAlert(String alertId) async {
    final response = await _dio.post(ApiEndpoints.acknowledgeAlert(alertId));
    return response.statusCode == 200;
  }

  Future<List<Map<String, dynamic>>> getLabs() async {
    final response = await _dio.get(ApiEndpoints.labs);
    return List<Map<String, dynamic>>.from(response.data as List);
  }

  Future<Map<String, dynamic>> getLabSafetyScore(String labId) async {
    final response = await _dio.get('${ApiEndpoints.labs}/$labId/safety-score');
    return Map<String, dynamic>.from(response.data as Map);
  }
}
