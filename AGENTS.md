# SmartLab 智慧实验室安全监测与预警系统

## 项目概述

**SmartLab** 是一个基于 Flutter 开发的智慧实验室安全监测与预警系统，采用 Clean Architecture + BLoC 状态管理模式。

## 应用信息

- **应用名称**: SmartLab
- **包名**: com.smartlab.smart_lab
- **Logo**: assets/icons/app_icon.jpg

## 服务器配置

| 服务 | 地址 | 端口 | 说明 |
|------|------|------|------|
| **API 服务** | 47.109.158.254 | 3000 | Node.js/Express 后端 |
| **PostgreSQL** | 47.109.158.254 | 5433 | 数据库 |
| **MQTT** | 47.109.158.254 | 1883 | 待部署 (EMQX) |

### API 端点

- **Base URL**: `http://47.109.158.254:3000/api/v1`
- **健康检查**: `GET /health`
- **登录**: `POST /auth/login` (admin / admin123)

## 技术栈

- **框架**: Flutter 3.x (Dart 3.x)
- **状态管理**: flutter_bloc ^8.0.0
- **依赖注入**: get_it + injectable
- **网络请求**: dio, mqtt_client
- **本地存储**: hive, flutter_secure_storage
- **路由**: go_router
- **图表**: fl_chart

## 架构规范

本项目严格遵循以下规范，请在开发时参考：

### Skills 规范文档

| 规范 | 路径 | 说明 |
|------|------|------|
| Flutter/Dart 代码规范 | [skills/flutter-dart-best-practices/SKILL.md](skills/flutter-dart-best-practices/SKILL.md) | 命名约定、代码风格、性能优化 |
| UI 设计规范 | [skills/smartlab-ui-design/SKILL.md](skills/smartlab-ui-design/SKILL.md) | 颜色系统、排版、组件规范、动画 |
| 后端/数据库规范 | [skills/smartlab-backend-database/SKILL.md](skills/smartlab-backend-database/SKILL.md) | 数据模型、API、缓存、安全 |
| BLoC 架构规范 | [skills/flutter-bloc-architecture/SKILL.md](skills/flutter-bloc-architecture/SKILL.md) | 状态管理、事件设计、测试 |

### 外部参考 Skills

| 规范 | 路径 | 说明 |
|------|------|------|
| Web 设计指南 | [skills/vercel-agent-skills/skills/web-design-guidelines/](skills/vercel-agent-skills/skills/web-design-guidelines/) | Vercel 设计规范 |
| React 最佳实践 | [skills/vercel-agent-skills/skills/react-best-practices/](skills/vercel-agent-skills/skills/react-best-practices/) | 性能优化参考 |
| 组合模式 | [skills/vercel-agent-skills/skills/composition-patterns/](skills/vercel-agent-skills/skills/composition-patterns/) | 组件设计参考 |

## 项目结构

```
SmartLab/
├── AGENTS.md                    # 项目配置文档
├── SKILLS_GUIDE.md              # Skills 使用指南
├── SmartLabApp.md               # 项目设计文档
├── logo.jpg                     # 原始 Logo
│
├── skills/                      # 开发规范
│   ├── flutter-dart-best-practices/
│   ├── smartlab-ui-design/
│   ├── smartlab-backend-database/
│   ├── flutter-bloc-architecture/
│   ├── vercel-agent-skills/
│   └── anthropic-courses/
│
└── smart_lab/                   # Flutter 项目
    ├── lib/
    │   ├── core/                # 核心模块
    │   │   ├── constants/       # 常量 (API端点、MQTT主题、安全阈值)
    │   │   ├── di/              # 依赖注入
    │   │   ├── router/          # 路由配置
    │   │   ├── services/        # 服务 (API、MQTT、存储、通知)
    │   │   └── theme/           # 主题 (颜色、排版、间距)
    │   │
    │   ├── features/            # 功能模块
    │   │   ├── alerts/          # 报警中心
    │   │   ├── auth/            # 认证登录
    │   │   ├── chemicals/       # 危化品管理
    │   │   ├── dashboard/       # 仪表盘
    │   │   ├── device/          # 设备管理
    │   │   ├── environment/     # 环境监测
    │   │   ├── main/            # 主页框架
    │   │   ├── power/           # 电源管理
    │   │   └── security/        # 安防水路
    │   │
    │   ├── shared/              # 共享组件
    │   │   └── widgets/         # 通用 Widget
    │   │
    │   └── main.dart            # 应用入口
    │
    ├── assets/                  # 资源文件
    │   ├── images/              # 图片 (含 Logo)
    │   ├── icons/               # 图标 (含 App 图标)
    │   └── fonts/               # 字体
    │
    ├── android/                 # Android 平台
    ├── web/                     # Web 平台
    └── pubspec.yaml             # 依赖配置
```

