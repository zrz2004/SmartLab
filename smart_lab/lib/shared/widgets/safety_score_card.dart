import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// 安全评分卡片组件
/// 
/// 显示实验室整体安全评分
/// 支持动画效果和呼吸灯警示
class SafetyScoreCard extends StatefulWidget {
  final int score;
  final String labName;
  final int alertCount;
  final VoidCallback? onTap;
  
  const SafetyScoreCard({
    super.key,
    required this.score,
    required this.labName,
    this.alertCount = 0,
    this.onTap,
  });
  
  @override
  State<SafetyScoreCard> createState() => _SafetyScoreCardState();
}

class _SafetyScoreCardState extends State<SafetyScoreCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    // 低分数时启动脉冲动画
    if (widget.score < 70) {
      _controller.repeat(reverse: true);
    }
  }
  
  @override
  void didUpdateWidget(SafetyScoreCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.score < 70 && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (widget.score >= 70 && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final (bgGradient, statusText, statusIcon) = _getStatusInfo();
    
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.score < 70 ? _pulseAnimation.value : 1.0,
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: bgGradient,
            borderRadius: AppSpacing.borderRadiusXl,
            boxShadow: [
              BoxShadow(
                color: _getScoreColor().withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部信息行
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.labName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            statusIcon,
                            size: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // 评分显示
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${widget.score}',
                            style: const TextStyle(
                              fontFamily: 'DINAlternate',
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                          Text(
                            '安全指数',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // 进度条
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: widget.score / 100,
                  minHeight: 6,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // 底部统计
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatItem(
                    label: '待处理报警',
                    value: '${widget.alertCount}',
                    icon: Icons.warning_rounded,
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  _StatItem(
                    label: '实时监控',
                    value: '运行中',
                    icon: Icons.sensors,
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  _StatItem(
                    label: 'MQTT',
                    value: '已连接',
                    icon: Icons.wifi,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getScoreColor() {
    if (widget.score >= 90) {
      return AppColors.safe;
    } else if (widget.score >= 70) {
      return AppColors.warning;
    } else {
      return AppColors.critical;
    }
  }
  
  (LinearGradient, String, IconData) _getStatusInfo() {
    if (widget.score >= 90) {
      return (
        AppColors.safeGradient,
        '安全状态良好',
        Icons.check_circle,
      );
    } else if (widget.score >= 70) {
      return (
        AppColors.warningGradient,
        '存在预警，请关注',
        Icons.info,
      );
    } else {
      return (
        AppColors.criticalGradient,
        '存在紧急报警！',
        Icons.error,
      );
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.white.withOpacity(0.8),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
