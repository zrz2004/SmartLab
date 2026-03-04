import 'package:flutter/material.dart';

/// 应用间距系统
/// 
/// 基于 8pt 网格系统
/// 确保视觉节奏一致，信息层次分明
class AppSpacing {
  AppSpacing._();

  // ==================== 基础间距 (8pt 网格) ====================
  
  /// 最小间距 - 4px
  static const double xs = 4.0;
  
  /// 小间距 - 8px
  static const double sm = 8.0;
  
  /// 中等间距 - 12px
  static const double md = 12.0;
  
  /// 标准间距 - 16px
  static const double lg = 16.0;
  
  /// 大间距 - 20px
  static const double xl = 20.0;
  
  /// 超大间距 - 24px
  static const double xxl = 24.0;
  
  /// 巨大间距 - 32px
  static const double xxxl = 32.0;
  
  /// 超巨大间距 - 40px
  static const double huge = 40.0;
  
  /// 最大间距 - 48px
  static const double massive = 48.0;
  
  // ==================== 页面内边距 ====================
  
  /// 页面水平内边距
  static const double pageHorizontal = 16.0;
  
  /// 页面垂直内边距
  static const double pageVertical = 16.0;
  
  /// 页面内边距
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: pageHorizontal,
    vertical: pageVertical,
  );
  
  /// 仅水平页面内边距
  static const EdgeInsets pageHorizontalPadding = EdgeInsets.symmetric(
    horizontal: pageHorizontal,
  );
  
  // ==================== 卡片内边距 ====================
  
  /// 卡片标准内边距
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  
  /// 卡片紧凑内边距
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(12.0);
  
  /// 卡片宽松内边距
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(20.0);
  
  // ==================== 列表内边距 ====================
  
  /// 列表项水平内边距
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 12.0,
  );
  
  /// 列表项紧凑内边距
  static const EdgeInsets listItemPaddingCompact = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 8.0,
  );
  
  // ==================== 组件间距 ====================
  
  /// 卡片之间的间距
  static const double cardGap = 12.0;
  
  /// 区块之间的间距
  static const double sectionGap = 24.0;
  
  /// 表单元素之间的间距
  static const double formGap = 16.0;
  
  /// 按钮之间的间距
  static const double buttonGap = 12.0;
  
  /// 图标与文字之间的间距
  static const double iconTextGap = 8.0;
  
  // ==================== 圆角 ====================
  
  /// 小圆角 - 8px
  static const double radiusSm = 8.0;
  
  /// 中圆角 - 12px
  static const double radiusMd = 12.0;
  
  /// 标准圆角 - 16px
  static const double radiusLg = 16.0;
  
  /// 大圆角 - 20px
  static const double radiusXl = 20.0;
  
  /// 超大圆角 - 24px
  static const double radiusXxl = 24.0;
  
  /// 圆形
  static const double radiusFull = 999.0;
  
  // ==================== 常用 BorderRadius ====================
  
  static BorderRadius get borderRadiusSm => BorderRadius.circular(radiusSm);
  static BorderRadius get borderRadiusMd => BorderRadius.circular(radiusMd);
  static BorderRadius get borderRadiusLg => BorderRadius.circular(radiusLg);
  static BorderRadius get borderRadiusXl => BorderRadius.circular(radiusXl);
  static BorderRadius get borderRadiusXxl => BorderRadius.circular(radiusXxl);
  
  // ==================== 组件高度 ====================
  
  /// 按钮高度 - 标准
  static const double buttonHeight = 48.0;
  
  /// 按钮高度 - 小
  static const double buttonHeightSm = 36.0;
  
  /// 按钮高度 - 大
  static const double buttonHeightLg = 56.0;
  
  /// 输入框高度
  static const double inputHeight = 48.0;
  
  /// 列表项高度
  static const double listItemHeight = 56.0;
  
  /// 底部导航栏高度
  static const double bottomNavHeight = 64.0;
  
  /// 应用栏高度
  static const double appBarHeight = 56.0;
  
  // ==================== 图标尺寸 ====================
  
  /// 图标尺寸 - 超小
  static const double iconXs = 16.0;
  
  /// 图标尺寸 - 小
  static const double iconSm = 20.0;
  
  /// 图标尺寸 - 中
  static const double iconMd = 24.0;
  
  /// 图标尺寸 - 大
  static const double iconLg = 32.0;
  
  /// 图标尺寸 - 超大
  static const double iconXl = 48.0;
  
  // ==================== 安全区域 ====================
  
  /// 底部安全区域（底部导航）
  static const double bottomSafeArea = 80.0;
}
