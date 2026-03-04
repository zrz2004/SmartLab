---
name: smartlab-backend-database
description: 智慧实验室安全监测系统后端与数据库规范。涵盖 API 设计、数据模型、本地存储、网络请求、安全实践等方面。适用于 Flutter 应用的数据层开发。
license: MIT
metadata:
  author: SmartLab Team
  version: "1.0.0"
  patterns: ["Repository Pattern", "Clean Architecture"]
  storage: ["SQLite", "Hive", "SharedPreferences"]
---

# 后端与数据库规范

智慧实验室安全监测与预警系统的数据层架构规范，涵盖本地数据库、远程 API、数据同步、缓存策略等方面。

## 适用场景

在以下情况下参考本指南：
- 设计数据模型和数据库架构
- 实现 API 调用和数据同步
- 配置本地存储和缓存策略
- 处理离线数据和断线重连
- 实现数据加密和安全存储

## 架构概述

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│                     (BLoC / Widgets)                    │
└─────────────────────┬───────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────┐
│                     Domain Layer                         │
│            (Entities / UseCases / Repositories)          │
└─────────────────────┬───────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────┐
│                      Data Layer                          │
│   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐  │
│   │   Remote    │   │    Local    │   │    Cache    │  │
│   │ DataSource  │   │ DataSource  │   │   Manager   │  │
│   └─────────────┘   └─────────────┘   └─────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## 数据模型规范

### Entity (领域实体)
```dart
// 领域层实体 - 纯业务对象
class SensorReading extends Equatable {
  final String id;
  final String sensorId;
  final double value;
  final String unit;
  final DateTime timestamp;
  final SensorStatus status;
  
  const SensorReading({
    required this.id,
    required this.sensorId,
    required this.value,
    required this.unit,
    required this.timestamp,
    required this.status,
  });
  
  @override
  List<Object?> get props => [id, sensorId, value, unit, timestamp, status];
}
```

### Model (数据模型)
```dart
// 数据层模型 - 处理序列化/反序列化
@JsonSerializable()
class SensorReadingModel extends SensorReading {
  const SensorReadingModel({
    required super.id,
    required super.sensorId,
    required super.value,
    required super.unit,
    required super.timestamp,
    required super.status,
  });
  
  // JSON 序列化
  factory SensorReadingModel.fromJson(Map<String, dynamic> json) =>
      _$SensorReadingModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$SensorReadingModelToJson(this);
  
  // 从数据库映射
  factory SensorReadingModel.fromDatabase(Map<String, dynamic> row) {
    return SensorReadingModel(
      id: row['id'] as String,
      sensorId: row['sensor_id'] as String,
      value: row['value'] as double,
      unit: row['unit'] as String,
      timestamp: DateTime.parse(row['timestamp'] as String),
      status: SensorStatus.values[row['status'] as int],
    );
  }
  
  // 转换为数据库格式
  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'sensor_id': sensorId,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'status': status.index,
    };
  }
}
```

### DTO (数据传输对象)
```dart
// API 请求/响应对象
@JsonSerializable()
class SensorReadingResponse {
  final List<SensorReadingModel> data;
  final PaginationInfo pagination;
  final String? message;
  
  const SensorReadingResponse({
    required this.data,
    required this.pagination,
    this.message,
  });
  
  factory SensorReadingResponse.fromJson(Map<String, dynamic> json) =>
      _$SensorReadingResponseFromJson(json);
}
```

## 本地数据库规范

