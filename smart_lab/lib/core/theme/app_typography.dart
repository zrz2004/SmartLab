import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 应用字体排版系统
/// 
/// 设计理念:
/// - 使用系统默认字体（待添加自定义字体后可更新）
/// - 遵循 8pt 网格系统
class AppTypography {
  AppTypography._();

  // ==================== 字体家族 ====================
  // 暂时使用 null 表示系统默认字体
  static const String? fontFamilyPrimary = null;
  static const String? fontFamilyNumeric = null;
  
  // ==================== 亮色主题文字样式 ====================
  
  static TextTheme get textTheme {
    return const TextTheme(
      // 超大标题 - 用于启动页或空状态
      displayLarge: TextStyle(
        fontFamily: fontFamilyPrimary,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      ),
      
      // 大标题 - 页面主标题
      displayMedium: TextStyle(
        fontFamily: fontFamilyPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.29,
        letterSpacing: -0.25,
        color: AppColors.textPrimary,
      ),
      
      // 中标题
      displaySmall: TextStyle(
        fontFamily: fontFamilyPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.33,
        color: AppColors.textPrimary,
      ),
      
      // 头条标题 - 仪表盘数值
      headlineLarge: TextStyle(
        fontFamily: fontFamilyNumeric,
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -1,
        color: AppColors.textPrimary,
      ),
      
      // 中等头条 - 卡片数值
      headlineMedium: TextStyle(
        fontFamily: fontFamilyNumeric,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      ),
      
      // 小头条 - 统计数字
      headlineSmall: TextStyle(
        fontFamily: fontFamilyNumeric,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.33,
        color: AppColors.textPrimary,
      ),
      
      // 大标题文字 - 区块标题
      titleLarge: TextStyle(
        fontFamily: fontFamilyPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textPrimary,
      ),
      
      // 中标题文字 - 卡片标题
      titleMedium: TextStyle(
        fontFamily: fontFamilyPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: AppColors.textPrimary,
      ),
      
      // 小标题文字 - 列表项标题
      titleSmall: TextStyle(
        fontFamily: fontFamilyPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.43,
        color: AppColors.textPrimary,
      ),
      
      // 大正文 - 主要内容
      bodyLarge: TextStyle(
        fontFamily: fontFamilyPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textPrimary,
      ),
      
      // 中正文 - 次要内容
      bodyMedium: TextStyle(
        fontFamily: fontFamilyPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.43,
        color: AppColors.textSecondary,
      ),
      
      // 小正文 - 辅助信息
      bodySmall: TextStyle(
        fontFamily: fontFamilyPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.33,
        color: AppColors.textTertiary,
      ),
      
      // 大标签 - 按钮文字
      labelLarge: TextStyle(
        fontFamily: fontFamilyPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
        letterSpacing: 0.25,
        color: AppColors.textPrimary,
      ),
      
      // 中标签 - 标签文字
      labelMedium: TextStyle(
        fontFamily: fontFamilyPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.33,
        letterSpacing: 0.5,
        color: AppColors.textSecondary,
      ),
      
      // 小标签 - 徽章、角标
      labelSmall: TextStyle(
        fontFamily: fontFamilyPrimary,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.5,
        color: AppColors.textTertiary,
      ),
    );
  }
  
  // ==================== 暗色主题文字样式 ====================
  
  static TextTheme get darkTextTheme {
    return TextTheme(
      displayLarge: textTheme.displayLarge!.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      displayMedium: textTheme.displayMedium!.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      displaySmall: textTheme.displaySmall!.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      headlineLarge: textTheme.headlineLarge!.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      headlineMedium: textTheme.headlineMedium!.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      headlineSmall: textTheme.headlineSmall!.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      titleLarge: textTheme.titleLarge!.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      titleMedium: textTheme.titleMedium!.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      titleSmall: textTheme.titleSmall!.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      bodyLarge: textTheme.bodyLarge!.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      bodyMedium: textTheme.bodyMedium!.copyWith(
        color: AppColors.darkTextSecondary,
      ),
      bodySmall: textTheme.bodySmall!.copyWith(
        color: AppColors.darkTextTertiary,
      ),
      labelLarge: textTheme.labelLarge!.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      labelMedium: textTheme.labelMedium!.copyWith(
        color: AppColors.darkTextSecondary,
      ),
      labelSmall: textTheme.labelSmall!.copyWith(
        color: AppColors.darkTextTertiary,
      ),
    );
  }
  
  // ==================== 特殊样式 ====================
  
  /// 安全评分数字样式
  static const TextStyle safetyScore = TextStyle(
    fontFamily: fontFamilyNumeric,
    fontSize: 56,
    fontWeight: FontWeight.w700,
    height: 1,
    letterSpacing: -2,
  );
  
  /// 传感器数值样式
  static const TextStyle sensorValue = TextStyle(
    fontFamily: fontFamilyNumeric,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  /// 单位文字样式
  static const TextStyle unit = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    color: AppColors.textSecondary,
  );
  
  /// 时间戳样式
  static const TextStyle timestamp = TextStyle(
    fontFamily: fontFamilyNumeric,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
    letterSpacing: 0.5,
    color: AppColors.textTertiary,
  );
  
  /// 状态标签样式
  static const TextStyle statusLabel = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.27,
    letterSpacing: 0.5,
  );
}
