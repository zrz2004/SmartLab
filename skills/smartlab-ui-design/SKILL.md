---
name: smartlab-ui-design-guidelines
description: 智慧实验室安全监测与预警系统 UI 设计规范。涵盖设计系统、组件规范、颜色方案、响应式布局、动画效果、可访问性等方面。适用于创建统一、专业、用户友好的实验室安全监测界面。
license: MIT
metadata:
  author: SmartLab Team
  version: "1.0.0"
  platform: flutter
  theme: material-design-3
---

# SmartLab UI 设计规范

专为智慧实验室安全监测与预警系统设计的 UI 规范指南，基于 Material Design 3，针对工业安全监测场景优化。

## 适用场景

在以下情况下参考本指南：
- 创建新的页面或组件
- 设计数据可视化图表
- 实现报警和通知界面
- 优化用户交互体验
- 确保跨平台一致性

## 设计原则

### 1. 安全第一 (Safety First)
- 警报信息必须醒目且易于识别
- 关键操作需要二次确认
- 危险状态使用红色/橙色高亮

### 2. 信息层次 (Information Hierarchy)
- 最重要的信息放在最显眼的位置
- 使用合适的字体大小和颜色建立层次
- 数据仪表盘遵循 F 型阅读模式

### 3. 响应迅速 (Responsive)
- 界面响应时间 < 100ms
- 加载状态有明确指示
- 实时数据更新平滑过渡

## 颜色系统

### 主色调 (Primary Colors)
```dart
class AppColors {
  // 主色 - 深蓝色 (专业、信任)
  static const primary = Color(0xFF1565C0);
  static const primaryLight = Color(0xFF5E92F3);
  static const primaryDark = Color(0xFF003C8F);
  
  // 次色 - 青色 (科技感)
  static const secondary = Color(0xFF00ACC1);
  static const secondaryLight = Color(0xFF5DDEF4);
  static const secondaryDark = Color(0xFF007C91);
}
```

### 状态颜色 (Status Colors)
```dart
class StatusColors {
  // 安全状态 - 绿色
  static const safe = Color(0xFF4CAF50);
  static const safeLight = Color(0xFFE8F5E9);
  
  // 警告状态 - 橙色
  static const warning = Color(0xFFFF9800);
  static const warningLight = Color(0xFFFFF3E0);
  
  // 危险状态 - 红色
  static const danger = Color(0xFFF44336);
  static const dangerLight = Color(0xFFFFEBEE);
  
  // 信息状态 - 蓝色
  static const info = Color(0xFF2196F3);
  static const infoLight = Color(0xFFE3F2FD);
  
  // 离线/未知 - 灰色
  static const offline = Color(0xFF9E9E9E);
  static const offlineLight = Color(0xFFF5F5F5);
}
```

### 深色模式
```dart
class DarkThemeColors {
  static const background = Color(0xFF121212);
  static const surface = Color(0xFF1E1E1E);
  static const cardBackground = Color(0xFF2C2C2C);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xB3FFFFFF); // 70% opacity
}
```

## 排版系统

### 字体层级
```dart
class AppTextStyles {
  // 大标题 - 页面标题
  static const headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );
  
  // 标题 - 卡片标题
  static const headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );
  
  // 副标题 - 区块标题
  static const subtitle1 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
  );
  
  // 正文 - 主要内容
  static const body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  // 辅助文本 - 次要信息
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Colors.grey,
  );
  
  // 数据显示 - 大数字
  static const dataDisplay = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    fontFamily: 'RobotoMono',
  );
}
```

## 间距系统

### 基准单位
```dart
class AppSpacing {
  static const double unit = 8.0;
  
  static const double xs = unit * 0.5;   // 4
  static const double sm = unit;          // 8
  static const double md = unit * 2;      // 16
  static const double lg = unit * 3;      // 24
  static const double xl = unit * 4;      // 32
  static const double xxl = unit * 6;     // 48
}
```

### 页面边距
```dart
class AppPadding {
  // 页面内边距
  static const pagePadding = EdgeInsets.all(16);
  
  // 卡片内边距
  static const cardPadding = EdgeInsets.all(16);
  
  // 列表项间距
  static const listItemSpacing = 12.0;
  
  // 区块间距
  static const sectionSpacing = 24.0;
}
```

## 组件规范