### SQLite 表设计
```sql
-- 传感器表
CREATE TABLE sensors (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  location TEXT NOT NULL,
  unit TEXT NOT NULL,
  min_value REAL,
  max_value REAL,
  warning_threshold REAL,
  danger_threshold REAL,
  status INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

-- 传感器读数表
CREATE TABLE sensor_readings (
  id TEXT PRIMARY KEY,
  sensor_id TEXT NOT NULL,
  value REAL NOT NULL,
  status INTEGER NOT NULL,
  timestamp TEXT NOT NULL,
  synced INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (sensor_id) REFERENCES sensors(id) ON DELETE CASCADE
);

-- 创建索引提高查询性能
CREATE INDEX idx_readings_sensor_id ON sensor_readings(sensor_id);
CREATE INDEX idx_readings_timestamp ON sensor_readings(timestamp);
CREATE INDEX idx_readings_synced ON sensor_readings(synced);

-- 警报表
CREATE TABLE alerts (
  id TEXT PRIMARY KEY,
  sensor_id TEXT,
  severity INTEGER NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  location TEXT NOT NULL,
  status INTEGER NOT NULL DEFAULT 0,
  acknowledged_at TEXT,
  acknowledged_by TEXT,
  resolved_at TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (sensor_id) REFERENCES sensors(id) ON DELETE SET NULL
);

CREATE INDEX idx_alerts_status ON alerts(status);
CREATE INDEX idx_alerts_severity ON alerts(severity);
CREATE INDEX idx_alerts_created_at ON alerts(created_at);
```

### Hive Box 规范
```dart
// 用于轻量级数据和缓存
@HiveType(typeId: 0)
class CachedSensorReading extends HiveObject {
  @HiveField(0)
  late String id;
  
  @HiveField(1)
  late String sensorId;
  
  @HiveField(2)
  late double value;
  
  @HiveField(3)
  late DateTime timestamp;
}

// Box 命名规范
class HiveBoxes {
  static const String sensorReadings = 'sensor_readings_cache';
  static const String userSettings = 'user_settings';
  static const String offlineQueue = 'offline_queue';
}
```

### SharedPreferences 使用规范
```dart
// 仅用于简单键值对存储
class PrefsKeys {
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String lastSyncTime = 'last_sync_time';
  static const String themeMode = 'theme_mode';
  static const String notificationsEnabled = 'notifications_enabled';
}
```

## Repository 实现规范

### Repository 接口 (Domain Layer)
```dart
abstract class SensorRepository {
  /// 获取所有传感器
  Future<Either<Failure, List<Sensor>>> getSensors();
  
  /// 获取传感器详情
  Future<Either<Failure, Sensor>> getSensorById(String id);
  
  /// 获取传感器读数历史
  Future<Either<Failure, List<SensorReading>>> getSensorReadings({
    required String sensorId,
    required DateTime startTime,
    required DateTime endTime,
  });
  
  /// 监听传感器实时数据
  Stream<Either<Failure, SensorReading>> watchSensorReading(String sensorId);
}
```

### Repository 实现 (Data Layer)
```dart
class SensorRepositoryImpl implements SensorRepository {
  final SensorRemoteDataSource _remoteDataSource;
  final SensorLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  
  SensorRepositoryImpl({
    required SensorRemoteDataSource remoteDataSource,
    required SensorLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo;
  
  @override
  Future<Either<Failure, List<Sensor>>> getSensors() async {
    // 网络优先策略
    if (await _networkInfo.isConnected) {
      try {
        final remoteSensors = await _remoteDataSource.getSensors();
        // 更新本地缓存
        await _localDataSource.cacheSensors(remoteSensors);
        return Right(remoteSensors);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      // 离线时使用本地数据
      try {
        final localSensors = await _localDataSource.getCachedSensors();
        return Right(localSensors);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }
}
```

## API 调用规范

### HTTP Client 配置
```dart
class ApiClient {
  final Dio _dio;
  
  ApiClient() : _dio = Dio() {
    _dio.options = BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    
    // 拦截器
    _dio.interceptors.addAll([
      AuthInterceptor(),        // 自动添加 Token
      LoggingInterceptor(),     // 日志记录
      RetryInterceptor(),       // 自动重试
      CacheInterceptor(),       // 响应缓存
    ]);
  }
}
```

