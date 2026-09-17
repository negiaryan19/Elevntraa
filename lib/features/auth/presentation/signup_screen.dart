import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../auth_redirect.dart';
import 'auth_scaffold.dart';
import 'auth_widgets.dart';
import 'verify_otp_screen.dart';

/// Create a per-doctor account. E-mail confirmation is on server-side, so a
/// successful sign-up leads to the 8-digit code screen.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscure = true;
  bool _busy = false;
  Object? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
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
    final email = _emailCtrl.text.trim();
    try {
      final outcome = await ref
          .read(authControllerProvider)
          .signUp(email: email, password: _passwordCtrl.text);
      if (!mounted) return;
      switch (outcome) {
        case SignUpOutcome.verificationRequired:
          setState(() => _busy = false);
          context.push(
            verifyLocation(email: email, purpose: VerifyPurpose.signup),
          );
        case SignUpOutcome.signedIn:
          // Confirmation disabled server-side: the router redirects.
          break;
      }
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
    final error = _error;
    final userExists =
        error != null &&
        authErrorKind(error) == AuthErrorKind.userAlreadyExists;

    return AuthScaffold(
      title: t.authSignUpTitle,
      subtitle: t.authSignUpSubtitle,
      icon: Icons.person_add_alt_1_rounded,
      showBack: true,
      footer: AuthLinkRow(
        question: t.authHaveAccount,
        linkLabel: t.authSignIn,
        onTap: () => context.go(kLoginPath),
      ),
      child: AutofillGroup(
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
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                enabled: !_busy,
                validator: (v) =>
                    isValidEmail(v ?? '') ? null : t.authEmailInvalid,
              ),
              const SizedBox(height: AppSpacing.md),
              AuthTextField(
                label: t.authPassword,
                icon: Icons.lock_outline_rounded,
                controller: _passwordCtrl,
                hint: t.authPasswordHint,
                helper: t.authPasswordRules,
                obscureText: _obscure,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                enabled: !_busy,
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
              if (error != null) ...[
                const SizedBox(height: AppSpacing.md),
                AuthErrorBanner(
                  message: authErrorMessage(t, error),
                  details: authErrorDetails(error),
                  action: userExists
                      ? AuthLink(
                          label: t.authSignInInstead,
                          onTap: () => context.go(kLoginPath),
                        )
                      : null,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AuthPrimaryButton(
                label: t.authCreateAccount,
                loading: _busy,
                trailingIcon: Icons.arrow_forward_rounded,
                onTap: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
