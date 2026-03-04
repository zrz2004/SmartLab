# SmartLab Skills 使用指南

本文档说明如何使用为智慧实验室安全监测与预警系统配置的各种开发规范 (Skills)。

## 已安装的 Skills

### 1. 项目专用 Skills (自定义创建)

| Skill | 位置 | 用途 |
|-------|------|------|
| **Flutter/Dart 代码规范** | `skills/flutter-dart-best-practices/SKILL.md` | Dart 语言规范、命名约定、性能优化 |
| **UI 设计规范** | `skills/smartlab-ui-design/SKILL.md` | 颜色系统、排版、组件设计、动画规范 |
| **后端/数据库规范** | `skills/smartlab-backend-database/SKILL.md` | API 设计、数据模型、缓存策略、安全实践 |
| **BLoC 架构规范** | `skills/flutter-bloc-architecture/SKILL.md` | 状态管理、事件/状态设计、依赖注入、测试 |

### 2. 外部参考 Skills (从 GitHub 克隆)

#### Vercel Agent Skills
位置: `skills/vercel-agent-skills/skills/`

| Skill | 用途 |
|-------|------|
| `web-design-guidelines/` | Web 设计通用准则 |
| `react-best-practices/` | React/Next.js 性能优化 (可参考用于 Flutter 优化思路) |
| `composition-patterns/` | 组件组合模式 |
| `react-native-skills/` | React Native 开发规范 (跨平台参考) |
| `claude.ai/` | Claude AI 集成指南 |

#### Anthropic Courses
位置: `skills/anthropic-courses/`

| 课程 | 用途 |
|------|------|
| `anthropic_api_fundamentals/` | Anthropic API 基础 |
| `prompt_engineering_interactive_tutorial/` | 提示工程教程 |
| `prompt_evaluations/` | 提示评估方法 |
| `real_world_prompting/` | 实际应用提示技巧 |
| `tool_use/` | 工具使用指南 |

---

## 如何使用这些 Skills

### 在开发过程中

1. **开始新功能前**：阅读相关的 SKILL.md 文件了解规范
2. **代码审查时**：对照规范检查代码质量
3. **遇到问题时**：查找对应规范中的最佳实践

### 与 AI 助手协作

在与 Claude 或其他 AI 助手协作时，可以：

```
请参考 skills/flutter-dart-best-practices/SKILL.md 中的代码规范，
帮我审查这段代码...
```

或

```
按照 skills/flutter-bloc-architecture/SKILL.md 的架构规范，
帮我创建一个新的 [功能名称] 模块...
```

### Skill 文件结构说明

每个 SKILL.md 文件包含：

```yaml
---
name: skill-name           # Skill 名称
description: ...           # 用途描述
license: MIT              # 许可证
metadata:
  author: ...             # 作者
  version: "1.0.0"        # 版本
---

# 标题
## 适用场景
## 规则分类
## 详细规范
...
```

---

## 更新 Skills

### 更新外部 Skills

```bash
cd skills/vercel-agent-skills
git pull origin main

cd ../anthropic-courses
git pull origin main
```

### 添加新的 Skill

1. 在 `skills/` 目录下创建新文件夹
2. 创建 `SKILL.md` 文件，遵循上述结构
3. 在 `AGENTS.md` 中添加引用

---

## 快速参考卡片

### 代码风格速查

```dart
// ✅ 正确的命名
class SensorReading {}           // 类名: UpperCamelCase
final maxRetryCount = 3;         // 常量: lowerCamelCase
void _privateMethod() {}         // 私有: _lowerCamelCase
// 文件名: sensor_reading.dart   // 文件名: snake_case

// ✅ 使用 const
const Widget myWidget = SizedBox();

// ✅ 尾随逗号
Container(
  width: 100,
  height: 100,  // <- 尾随逗号
)
```

### 状态颜色速查

```dart
// 安全 - 绿色
StatusColors.safe      // #4CAF50
// 警告 - 橙色
StatusColors.warning   // #FF9800
// 危险 - 红色
StatusColors.danger    // #F44336
// 信息 - 蓝色
StatusColors.info      // #2196F3
// 离线 - 灰色
StatusColors.offline   // #9E9E9E
```

### BLoC 事件命名速查

```dart
// ✅ 正确: 动词 + 名词
LoadSensorData
UpdateAlertStatus
DeleteAlert
SubscribeToAlerts

// ❌ 错误
SensorDataLoad
AlertStatusUpdate
```

---

## 相关文档

- [项目主文档](AGENTS.md)
- [项目说明](SmartLabApp.md)
- [Flutter 官方文档](https://docs.flutter.dev/)
- [BLoC 库文档](https://bloclibrary.dev/)