### API 端点规范
```dart
class ApiEndpoints {
  // 传感器相关
  static const String sensors = '/api/v1/sensors';
  static String sensorById(String id) => '/api/v1/sensors/$id';
  static String sensorReadings(String id) => '/api/v1/sensors/$id/readings';
  
  // 警报相关
  static const String alerts = '/api/v1/alerts';
  static String alertById(String id) => '/api/v1/alerts/$id';
  static String acknowledgeAlert(String id) => '/api/v1/alerts/$id/acknowledge';
  
  // 用户相关
  static const String login = '/api/v1/auth/login';
  static const String logout = '/api/v1/auth/logout';
  static const String refreshToken = '/api/v1/auth/refresh';
  static const String profile = '/api/v1/users/me';
}
```

### 错误处理
```dart
// 自定义异常
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
  
  const ServerException({
    required this.message,
    this.statusCode,
    this.data,
  });
}

class CacheException implements Exception {
  final String message;
  const CacheException({required this.message});
}

class NetworkException implements Exception {
  final String message;
  const NetworkException({required this.message});
}

// Failure 类型
abstract class Failure extends Equatable {
  final String message;
  const Failure({required this.message});
  
  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

class NetworkFailure extends Failure {
  const NetworkFailure({required super.message});
}
```

## 数据同步策略

### 离线队列
```dart
class OfflineQueueManager {
  final Box<OfflineOperation> _queue;
  
  Future<void> enqueue(OfflineOperation operation) async {
    await _queue.add(operation);
  }
  
  Future<void> processQueue() async {
    final operations = _queue.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    for (final operation in operations) {
      try {
        await _executeOperation(operation);
        await operation.delete(); // 成功后删除
      } on NetworkException {
        break; // 网络错误时停止处理
      }
    }
  }
}

@HiveType(typeId: 10)
class OfflineOperation extends HiveObject {
  @HiveField(0)
  late String type; // 'CREATE', 'UPDATE', 'DELETE'
  
  @HiveField(1)
  late String endpoint;
  
  @HiveField(2)
  late Map<String, dynamic> data;
  
  @HiveField(3)
  late DateTime timestamp;
  
  @HiveField(4)
  late int retryCount;
}
```

### 数据同步服务
```dart
class DataSyncService {
  final SensorRepository _sensorRepository;
  final AlertRepository _alertRepository;
  final OfflineQueueManager _queueManager;
  
  // 完整同步
  Future<void> fullSync() async {
    await _queueManager.processQueue();
    await _syncSensors();
    await _syncAlerts();
    await _updateLastSyncTime();
  }
  
  // 增量同步
  Future<void> incrementalSync() async {
    final lastSync = await _getLastSyncTime();
    await _syncChangedSensors(since: lastSync);
    await _syncChangedAlerts(since: lastSync);
  }
}
```

## WebSocket 实时数据

### WebSocket 配置
```dart
class WebSocketService {
  WebSocketChannel? _channel;
  final StreamController<SensorReading> _readingController = 
      StreamController.broadcast();
  
  Stream<SensorReading> get readingStream => _readingController.stream;
  
  Future<void> connect() async {
    final token = await _authService.getToken();
    _channel = WebSocketChannel.connect(
      Uri.parse('${AppConfig.wsBaseUrl}/sensors?token=$token'),
    );
    
    _channel!.stream.listen(
      _handleMessage,
      onError: _handleError,
      onDone: _handleDone,
    );
  }
  
  void _handleMessage(dynamic message) {
    final data = jsonDecode(message as String);
    final reading = SensorReadingModel.fromJson(data);
    _readingController.add(reading);
  }
  
  void subscribe(String sensorId) {
    _channel?.sink.add(jsonEncode({
      'action': 'subscribe',
      'sensorId': sensorId,
    }));
  }
  
  void unsubscribe(String sensorId) {
    _channel?.sink.add(jsonEncode({
      'action': 'unsubscribe',
      'sensorId': sensorId,
    }));
  }
}
```

## 缓存策略

