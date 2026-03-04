---
name: flutter-dart-best-practices
description: Flutter 和 Dart 代码规范与最佳实践指南。适用于编写、审查或重构 Flutter/Dart 代码时使用。涵盖代码风格、性能优化、状态管理、错误处理等方面。
license: MIT
metadata:
  author: SmartLab Team
  version: "1.0.0"
  language: dart
  framework: flutter
---

# Flutter & Dart 最佳实践指南

针对 Flutter 应用开发的综合性代码规范与最佳实践，适用于智慧实验室安全监测与预警系统项目。

## 适用场景

在以下情况下参考本指南：
- 编写新的 Flutter Widget 或页面
- 实现状态管理（BLoC、Provider 等）
- 审查代码性能问题
- 重构现有 Flutter/Dart 代码
- 优化应用性能和用户体验

## 规则分类及优先级

| 优先级 | 类别 | 影响程度 | 前缀 |
|--------|------|----------|------|
| 1 | 代码风格 | HIGH | `style-` |
| 2 | 性能优化 | CRITICAL | `perf-` |
| 3 | Widget 设计 | HIGH | `widget-` |
| 4 | 状态管理 | HIGH | `state-` |
| 5 | 错误处理 | MEDIUM | `error-` |
| 6 | 测试规范 | MEDIUM | `test-` |

## 快速参考

### 1. 代码风格 (HIGH)

- `style-naming-conventions` - 使用正确的命名约定
  - 类名：`UpperCamelCase` (如 `SafetyAlertCard`)
  - 变量/方法：`lowerCamelCase` (如 `getUserData`)
  - 常量：`lowerCamelCase` (如 `maxRetryCount`)
  - 私有成员：`_lowerCamelCase` (如 `_privateField`)
  - 文件名：`snake_case.dart` (如 `safety_bloc.dart`)

- `style-prefer-const` - 优先使用 const 构造函数
  ```dart
  // ✗ 避免
  Widget build(BuildContext context) {
    return Container(child: Text('Hello'));
  }
  
  // ✓ 推荐
  Widget build(BuildContext context) {
    return const Container(child: Text('Hello'));
  }
  ```

- `style-trailing-commas` - 在多行参数列表末尾添加逗号
  ```dart
  // ✓ 推荐
  Container(
    width: 100,
    height: 100,
    color: Colors.blue,
  )
  ```

- `style-prefer-relative-imports` - 包内使用相对导入
  ```dart
  // ✗ 避免
  import 'package:smart_lab/features/home/home_page.dart';
  
  // ✓ 推荐 (在同一包内)
  import '../home/home_page.dart';
  ```

- `style-import-order` - 导入语句按规范排序
  ```dart
  // 1. dart: 导入
  import 'dart:async';
  import 'dart:io';
  
  // 2. package: 导入 (第三方包)
  import 'package:flutter/material.dart';
  import 'package:flutter_bloc/flutter_bloc.dart';
  
  // 3. 相对导入 (项目内部)
  import '../widgets/custom_button.dart';
  import 'home_state.dart';
  ```

### 2. 性能优化 (CRITICAL)

- `perf-avoid-rebuild` - 避免不必要的 Widget 重建
  ```dart
  // ✗ 避免：在 build 方法中创建闭包
  onPressed: () => _handlePress(item.id)
  
  // ✓ 推荐：使用 const 或提取为独立 Widget
  onPressed: _handlePress  // 配合 callback 传递
  ```

- `perf-use-const-widgets` - 将不变的 Widget 提取为 const
  ```dart
  // ✓ 推荐
  class _LoadingIndicator extends StatelessWidget {
    const _LoadingIndicator();
    
    @override
    Widget build(BuildContext context) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
  }
  ```

- `perf-list-view-builder` - 长列表使用 ListView.builder
  ```dart
  // ✗ 避免：一次性构建所有子项
  ListView(children: items.map((e) => ItemWidget(e)).toList())
  
  // ✓ 推荐：按需构建
  ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) => ItemWidget(items[index]),
  )
  ```

- `perf-image-caching` - 使用图片缓存
  ```dart
  // ✓ 推荐：使用 cached_network_image
  CachedNetworkImage(
    imageUrl: url,
    placeholder: (context, url) => const CircularProgressIndicator(),
    errorWidget: (context, url, error) => const Icon(Icons.error),
  )
  ```

- `perf-dispose-resources` - 及时释放资源
  ```dart
  class _MyWidgetState extends State<MyWidget> {
    late final StreamSubscription _subscription;
    late final TextEditingController _controller;
    
    @override
    void dispose() {
      _subscription.cancel();
      _controller.dispose();
      super.dispose();
    }
  }
  ```

### 3. Widget 设计 (HIGH)

- `widget-single-responsibility` - 每个 Widget 只做一件事
- `widget-extract-methods` - 将复杂 build 方法拆分为小 Widget
- `widget-prefer-stateless` - 优先使用 StatelessWidget
- `widget-keys` - 正确使用 Key
  ```dart
  // ✓ 列表项使用 ValueKey
  ListView.builder(
    itemBuilder: (context, index) => ListTile(
      key: ValueKey(items[index].id),
      title: Text(items[index].name),
    ),
  )
  ```

### 4. 状态管理 (HIGH)

- `state-bloc-pattern` - 遵循 BLoC 模式
  - Event -> Bloc -> State
  - 单向数据流
  - 事件驱动

- `state-immutable` - 状态对象不可变
  ```dart
  // ✓ 推荐：使用 copyWith
  class SafetyState extends Equatable {
    final List<Alert> alerts;
    final bool isLoading;
    
    SafetyState copyWith({
      List<Alert>? alerts,
      bool? isLoading,
    }) {
      return SafetyState(
        alerts: alerts ?? this.alerts,
        isLoading: isLoading ?? this.isLoading,
      );
    }
  }
  ```

- `state-bloc-events` - 事件命名规范
  ```dart
  // ✓ 推荐：动词 + 名词
  class LoadAlerts extends SafetyEvent {}
  class UpdateAlertStatus extends SafetyEvent {}
  class DeleteAlert extends SafetyEvent {}
  ```

### 5. 错误处理 (MEDIUM)

- `error-result-type` - 使用 Result 类型处理可预期错误
  ```dart
  // ✓ 推荐
  Future<Either<Failure, User>> getUser(String id);
  ```

- `error-try-catch` - 适当使用 try-catch
  ```dart
  // ✓ 推荐：只捕获预期的异常
  try {
    final result = await api.fetchData();
  } on NetworkException catch (e) {
    // 处理网络错误
  } on FormatException catch (e) {
    // 处理格式错误
  }
  ```

- `error-logging` - 记录错误日志
  ```dart
  // ✓ 推荐
  catch (e, stackTrace) {
    logger.error('Failed to fetch data', error: e, stackTrace: stackTrace);
  }
  ```

### 6. 测试规范 (MEDIUM)

- `test-unit-tests` - 业务逻辑必须有单元测试
- `test-widget-tests` - 关键 Widget 需要 Widget 测试
- `test-bloc-tests` - BLoC 需要完整的状态测试
- `test-mocking` - 使用 mocktail 进行依赖模拟

## 完整文档

详细规则请参考: `rules/` 目录下的各规则文件
