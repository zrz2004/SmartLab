import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/user.dart';
import '../bloc/auth_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserRole _selectedRole = UserRole.undergraduate;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isLoading = context.select((AuthBloc bloc) => bloc.state.isLoading);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.registrationPending) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(l10n.t('register.title'))),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('register.desc'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _RegisterField(
                  controller: _nameController,
                  enabled: !isLoading,
                  label: l10n.t('register.name'),
                  hint: l10n.t('register.name'),
                  validator: _required,
                ),
                const SizedBox(height: AppSpacing.lg),
                _RegisterField(
                  controller: _usernameController,
                  enabled: !isLoading,
                  label: l10n.t('register.studentOrEmployeeId'),
                  hint: l10n.t('register.studentOrEmployeeId'),
                  validator: _required,
                ),
                const SizedBox(height: AppSpacing.lg),
                _RegisterField(
                  controller: _emailController,
                  enabled: !isLoading,
                  label: l10n.t('register.email'),
                  hint: l10n.t('register.email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return l10n.t('register.enterEmail');
                    if (!value.contains('@')) return l10n.t('register.invalidEmail');
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                _RegisterField(
                  controller: _phoneController,
                  enabled: !isLoading,
                  label: l10n.t('register.phone'),
                  hint: l10n.t('register.phone'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.t('register.requestedRole'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  alignment: Alignment.centerLeft,
                  child: DropdownButtonFormField<UserRole>(
                    initialValue: _selectedRole,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    items: [
                      DropdownMenuItem(value: UserRole.undergraduate, child: Text(l10n.t('role.undergraduate'))),
                      DropdownMenuItem(value: UserRole.graduate, child: Text(l10n.t('role.graduate'))),
                      DropdownMenuItem(value: UserRole.teacher, child: Text(l10n.t('role.teacher'))),
                    ],
                    onChanged: isLoading
                        ? null
                        : (value) {
                            if (value != null) setState(() => _selectedRole = value);
                          },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _RegisterField(
                  controller: _passwordController,
                  enabled: !isLoading,
                  label: l10n.t('register.password'),
                  hint: l10n.t('register.password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.length < 6) return l10n.t('register.atLeast6Chars');
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                _RegisterField(
                  controller: _confirmPasswordController,
                  enabled: !isLoading,
                  label: l10n.t('register.confirmPassword'),
                  hint: l10n.t('register.confirmPassword'),
                  obscureText: true,
                  validator: (value) =>
                      value != _passwordController.text ? l10n.t('register.passwordMismatch') : null,
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(l10n.t('common.submit')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return context.l10n.t('register.required');
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          AuthRegisterRequested(
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            requestedRole: _selectedRole,
          ),
        );
  }
}

class _RegisterField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;

  const _RegisterField({
    required this.controller,
    required this.enabled,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            filled: true,
            fillColor: AppColors.inputBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.critical),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.critical, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
