import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../auth_redirect.dart';
import 'auth_scaffold.dart';
import 'auth_widgets.dart';

/// Final step of password recovery. Reached only with a session (the
/// recovery code was accepted), so on success we simply continue into the
/// app.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscure = true;
  bool _busy = false;
  Object? _error;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    final t = AppLocalizations.of(context)!;
    try {
      await ref.read(authControllerProvider).updatePassword(_passwordCtrl.text);
      // Clear before navigating, or the router sends the doctor straight
      // back here while the userUpdated event is still on its way.
      ref.read(passwordRecoveryPendingProvider.notifier).clear();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.authPasswordUpdated)));
      context.go(kHomePath);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return AuthScaffold(
      title: t.authResetTitle,
      subtitle: t.authResetSubtitle,
      icon: Icons.password_rounded,
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                label: t.authNewPassword,
                icon: Icons.lock_outline_rounded,
                controller: _passwordCtrl,
                hint: t.authPasswordHint,
                helper: t.authPasswordRules,
                obscureText: _obscure,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                enabled: !_busy,
                autofocus: true,
                suffix: PasswordVisibilityToggle(
                  obscured: _obscure,
                  onToggle: () => setState(() => _obscure = !_obscure),
                ),
                validator: (v) => (v ?? '').length < kMinPasswordLength
                    ? t.authPasswordRules
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AuthTextField(
                label: t.authConfirmPassword,
                icon: Icons.lock_outline_rounded,
                controller: _confirmCtrl,
                hint: t.authPasswordHint,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                enabled: !_busy,
                validator: (v) =>
                    v != _passwordCtrl.text ? t.authPasswordsDoNotMatch : null,
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                AuthErrorBanner(
                  message: authErrorMessage(t, _error!),
                  details: authErrorDetails(_error!),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AuthPrimaryButton(
                label: t.authUpdatePassword,
                loading: _busy,
                trailingIcon: Icons.check_rounded,
                onTap: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
