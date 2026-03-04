import 'package:flutter/material.dart';

/// 应用颜色系统
/// 
/// 设计理念: 工业安全风格 + 现代简约
/// - 主色调: 沉稳的深蓝色，代表专业与信任
/// - 警示色: 分级的红黄绿系统，符合工业安全标准
/// - 辅助色: 柔和的灰度系统，确保信息层次清晰
class AppColors {
  AppColors._();

  // ==================== 品牌色 ====================
  
  /// 主色 - 深邃科技蓝
  static const Color primary = Color(0xFF1E3A5F);
  
  /// 主色浅色变体
  static const Color primaryLight = Color(0xFF3D5A80);
  
  /// 主色深色变体
  static const Color primaryDark = Color(0xFF0D1B2A);
  
  /// 强调色 - 活力青色
  static const Color accent = Color(0xFF00B4D8);
  
  /// 强调色浅色变体
  static const Color accentLight = Color(0xFF90E0EF);
  
  // ==================== 状态色 - 安全分级系统 ====================
  
  /// 安全/正常 - 祖母绿
  static const Color safe = Color(0xFF10B981);
  static const Color safeLight = Color(0xFFD1FAE5);
  static const Color safeDark = Color(0xFF059669);
  
  /// 警告 - 琥珀黄
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFD97706);
  
  /// 危急/错误 - 警示红
  static const Color critical = Color(0xFFEF4444);
  static const Color criticalLight = Color(0xFFFEE2E2);
  static const Color criticalDark = Color(0xFFDC2626);
  
  /// 信息 - 天空蓝
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF2563EB);
  
  // ==================== 功能模块色 ====================
  
  /// 环境监测 - 清新绿
  static const Color environment = Color(0xFF22C55E);
  static const Color environmentLight = Color(0xFFDCFCE7);
  
  /// 电源管理 - 能量橙
  static const Color power = Color(0xFFF97316);
  static const Color powerLight = Color(0xFFFFEDD5);
  
  /// 水路安防 - 清澈蓝
  static const Color water = Color(0xFF06B6D4);
  static const Color waterLight = Color(0xFFCFFAFE);
  
  /// 危化品管理 - 警示紫
  static const Color chemical = Color(0xFF8B5CF6);
  static const Color chemicalLight = Color(0xFFEDE9FE);
  
  /// 门窗安防 - 稳重棕
  static const Color security = Color(0xFF78716C);
  static const Color securityLight = Color(0xFFF5F5F4);
  
  // ==================== 中性色 - 亮色主题 ====================
  
  /// 背景色
  static const Color background = Color(0xFFF8FAFC);
  
  /// 表面色
  static const Color surface = Color(0xFFFFFFFF);
  
  /// 边框色
  static const Color border = Color(0xFFE2E8F0);
  
  /// 分割线色
  static const Color divider = Color(0xFFF1F5F9);
  
  /// 输入框背景
  static const Color inputBackground = Color(0xFFF8FAFC);
  
  /// 进度条轨道
  static const Color progressTrack = Color(0xFFE2E8F0);
  
  // ==================== 文字色 - 亮色主题 ====================
  
  /// 主要文字
  static const Color textPrimary = Color(0xFF1E293B);
  
  /// 次要文字
  static const Color textSecondary = Color(0xFF64748B);
  
  /// 辅助文字
  static const Color textTertiary = Color(0xFF94A3B8);
  
  /// 禁用文字
  static const Color textDisabled = Color(0xFFCBD5E1);
  
  // ==================== 中性色 - 暗色主题 ====================
  
  /// 暗色背景
  static const Color darkBackground = Color(0xFF0F172A);
  
  /// 暗色表面
  static const Color darkSurface = Color(0xFF1E293B);
  
  /// 暗色边框
  static const Color darkBorder = Color(0xFF334155);
  
  /// 暗色主要文字
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  
  /// 暗色次要文字
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  
  /// 暗色辅助文字
  static const Color darkTextTertiary = Color(0xFF64748B);
  
  // ==================== 渐变色 ====================
  
  /// 主色渐变
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );
  
  /// 安全渐变
  static const LinearGradient safeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [safe, Color(0xFF34D399)],
  );
  
  /// 警告渐变
  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warning, Color(0xFFFBBF24)],
  );
  
  /// 危急渐变
  static const LinearGradient criticalGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [critical, Color(0xFFF87171)],
  );
  
  /// 电源模块渐变
  static const LinearGradient powerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [power, Color(0xFFFB923C)],
  );
  
  /// 水路模块渐变
  static const LinearGradient waterGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [water, Color(0xFF22D3EE)],
  );
  
  // ==================== 阴影色 ====================
  
  /// 卡片阴影
  static const Color cardShadow = Color(0x0F1E293B);
  
  /// 弹窗阴影
  static const Color dialogShadow = Color(0x1F1E293B);
  
  /// 按钮阴影
  static const Color buttonShadow = Color(0x2F1E3A5F);
  
  // ==================== 覆盖层 ====================
  
  /// 遮罩层
  static const Color overlay = Color(0x80000000);
  
  /// 亮色遮罩
  static const Color overlayLight = Color(0x40FFFFFF);
}