### 1. 报警卡片 (Alert Card)
```dart
// 结构规范
AlertCard(
  severity: AlertSeverity.high,     // 严重程度
  title: '温度超标警报',              // 标题
  description: '实验室A温度达到35°C', // 描述
  timestamp: DateTime.now(),         // 时间戳
  location: '化学实验室A',            // 位置
  actions: [...],                    // 操作按钮
)

// 视觉规范
// - 高严重度：红色左边框 4px
// - 中严重度：橙色左边框 4px
// - 低严重度：黄色左边框 4px
// - 卡片圆角：12px
// - 卡片阴影：elevation 2
```

### 2. 传感器状态指示器 (Sensor Status Indicator)
```dart
// 规范
SensorStatusIndicator(
  value: 25.5,
  unit: '°C',
  status: SensorStatus.normal,
  minValue: 0,
  maxValue: 50,
  warningThreshold: 30,
  dangerThreshold: 40,
)

// 视觉规范
// - 正常：绿色圆形指示灯
// - 警告：橙色脉动动画
// - 危险：红色闪烁动画
// - 离线：灰色静态
```

### 3. 数据仪表盘 (Dashboard Card)
```dart
// 布局规范
// - 标题区：图标 + 标题 + 操作按钮
// - 数据区：大数字显示 + 单位 + 趋势箭头
// - 图表区：迷你趋势图
// - 底部区：更新时间 + 详情链接

// 尺寸规范
// - 最小宽度：160px
// - 最小高度：140px
// - 建议比例：1:1 或 2:1
```

### 4. 导航栏 (Navigation)
```dart
// 底部导航规范 (移动端)
BottomNavigationBar(
  items: [
    // 图标大小：24x24
    // 标签字号：12
    // 选中项：主色
    // 未选中：灰色
  ],
)

// 侧边导航规范 (平板/桌面)
NavigationRail(
  // 展开宽度：256px
  // 收起宽度：72px
  // 图标大小：24x24
)
```

## 动画规范

### 时长
```dart
class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 500);
}
```

### 曲线
```dart
class AppCurves {
  static const standard = Curves.easeInOut;
  static const enter = Curves.easeOut;
  static const exit = Curves.easeIn;
  static const bounce = Curves.elasticOut;
}
```

### 动画场景
- **页面转场**：SlideTransition，300ms
- **卡片展开**：SizeAnimation，250ms
- **按钮反馈**：ScaleAnimation，150ms
- **警报闪烁**：OpacityAnimation，500ms 循环
- **数据刷新**：FadeTransition，200ms

## 响应式布局

### 断点
```dart
class Breakpoints {
  static const mobile = 600;    // < 600: 手机
  static const tablet = 900;    // 600-900: 平板竖屏
  static const desktop = 1200;  // 900-1200: 平板横屏
  static const wide = 1800;     // > 1200: 桌面
}
```

### 布局策略
```dart
// 手机：单列布局
// - 导航：底部导航栏
// - 仪表盘：垂直滚动卡片列表
// - 列表：全宽列表项

// 平板：双列布局
// - 导航：侧边导航栏（可收起）
// - 仪表盘：2列网格
// - 列表：主从视图

// 桌面：多列布局
// - 导航：固定侧边栏
// - 仪表盘：3-4列网格
// - 列表：主从视图 + 详情面板
```

## 可访问性

### 对比度要求
- 正文文本：至少 4.5:1
- 大文本：至少 3:1
- 图形元素：至少 3:1

### 触控目标
- 最小尺寸：48x48px
- 按钮间距：至少 8px

### 屏幕阅读器
```dart
Semantics(
  label: '温度传感器，当前值25度，状态正常',
  child: TemperatureWidget(value: 25),
)
```

## 图表规范

### 实时数据图表
```dart
// 折线图配置
LineChartConfig(
  // 数据点：最多显示 100 个
  // 更新频率：1 秒
  // Y轴：自动缩放，显示单位
  // X轴：时间轴，显示最近 5 分钟
  // 网格线：虚线，低透明度
  // 工具提示：显示精确值和时间
)
```

### 统计图表
```dart
// 柱状图、饼图配置
// - 最多显示 8 个分类
// - 颜色使用状态色或主题色系
// - 必须有图例
// - 数据标签可选显示
```

## 图标规范

### 系统图标
- 风格：Material Icons Rounded
- 大小：24x24（标准）、20x20（小）、32x32（大）
- 颜色：跟随文本颜色或状态颜色

### 自定义图标
- 格式：SVG（首选）或 PNG @2x
- 线宽：2px
- 圆角：2px
- 内边距：2px

## 设计资源

- Material Design 3: https://m3.material.io/
- Flutter Widget Catalog: https://docs.flutter.dev/ui/widgets
- Figma Community Flutter Widgets
