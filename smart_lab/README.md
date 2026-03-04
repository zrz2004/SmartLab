# 智慧实验室安全监测与预警系统 (SmartLab)

基于物联网技术的实验室安全管理移动端应用，采用 Flutter + Clean Architecture + BLoC 架构开发。

## 项目概述

本系统旨在实现对高校实验室环境的智能化监测与预警，通过物联网传感器实时采集实验室数据，并在移动端进行可视化展示和预警通知。

### 核心功能

- **首页仪表盘**: 实时安全评分、各类传感器状态概览、实时告警列表
- **环境监测**: 温度、湿度、VOC指数实时监控与历史趋势
- **电源管理**: 智能电源控制、漏电流监测、各插座功率监控
- **安防水路**: 水阀控制、漏水检测、门窗状态监控
- **危化品管理**: RFID智能识别、库存管理、领用记录追踪
- **告警中心**: 多级告警推送、历史告警查询、一键确认

## 技术架构

### 前端框架
- **Flutter 3.0+**: 跨平台移动应用开发
- **Dart 3.0+**: 支持 Pattern Matching 和 Records

### 架构模式
- **Clean Architecture**: 清晰的分层架构
  - Data Layer: 数据源、仓库实现
  - Domain Layer: 实体、用例
  - Presentation Layer: BLoC、Widgets
- **BLoC Pattern**: 可预测的状态管理

### 通信协议
- **MQTT over TLS**: 实时传感器数据订阅
- **REST API**: 设备管理、用户认证
- **WebSocket**: 即时通知推送

### 核心依赖
```yaml
flutter_bloc: ^8.1.3      # 状态管理
dio: ^5.4.0               # HTTP客户端
mqtt_client: ^10.0.0      # MQTT通信
go_router: ^13.0.0        # 声明式路由
fl_chart: ^0.66.0         # 数据可视化
hive: ^2.2.3              # 本地存储
get_it: ^7.6.4            # 依赖注入
local_auth: ^2.1.6        # 生物识别
```

## 项目结构

```
lib/
├── main.dart                      # 应用入口
├── core/                          # 核心层
│   ├── constants/                 # 常量定义
│   │   ├── api_endpoints.dart     # API端点
│   │   ├── mqtt_topics.dart       # MQTT主题
│   │   └── safety_thresholds.dart # 安全阈值
│   ├── di/                        # 依赖注入
│   │   └── injection.dart
│   ├── router/                    # 路由配置
│   │   └── app_router.dart
│   ├── services/                  # 基础服务
│   │   ├── api_service.dart       # REST API
│   │   ├── mqtt_service.dart      # MQTT服务
│   │   ├── notification_service.dart
│   │   └── local_storage_service.dart
│   └── theme/                     # 主题系统
│       ├── app_colors.dart        # 颜色定义
│       ├── app_spacing.dart       # 间距系统
│       ├── app_theme.dart         # 主题配置
│       └── app_typography.dart    # 字体样式
├── features/                      # 功能模块
│   ├── dashboard/                 # 首页仪表盘
│   ├── environment/               # 环境监测
│   ├── power/                     # 电源管理
│   ├── security/                  # 安防水路
│   ├── chemicals/                 # 危化品管理
│   ├── alerts/                    # 告警中心
│   ├── auth/                      # 认证模块
│   └── device/                    # 设备详情
└── shared/                        # 共享组件
    └── widgets/                   # 通用UI组件
        ├── status_card.dart
        ├── safety_score_card.dart
        ├── sensor_gauge.dart
        ├── realtime_chart.dart
        ├── alert_item.dart
        └── control_switch.dart
```

## 开发环境配置

### 前置要求
1. Flutter SDK >= 3.0.0
2. Dart SDK >= 3.0.0
3. Android Studio / VS Code
4. iOS 开发需要 Xcode (macOS)

### 安装步骤

```bash
# 1. 克隆项目
git clone <repository-url>
cd smart_lab

# 2. 获取依赖
flutter pub get

# 3. 运行代码生成 (如需要)
flutter pub run build_runner build

# 4. 运行应用
flutter run

# 5. 构建发布版本
flutter build apk --release    # Android
flutter build ios --release    # iOS
```

### 目录创建
运行前需要创建资源目录:
```bash
mkdir -p assets/images assets/icons assets/fonts
```

## 设计规范

### 颜色系统
| 名称 | 色值 | 用途 |
|------|------|------|
| Primary | #1E3A5F | 主色调（深邃科技蓝）|
| Safe | #10B981 | 安全状态 |
| Warning | #F59E0B | 预警状态 |
| Critical | #EF4444 | 紧急状态 |

### 间距系统
- 基于 8pt 网格系统
- xs: 4px, sm: 8px, md: 12px, lg: 16px, xl: 24px

### 字体
- 中文: PingFang SC
- 数字: DIN Alternate (醒目的数据展示)

## MQTT 主题规范

```
lab/{buildingId}/{roomId}/{deviceType}/{deviceId}/telemetry   # 遥测数据
lab/{buildingId}/{roomId}/{deviceType}/{deviceId}/command     # 控制指令
lab/{buildingId}/{roomId}/alert                               # 告警推送
```

## 安全阈值 (OSHA/FDA 标准)

| 参数 | 正常范围 | 预警值 | 危险值 |
|------|----------|--------|--------|
| 温度 | 20-25°C | 28°C | 35°C |
| 湿度 | 30-50% | 60% | 80% |
| VOC | < 150 ppb | 200 ppb | 500 ppb |
| 漏电流 | < 15 mA | 25 mA | 30 mA |

## 许可证

本项目为毕业设计作品，仅供学习参考。

---

**作者**: 张润哲 (学号: 2022117358)  
**指导教师**: 徐丹  
**专业**: 物联网工程  
**学院**: 计算机科学与技术学院