## 支持平台

| 平台 | 状态 | 说明 |
|------|------|------|
| Android | ✅ 支持 | 主要目标平台 |
| Web | ✅ 支持 | 浏览器访问 |

## 功能模块说明

| 模块 | 目录 | 功能 |
|------|------|------|
| 仪表盘 | `features/dashboard/` | 安全总览、实时数据概览 |
| 环境监测 | `features/environment/` | 温湿度、气体监测 |
| 电源管理 | `features/power/` | 电压电流、功率、漏电监测 |
| 安防水路 | `features/security/` | 门窗状态、水路监测 |
| 危化品管理 | `features/chemicals/` | 化学品库存、有效期管理 |
| 报警中心 | `features/alerts/` | 报警列表、处理记录 |
| 设备管理 | `features/device/` | 传感器设备管理 |
| 认证登录 | `features/auth/` | 用户登录、生物识别 |

## 开发指南

### 快速开始

```bash
cd smart_lab

# 获取依赖
flutter pub get

# 运行应用
flutter run

# 生成图标 (如需更新)
dart run flutter_launcher_icons
```

### 创建新功能模块

1. 在 `features/` 下创建功能文件夹
2. 按照三层架构创建子目录: `domain/`, `presentation/`
3. 遵循 BLoC 架构规范创建状态管理

### 代码风格

- 遵循 [Effective Dart](https://dart.dev/guides/language/effective-dart) 规范
- 使用 `dart format` 格式化代码
- 使用 `dart analyze` 检查代码问题
- PR 前必须通过所有测试

### 命名约定

| 类型 | 命名规则 | 示例 |
|------|----------|------|
| 文件名 | snake_case | `safety_bloc.dart` |
| 类名 | UpperCamelCase | `SafetyBloc` |
| 变量/方法 | lowerCamelCase | `getSensorData` |
| 常量 | lowerCamelCase | `maxRetryCount` |
| 私有成员 | _lowerCamelCase | `_isLoading` |

### 提交规范

```
<type>(<scope>): <subject>

<body>

<footer>
```

类型 (type):
- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `style`: 代码风格
- `refactor`: 重构
- `test`: 测试
- `chore`: 构建/工具

### 分支策略

- `main`: 生产分支
- `develop`: 开发分支
- `feature/*`: 功能分支
- `bugfix/*`: Bug 修复分支
- `release/*`: 发布分支

## 快速开始

```bash
# 获取依赖
flutter pub get

# 运行代码生成
flutter pub run build_runner build --delete-conflicting-outputs

# 运行应用
flutter run

# 运行测试
flutter test

# 构建发布版本
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

## 环境配置

### 开发环境
- Flutter SDK: 3.x
- Dart SDK: 3.x
- Android Studio / VS Code
- Android SDK (Android 开发)
- Xcode (iOS 开发)

### 环境变量
在项目根目录创建 `.env` 文件：
```
API_BASE_URL=https://api.smartlab.example.com
WS_BASE_URL=wss://ws.smartlab.example.com
```

