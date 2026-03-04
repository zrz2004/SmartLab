import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../constants/api_endpoints.dart';

/// API 服务
/// 
/// 负责与后端 REST API 通信
/// - 设备管理
/// - 用户认证
/// - 历史数据查询
/// - 危化品管理
class ApiService {
  // 生产服务器地址
  static const String _baseUrl = 'http://47.109.158.254:3000/api/v1';
  static const Duration _timeout = Duration(seconds: 30);
  
  final Logger _logger = Logger();
  late final Dio _dio;
  
  String? _accessToken;
  String? _refreshToken;
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: _timeout,
      receiveTimeout: _timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    _setupInterceptors();
  }
  
  /// 配置拦截器
  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // 添加认证 Token
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        _logger.d('API 请求: ${options.method} ${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        _logger.d('API 响应: ${response.statusCode}');
        handler.next(response);
      },
      onError: (error, handler) async {
        _logger.e('API 错误: ${error.message}');
        
        // Token 过期，尝试刷新
        if (error.response?.statusCode == 401 && _refreshToken != null) {
          try {
            await _refreshAccessToken();
            // 重试原请求
            final retryResponse = await _dio.fetch(error.requestOptions);
            handler.resolve(retryResponse);
            return;
          } catch (e) {
            // Token 刷新失败，需要重新登录
            _accessToken = null;
            _refreshToken = null;
          }
        }
        
        handler.next(error);
      },
    ));
  }
  
  /// 设置 Token
  void setTokens({required String accessToken, required String refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }
  
  /// 刷新 Access Token
  Future<void> _refreshAccessToken() async {
    final response = await _dio.post(
      ApiEndpoints.refreshToken,
      data: {'refresh_token': _refreshToken},
      options: Options(headers: {'Authorization': null}),
    );
    
    if (response.statusCode == 200) {
      _accessToken = response.data['access_token'];
      _refreshToken = response.data['refresh_token'];
    }
  }
  
  // ==================== 认证接口 ====================
  
  /// 用户登录
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
      final data = response.data;
      setTokens(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
      );
      return data;
    }
    
    throw DioException(
      requestOptions: response.requestOptions,
      message: '登录失败',
    );
  }
  
  /// 用户登出
  Future<void> logout() async {
    await _dio.post(ApiEndpoints.logout);
    _accessToken = null;
    _refreshToken = null;
  }
  
  // ==================== 设备接口 ====================
  
  /// 获取设备列表
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
    
    return List<Map<String, dynamic>>.from(response.data);
  }
  
  /// 获取设备详情
  Future<Map<String, dynamic>> getDeviceDetail(String deviceId) async {
    final response = await _dio.get('${ApiEndpoints.devices}/$deviceId');
    return response.data;
  }
  
  /// 控制设备
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
  
  // ==================== 遥测数据接口 ====================
  
  /// 获取历史遥测数据
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
    
    return List<Map<String, dynamic>>.from(response.data);
  }
  
  // ==================== 危化品接口 ====================
  
  /// 获取危化品库存
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
    
    return List<Map<String, dynamic>>.from(response.data);
  }
  
  /// 获取危化品详情
  Future<Map<String, dynamic>> getChemicalDetail(String chemicalId) async {
    final response = await _dio.get('${ApiEndpoints.chemicalInventory}/$chemicalId');
    return response.data;
  }
  
  /// 获取危化品操作日志
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
    
    return List<Map<String, dynamic>>.from(response.data);
  }
  
  // ==================== 报警接口 ====================
  
  /// 获取报警列表
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
    
    return List<Map<String, dynamic>>.from(response.data);
  }
  
  /// 确认报警
  Future<bool> acknowledgeAlert(String alertId) async {
    final response = await _dio.post(
      '${ApiEndpoints.alerts}/$alertId/acknowledge',
    );
    
    return response.statusCode == 200;
  }
  
  // ==================== 实验室接口 ====================
  
  /// 获取实验室列表
  Future<List<Map<String, dynamic>>> getLabs() async {
    final response = await _dio.get(ApiEndpoints.labs);
    return List<Map<String, dynamic>>.from(response.data);
  }
  
  /// 获取实验室安全评分
  Future<Map<String, dynamic>> getLabSafetyScore(String labId) async {
    final response = await _dio.get('${ApiEndpoints.labs}/$labId/safety-score');
    return response.data;
  }
}
