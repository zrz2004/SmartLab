import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/realtime_chart.dart';
import '../../../../shared/widgets/sensor_gauge.dart';

/// 设备详情页面
class DeviceDetailPage extends StatefulWidget {
  final String deviceId;
  
  const DeviceDetailPage({
    super.key,
    required this.deviceId,
  });

  @override
  State<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  // 模拟设备信息
  late final Map<String, dynamic> _deviceInfo;
  
  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }
  
  void _loadDeviceInfo() {
    // 模拟设备数据
    _deviceInfo = {
      'id': widget.deviceId,
      'name': '温湿度传感器 #${widget.deviceId.hashCode % 100}',
      'type': 'environment',
      'model': 'DHT22-Pro',
      'location': '302 实验室 - A区',
      'status': 'online',
      'lastOnline': DateTime.now().subtract(const Duration(minutes: 2)),
      'installDate': DateTime.now().subtract(const Duration(days: 180)),
      'firmware': 'v2.1.3',
      'protocol': 'MQTT / TLS',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_deviceInfo['name'] ?? '设备详情'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showDeviceSettings(context);
            },
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // 设备状态卡片
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _DeviceStatusCard(deviceInfo: _deviceInfo),
            ),
          ),
          
          // 实时数据
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                '实时数据',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.md),
          ),
          
          // 传感器仪表盘
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.9,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
              ),
              delegate: SliverChildListDelegate([
                SensorGauge(
                  label: '温度',
                  value: 23.5,
                  unit: '°C',
                  minValue: 0,
                  maxValue: 50,
                  warningValue: 28,
                  criticalValue: 35,
                  primaryColor: AppColors.environment,
                  icon: Icons.thermostat,
                ),
                SensorGauge(
                  label: '湿度',
                  value: 45,
                  unit: '%',
                  minValue: 0,
                  maxValue: 100,
                  warningValue: 60,
                  criticalValue: 80,
                  primaryColor: AppColors.water,
                  icon: Icons.water_drop,
                ),
              ]),
            ),
          ),
          
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xl),
          ),
          
          // 历史趋势
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                '历史趋势',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.md),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: RealtimeChart(
                data: _generateMockHistory(),
                title: '温度 (24小时)',
                unit: '°C',
                lineColor: AppColors.environment,
                warningThreshold: 28,
                criticalThreshold: 35,
              ),
            ),
          ),
          
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xl),
          ),
          
          // 设备信息
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                '设备信息',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.md),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _DeviceInfoCard(deviceInfo: _deviceInfo),
            ),
          ),
          
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xl),
          ),
          
          // 操作按钮
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showRebootConfirm(context);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('重启设备'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warning,
                        side: BorderSide(color: AppColors.warning),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showDiagnostics(context);
                      },
                      icon: const Icon(Icons.bug_report),
                      label: const Text('诊断测试'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 底部间距
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.bottomSafeArea),
          ),
        ],
      ),
    );
  }
  
  List<FlSpot> _generateMockHistory() {
    return List.generate(48, (i) {
      final hour = i / 2;
      final baseTemp = 22 + 3 * (hour > 8 && hour < 18 ? 1 : 0);
      final noise = (i % 7 - 3) * 0.3;
      return FlSpot(hour, baseTemp + noise);
    });
  }
  
  void _showDeviceSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '设备设置',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('告警通知'),
              trailing: Switch(value: true, onChanged: (v) {}),
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('阈值配置'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('数据采样间隔'),
              subtitle: const Text('5 秒'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
  
  void _showRebootConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认重启'),
        content: const Text('确定要重启该设备吗？重启期间将无法采集数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('重启指令已发送')),
              );
            },
            child: const Text('确认重启'),
          ),
        ],
      ),
    );
  }
  
  void _showDiagnostics(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设备诊断'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DiagItem(label: '网络连接', status: true),
            _DiagItem(label: 'MQTT 服务', status: true),
            _DiagItem(label: '传感器响应', status: true),
            _DiagItem(label: '固件版本', status: true),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }
}

class _DiagItem extends StatelessWidget {
  final String label;
  final bool status;
  
  const _DiagItem({required this.label, required this.status});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.error,
            color: status ? AppColors.safe : AppColors.critical,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(label),
          const Spacer(),
          Text(
            status ? '正常' : '异常',
            style: TextStyle(
              color: status ? AppColors.safe : AppColors.critical,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// 设备状态卡片
class _DeviceStatusCard extends StatelessWidget {
  final Map<String, dynamic> deviceInfo;
  
  const _DeviceStatusCard({required this.deviceInfo});
  
  @override
  Widget build(BuildContext context) {
    final isOnline = deviceInfo['status'] == 'online';
    
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isOnline ? AppColors.safeLight : AppColors.criticalLight,
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Icon(
              Icons.sensors,
              color: isOnline ? AppColors.safe : AppColors.critical,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deviceInfo['name'] ?? '-',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  deviceInfo['location'] ?? '-',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isOnline ? AppColors.safeLight : AppColors.criticalLight,
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isOnline ? AppColors.safe : AppColors.critical,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isOnline ? '在线' : '离线',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isOnline ? AppColors.safe : AppColors.critical,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 设备信息卡片
class _DeviceInfoCard extends StatelessWidget {
  final Map<String, dynamic> deviceInfo;
  
  const _DeviceInfoCard({required this.deviceInfo});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _InfoRow(label: '设备型号', value: deviceInfo['model'] ?? '-'),
          const Divider(height: 24),
          _InfoRow(label: '设备 ID', value: deviceInfo['id'] ?? '-'),
          const Divider(height: 24),
          _InfoRow(label: '通信协议', value: deviceInfo['protocol'] ?? '-'),
          const Divider(height: 24),
          _InfoRow(label: '固件版本', value: deviceInfo['firmware'] ?? '-'),
          const Divider(height: 24),
          _InfoRow(
            label: '安装日期',
            value: _formatDate(deviceInfo['installDate']),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  
  const _InfoRow({required this.label, required this.value});
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
