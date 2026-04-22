import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/dynamic_text_localizer.dart';
import '../../../../core/localization/locale_cubit.dart';
import '../../../../core/services/upload_reminder_models.dart';
import '../../../../core/services/upload_reminder_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../alerts/domain/entities/alert.dart';
import '../../../alerts/presentation/bloc/alerts_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../chemicals/presentation/bloc/chemicals_bloc.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../environment/presentation/bloc/environment_bloc.dart';
import '../../../power/presentation/bloc/power_bloc.dart';
import '../../../security/presentation/bloc/security_bloc.dart';

class MainPage extends StatefulWidget {
  final Widget child;

  const MainPage({
    super.key,
    required this.child,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final Set<String> _shownAlertIds = <String>{};
  final UploadReminderService _uploadReminderService =
      getIt<UploadReminderService>();

  final List<_NavItem> _navItems = const [
    _NavItem(
      path: '/',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      labelKey: 'nav.home',
    ),
    _NavItem(
      path: '/environment',
      icon: Icons.air_outlined,
      activeIcon: Icons.air,
      labelKey: 'nav.environment',
    ),
    _NavItem(
      path: '/power',
      icon: Icons.flash_on_outlined,
      activeIcon: Icons.flash_on,
      labelKey: 'nav.power',
    ),
    _NavItem(
      path: '/security',
      icon: Icons.shield_outlined,
      activeIcon: Icons.shield,
      labelKey: 'nav.security',
    ),
    _NavItem(
      path: '/chemicals',
      icon: Icons.science_outlined,
      activeIcon: Icons.science,
      labelKey: 'nav.chemicals',
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateCurrentIndex();
  }

  void _updateCurrentIndex() {
    final location = GoRouterState.of(context).uri.path;
    final index = _navItems.indexWhere((item) => item.path == location);
    if (index != -1 && index != _currentIndex) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              previous.currentLabId != current.currentLabId,
          listener: (context, state) {
            if (state.currentLabId == null) return;
            _shownAlertIds.clear();
            context.read<DashboardBloc>().add(LoadDashboardData());
            context.read<EnvironmentBloc>().add(LoadEnvironmentData());
            context.read<PowerBloc>().add(LoadPowerData());
            context.read<SecurityBloc>().add(LoadSecurityData());
            context.read<ChemicalsBloc>().add(LoadChemicals(labId: state.currentLabId));
            context.read<AlertsBloc>().add(LoadAlerts());
          },
        ),
        BlocListener<AlertsBloc, AlertsState>(
          listener: (context, state) {
            final nextAlert = state.alerts.firstWhere(
              (alert) =>
                  !alert.isAcknowledged &&
                  (alert.level == AlertLevel.warning ||
                      alert.level == AlertLevel.critical) &&
                  !_shownAlertIds.contains(alert.id),
              orElse: () => Alert(
                id: '',
                type: AlertType.other,
                level: AlertLevel.info,
                title: '',
                message: '',
                deviceId: '',
                deviceName: '',
                timestamp: DateTime.now(),
              ),
            );
            if (nextAlert.id.isEmpty) return;
            _shownAlertIds.add(nextAlert.id);
            _showAlertWarningDialog(context, nextAlert);
          },
        ),
      ],
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: widget.child,
        bottomNavigationBar: _buildBottomNav(context),
      ),
    );
  }

  Future<void> _showAlertWarningDialog(BuildContext context, Alert alert) async {
    final isCritical = alert.level == AlertLevel.critical;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isCritical
                  ? Icons.warning_amber_rounded
                  : Icons.notification_important_rounded,
              color: isCritical ? AppColors.critical : AppColors.warning,
            ),
            const SizedBox(width: 8),
            Text(isCritical ? '严重警告' : '安全预警'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DynamicTextLocalizer.alertTitle(context, alert.title),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(DynamicTextLocalizer.alertMessage(context, alert.message)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.t('common.ok')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.push('/alerts');
            },
            child: const Text('查看处理'),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final l10n = context.l10n;
    return AppBar(
      titleSpacing: 12,
      title: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final currentLab = state.currentLab;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.shield,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.t('app.name'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                currentLab?.name ?? l10n.t('app.selectLab'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
              ),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => context.push('/alerts'),
        ),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return PopupMenuButton<String>(
              tooltip: l10n.t('app.labsAndAccount'),
              onSelected: (value) {
                if (value == 'logout') {
                  context.read<AuthBloc>().add(const AuthLogoutRequested());
                  context.go('/login');
                  return;
                }
                if (value == 'lang-zh' || value == 'lang-en') {
                  final code = value == 'lang-zh' ? 'zh' : 'en';
                  context.read<LocaleCubit>().setLanguage(code);
                  return;
                }
                if (value == 'select-lab') {
                  context.push('/select-lab');
                  return;
                }
                if (value == 'reminder-settings') {
                  _openReminderSettingsDialog(state);
                  return;
                }
                if (state.hasLabAccess(value)) {
                  context.read<AuthBloc>().add(AuthLabChanged(labId: value));
                }
              },
              itemBuilder: (context) {
                final items = <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    enabled: false,
                    value: 'header',
                    child: Text(
                      state.user == null
                          ? l10n.t('app.notLoggedIn')
                          : '${state.user!.name} - ${l10n.t('role.${state.user!.role.name}')}',
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'select-lab',
                    child: Text(l10n.t('app.openLabSelector')),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    enabled: false,
                    value: 'language-header',
                    child: Text(l10n.t('app.language')),
                  ),
                  PopupMenuItem<String>(
                    value: 'lang-zh',
                    child: Row(
                      children: [
                        Icon(
                          Localizations.localeOf(context).languageCode == 'zh'
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 18,
                          color:
                              Localizations.localeOf(context).languageCode ==
                                      'zh'
                                  ? AppColors.primary
                                  : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 8),
                        Text(l10n.t('app.languageChinese')),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'lang-en',
                    child: Row(
                      children: [
                        Icon(
                          Localizations.localeOf(context).languageCode == 'en'
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 18,
                          color:
                              Localizations.localeOf(context).languageCode ==
                                      'en'
                                  ? AppColors.primary
                                  : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 8),
                        Text(l10n.t('app.languageEnglish')),
                      ],
                    ),
                  ),
                ];

                for (final lab in state.accessibleLabs) {
                  items.add(
                    PopupMenuItem<String>(
                      value: lab.id,
                      child: Row(
                        children: [
                          Icon(
                            lab.id == state.currentLabId
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 18,
                            color: lab.id == state.currentLabId
                                ? AppColors.primary
                                : AppColors.textTertiary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(lab.name)),
                        ],
                      ),
                    ),
                  );
                }

                items.add(const PopupMenuDivider());
                if (state.user?.canManageLab == true) {
                  items.add(
                    const PopupMenuItem<String>(
                      value: 'reminder-settings',
                      child: Text('上传提醒时间'),
                    ),
                  );
                  items.add(const PopupMenuDivider());
                }
                items.add(
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Text(l10n.t('common.logout')),
                  ),
                );
                return items;
              },
              child: const Padding(
                padding: EdgeInsets.only(right: AppSpacing.md),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.background,
                  child: Icon(
                    Icons.person,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: AppSpacing.bottomNavHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _navItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == _currentIndex;
              return _NavButton(
                item: item,
                isSelected: isSelected,
                onTap: () {
                  setState(() => _currentIndex = index);
                  context.go(item.path);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _openReminderSettingsDialog(
    AuthState authState,
  ) async {
    final currentLab = authState.currentLab;
    if (currentLab == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择实验室后再设置提醒时间。')),
      );
      return;
    }

    final pageContext = context;
    final settingsFuture = _uploadReminderService.getReminderSettings(
      currentLab,
      forceRefresh: true,
    );
    var initialized = false;
    var enabled = true;
    var firstTime = const TimeOfDay(hour: 19, minute: 0);
    var secondTime = const TimeOfDay(hour: 23, minute: 0);
    var saving = false;

    await showDialog<void>(
      context: pageContext,
      builder: (dialogContext) {
        return FutureBuilder<LabReminderSettings>(
          future: settingsFuture,
          builder: (dialogContext, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const AlertDialog(
                content: SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (!snapshot.hasData) {
              return AlertDialog(
                title: const Text('上传提醒时间'),
                content: const Text('读取提醒设置失败，请稍后重试。'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('关闭'),
                  ),
                ],
              );
            }

            if (!initialized) {
              initialized = true;
              enabled = snapshot.data!.enabled;
              firstTime = _parseTimeOfDay(snapshot.data!.firstSlot.label);
              secondTime = _parseTimeOfDay(snapshot.data!.secondSlot.label);
            }

            return StatefulBuilder(
              builder: (dialogContext, setDialogState) {
            Future<void> pickTime(bool isFirst) async {
              final selected = await showTimePicker(
                context: dialogContext,
                initialTime: isFirst ? firstTime : secondTime,
              );
              if (selected == null) return;
              setDialogState(() {
                if (isFirst) {
                  firstTime = selected;
                } else {
                  secondTime = selected;
                }
              });
            }

            final sameTime = _formatTimeOfDay(firstTime) ==
                _formatTimeOfDay(secondTime);

                return AlertDialog(
                  title: Text('${currentLab.name} 上传提醒'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('启用提醒'),
                        subtitle: const Text('仅对学生显示系统通知'),
                        value: enabled,
                        onChanged: (value) {
                          setDialogState(() => enabled = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      _ReminderTimeTile(
                        title: '第一次提醒',
                        value: _formatTimeOfDay(firstTime),
                        onTap: saving ? null : () => pickTime(true),
                      ),
                      const SizedBox(height: 8),
                      _ReminderTimeTile(
                        title: '第二次提醒',
                        value: _formatTimeOfDay(secondTime),
                        onTap: saving ? null : () => pickTime(false),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '修改后，学生设备会在下次打开 App 或回到前台时同步新的提醒时间。',
                        style: Theme.of(dialogContext)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      if (sameTime) ...[
                        const SizedBox(height: 8),
                        const Text(
                          '两个提醒时间不能相同。',
                          style: TextStyle(color: AppColors.critical),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          saving ? null : () => Navigator.of(dialogContext).pop(),
                      child: const Text('取消'),
                    ),
                    FilledButton(
                      onPressed: saving || sameTime
                          ? null
                          : () async {
                              setDialogState(() => saving = true);
                              try {
                                await _uploadReminderService
                                    .updateReminderSettings(
                                  lab: currentLab,
                                  enabled: enabled,
                                  firstReminderTime:
                                      _formatTimeOfDay(firstTime),
                                  secondReminderTime:
                                      _formatTimeOfDay(secondTime),
                                );
                                await _uploadReminderService
                                    .syncReminderConfiguration(
                                  user: authState.user,
                                  labs: authState.accessibleLabs,
                                  forceRefresh: true,
                                );
                                if (!dialogContext.mounted) return;
                                Navigator.of(dialogContext).pop();
                                if (!mounted) return;
                                ScaffoldMessenger.of(pageContext).showSnackBar(
                                  const SnackBar(
                                    content: Text('上传提醒时间已保存。'),
                                  ),
                                );
                              } catch (_) {
                                if (!dialogContext.mounted) return;
                                setDialogState(() => saving = false);
                                ScaffoldMessenger.of(dialogContext).showSnackBar(
                                  const SnackBar(
                                    content: Text('保存失败，请检查网络或后端服务。'),
                                  ),
                                );
                              }
                            },
                      child: Text(saving ? '保存中...' : '保存'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  TimeOfDay _parseTimeOfDay(String value) {
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 19,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  String _formatTimeOfDay(TimeOfDay value) {
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}

class _NavItem {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String labelKey;

  const _NavItem({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.labelKey,
  });
}

class _ReminderTimeTile extends StatelessWidget {
  const _ReminderTimeTile({
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusMd,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(value),
                ],
              ),
            ),
            const Icon(Icons.schedule_rounded),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              size: 24,
              color: isSelected ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(height: 2),
            Text(
              context.l10n.t(item.labelKey),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color:
                    isSelected ? AppColors.primary : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
