import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import 'auth_scaffold.dart';
import 'auth_widgets.dart';
import 'verify_otp_screen.dart';

/// Step 1 of password recovery: ask for the e-mail, have Supabase send the
/// 8-digit recovery code, then collect it on [VerifyOtpScreen].
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  bool _busy = false;
  Object? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
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
    final email = _emailCtrl.text.trim();
    try {
      await ref.read(authControllerProvider).requestPasswordReset(email);
      if (!mounted) return;
      setState(() => _busy = false);
      context.push(
        verifyLocation(email: email, purpose: VerifyPurpose.recovery),
      );
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
      title: t.authForgotTitle,
      subtitle: t.authForgotSubtitle,
      icon: Icons.lock_reset_rounded,
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              label: t.authEmail,
              icon: Icons.alternate_email_rounded,
              controller: _emailCtrl,
              hint: t.authEmailHint,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.username],
              enabled: !_busy,
              autofocus: true,
              validator: (v) => existingEmailFieldError(t, v),
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
              label: t.authSendCode,
              loading: _busy,
              trailingIcon: Icons.send_rounded,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
