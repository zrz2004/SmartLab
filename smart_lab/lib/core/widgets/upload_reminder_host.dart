import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../di/injection.dart';
import '../services/notification_service.dart';
import '../services/upload_reminder_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class UploadReminderHost extends StatefulWidget {
  final Widget child;

  const UploadReminderHost({
    super.key,
    required this.child,
  });

  @override
  State<UploadReminderHost> createState() => _UploadReminderHostState();
}

class _UploadReminderHostState extends State<UploadReminderHost>
    with WidgetsBindingObserver {
  final UploadReminderService _service = getIt<UploadReminderService>();
  final NotificationService _notificationService = getIt<NotificationService>();

  StreamSubscription<Map<String, dynamic>>? _tapSubscription;
  Timer? _ticker;
  bool _dialogVisible = false;
  bool _isCheckingReminder = false;
  Map<String, dynamic>? _deferredReminderPayload;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tapSubscription = _notificationService.uploadReminderTapStream.listen(
      _handleReminderPayload,
    );
    _ticker = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _scheduleReminderCheck(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _syncReminderConfiguration(forceRefresh: true);
      _scheduleReminderCheck();
      final payload = _notificationService.takePendingUploadReminderPayload();
      if (payload != null) {
        _handleReminderPayload(payload);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncReminderConfiguration(forceRefresh: true)
          .then((_) => _scheduleReminderCheck());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _processDeferredReminderPayload();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tapSubscription?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _syncReminderConfiguration({bool forceRefresh = false}) async {
    if (!mounted) return;
    final authState = context.read<AuthBloc>().state;
    try {
      await _service.syncReminderConfiguration(
        user: authState.user,
        labs: authState.accessibleLabs,
        forceRefresh: forceRefresh,
      );
    } catch (_) {
      // Reminder sync should never block the app shell.
    }
  }

  void _scheduleReminderCheck({Duration delay = Duration.zero}) {
    if (delay == Duration.zero) {
      unawaited(_checkReminder());
      return;
    }

    Future<void>.delayed(delay, () async {
      if (!mounted) return;
      await _checkReminder();
    });
  }

  bool _isRouteReadyForReminder() {
    final path = GoRouter.of(context).routeInformationProvider.value.uri.path;
    return path != '/login' && path != '/register' && path != '/select-lab';
  }

  void _processDeferredReminderPayload() {
    final payload = _deferredReminderPayload;
    if (payload == null) {
      return;
    }
    _handleReminderPayload(payload);
  }

  Future<void> _checkReminder() async {
    if (!mounted || _dialogVisible || _isCheckingReminder) {
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (!authState.isLoggedIn ||
        authState.user == null ||
        authState.currentLabId == null ||
        !_isRouteReadyForReminder()) {
      return;
    }

    final dialogTheme = Theme.of(context);

    _isCheckingReminder = true;
    try {
      final reminder = await _service.getDueReminder(
        user: authState.user,
        labs: authState.accessibleLabs,
      );
      if (!mounted || reminder == null || !_isRouteReadyForReminder()) {
        return;
      }

      await _service.markReminderShown(
        userId: authState.user!.id,
        reminder: reminder,
      );
      if (!mounted) {
        return;
      }

      _dialogVisible = true;
      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: true,
        builder: (dialogContext) {
          final pendingNames =
              reminder.pendingLabs.map((lab) => lab.name).join('、');
          return AlertDialog(
            title: Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(reminder.title)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.description,
                  style: dialogTheme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: AppSpacing.borderRadiusMd,
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text('待上传实验室：$pendingNames'),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '仅学生账号会收到此提醒。完成图片上传后，本时段内不会重复弹出。',
                  style: dialogTheme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('稍后提醒'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _openEnvironmentForLab(reminder.pendingLabs.first.id);
                },
                child: const Text('立即上传'),
              ),
            ],
          );
        },
      );
    } finally {
      _dialogVisible = false;
      _isCheckingReminder = false;
    }
  }

  void _handleReminderPayload(Map<String, dynamic> payload) {
    final labId = payload['labId']?.toString();
    if (labId == null || labId.isEmpty || !mounted) {
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (!authState.isLoggedIn ||
        authState.user == null ||
        authState.currentLabId == null ||
        !_isRouteReadyForReminder()) {
      _deferredReminderPayload = payload;
      return;
    }

    if (!authState.hasLabAccess(labId)) {
      _deferredReminderPayload = null;
      return;
    }

    _deferredReminderPayload = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openEnvironmentForLab(labId);
    });
  }

  void _openEnvironmentForLab(String labId) {
    final authState = context.read<AuthBloc>().state;
    if (!authState.isLoggedIn || authState.user == null) {
      return;
    }
    if (!authState.hasLabAccess(labId)) {
      return;
    }
    if (authState.currentLabId != labId) {
      context.read<AuthBloc>().add(AuthLabChanged(labId: labId));
    }
    GoRouter.of(context).go('/environment');
  }

  @override
  Widget build(BuildContext context) {
    if (_deferredReminderPayload != null && _isRouteReadyForReminder()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _processDeferredReminderPayload();
      });
    }

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.user != current.user ||
          previous.currentLabId != current.currentLabId,
      listener: (_, state) async {
        if (state.status == AuthStatus.loading ||
            state.status == AuthStatus.checking) {
          return;
        }

        await _syncReminderConfiguration(forceRefresh: true);

        if (!state.isLoggedIn || state.user == null) {
          return;
        }

        _scheduleReminderCheck(
          delay: const Duration(milliseconds: 350),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _processDeferredReminderPayload();
        });
      },
      child: widget.child,
    );
  }
}