### 缓存配置
```dart
class CacheConfig {
  // 传感器列表缓存：5 分钟
  static const sensorListTTL = Duration(minutes: 5);
  
  // 传感器详情缓存：2 分钟
  static const sensorDetailTTL = Duration(minutes: 2);
  
  // 历史数据缓存：1 小时
  static const historyDataTTL = Duration(hours: 1);
  
  // 用户信息缓存：30 分钟
  static const userInfoTTL = Duration(minutes: 30);
}
```

### 缓存管理
```dart
class CacheManager {
  final Box<CacheEntry> _cacheBox;
  
  Future<T?> get<T>(String key) async {
    final entry = _cacheBox.get(key);
    if (entry == null) return null;
    if (entry.isExpired) {
      await _cacheBox.delete(key);
      return null;
    }
    return entry.data as T;
  }
  
  Future<void> set<T>(String key, T data, Duration ttl) async {
    final entry = CacheEntry(
      data: data,
      expiresAt: DateTime.now().add(ttl),
    );
    await _cacheBox.put(key, entry);
  }
  
  Future<void> invalidate(String key) async {
    await _cacheBox.delete(key);
  }
  
  Future<void> clear() async {
    await _cacheBox.clear();
  }
}
```

## 安全规范

### 敏感数据存储
```dart
class SecureStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }
  
  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }
  
  Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }
}
```

### API 安全
```dart
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 添加 Authorization header
    final token = await _secureStorage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    // 添加请求签名 (可选)
    final signature = _generateSignature(options);
    options.headers['X-Signature'] = signature;
    
    handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token 过期，尝试刷新
      final newToken = await _refreshToken();
      if (newToken != null) {
        // 重试原请求
        final response = await _retry(err.requestOptions);
        return handler.resolve(response);
      }
    }
    handler.next(err);
  }
}
```

## 数据库迁移

```dart
class DatabaseMigration {
  static const int currentVersion = 3;
  
  static Future<void> migrate(Database db, int oldVersion, int newVersion) async {
    for (var version = oldVersion + 1; version <= newVersion; version++) {
      await _runMigration(db, version);
    }
  }
  
  static Future<void> _runMigration(Database db, int version) async {
    switch (version) {
      case 2:
        await _migrateToV2(db);
        break;
      case 3:
        await _migrateToV3(db);
        break;
    }
  }
  
  static Future<void> _migrateToV2(Database db) async {
    await db.execute('''
      ALTER TABLE sensors ADD COLUMN last_reading_at TEXT;
    ''');
  }
  
  static Future<void> _migrateToV3(Database db) async {
    await db.execute('''
      CREATE TABLE maintenance_logs (
        id TEXT PRIMARY KEY,
        sensor_id TEXT NOT NULL,
        description TEXT NOT NULL,
        performed_by TEXT NOT NULL,
        performed_at TEXT NOT NULL,
        FOREIGN KEY (sensor_id) REFERENCES sensors(id)
      );
    ''');
  }
}
```

## 测试规范

### Repository 测试
```dart
void main() {
  late MockSensorRemoteDataSource mockRemoteDataSource;
  late MockSensorLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;
  late SensorRepositoryImpl repository;
  
  setUp(() {
    mockRemoteDataSource = MockSensorRemoteDataSource();
    mockLocalDataSource = MockSensorLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = SensorRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });
  
  group('getSensors', () {
    test('should return remote data when online', () async {
      // Arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.getSensors())
          .thenAnswer((_) async => testSensors);
      
      // Act
      final result = await repository.getSensors();
      
      // Assert
      expect(result, equals(Right(testSensors)));
      verify(mockLocalDataSource.cacheSensors(testSensors));
    });
    
    test('should return cached data when offline', () async {
      // Arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(mockLocalDataSource.getCachedSensors())
          .thenAnswer((_) async => cachedSensors);
      
      // Act
      final result = await repository.getSensors();
      
      // Assert
      expect(result, equals(Right(cachedSensors)));
      verifyZeroInteractions(mockRemoteDataSource);
    });
  });
}
```
