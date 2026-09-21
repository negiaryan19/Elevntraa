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

  /// The address a "Did you mean …?" warning was last shown for. The first
  /// Create account with a likely typo (`doctor@gmial.com`) stops and shows
  /// the suggestion; a second one with the same address goes ahead, so a
  /// doctor whose address really looks like that is never stuck.
  String? _typoWarnedFor;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(_dropStaleTypoWarning);
  }

  /// The warning is about one exact address: editing the field retires it.
  void _dropStaleTypoWarning() {
    if (_typoWarnedFor != null && _typoWarnedFor != _emailCtrl.text.trim()) {
      setState(() => _typoWarnedFor = null);
    }
  }

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

    final email = _emailCtrl.text.trim();
    // A well-formed typo passes validation, and the code e-mail would then go
    // to a domain that cannot receive it. Say so once before sending.
    if (suggestEmailFix(email) != null && _typoWarnedFor != email) {
      setState(() {
        _typoWarnedFor = email;
        _error = null;
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
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
    final typoFor = _typoWarnedFor;
    final suggestion = typoFor == null ? null : suggestEmailFix(typoFor);

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
                validator: (v) => emailFieldError(t, v),
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
                validator: (v) => newPasswordFieldError(t, v),
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
              if (suggestion != null) ...[
                const SizedBox(height: AppSpacing.md),
                AuthErrorBanner(
                  message:
                      '${t.authEmailDidYouMean(suggestion)} '
                      '${t.authEmailKeepAsTyped(t.authCreateAccount)}',
                  action: AuthLink(
                    label: suggestion,
                    onTap: () {
                      // Replacing the text retires the warning through the
                      // controller listener; the doctor taps Create account
                      // again to go ahead with the corrected address.
                      _emailCtrl.text = suggestion;
                    },
                  ),
                ),
              ],
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
