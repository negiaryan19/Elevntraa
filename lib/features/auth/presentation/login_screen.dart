import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../auth_redirect.dart';
import 'auth_scaffold.dart';
import 'auth_widgets.dart';
import 'verify_otp_screen.dart';

/// Email + password sign-in (roadmap item 1). When the build carries no
/// backend configuration the form is replaced by an explanation card so the
/// app still boots instead of crashing on `Supabase.instance`.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;
  bool _busy = false;
  Object? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
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
    final auth = ref.read(authControllerProvider);
    final email = _emailCtrl.text.trim();
    try {
      await auth.signIn(email: email, password: _passwordCtrl.text);
      // Success: the auth stream fires and the router redirects. Keep the
      // button in its loading state until this screen is replaced.
    } catch (e) {
      if (!mounted) return;
      if (authErrorKind(e) == AuthErrorKind.emailNotConfirmed) {
        // The account exists but was never verified: send a fresh code and
        // take the doctor straight to the code screen.
        try {
          await auth.resendSignUpCode(email);
        } catch (_) {
          // Rate-limited or offline: the code screen offers "Resend" again.
        }
        if (!mounted) return;
        setState(() => _busy = false);
        context.push(
          verifyLocation(email: email, purpose: VerifyPurpose.signup),
        );
        return;
      }
      setState(() {
        _error = e;
        _busy = false;
      });
    }
  }

  /// The failure to show, plus "Did you mean …?" when the address that was
  /// rejected looks like a typo of a common provider. A mistyped domain is
  /// the usual reason a doctor's own e-mail is "not recognised", and saying
  /// so here costs nothing — unlike blocking the form, which would strand
  /// anyone whose real address our rules happen to dislike.
  String _errorMessage(AppLocalizations t) {
    final message = authErrorMessage(t, _error!);
    if (authErrorKind(_error!) != AuthErrorKind.invalidCredentials) {
      return message;
    }
    final hint = emailTypoHint(t, _emailCtrl.text);
    return hint == null ? message : '$message $hint';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (!AppConfig.hasBackend) {
      return AuthScaffold(
        title: t.authSignInTitle,
        subtitle: t.authSignInSubtitle,
        icon: Icons.cloud_off_rounded,
        child: const _NotConfiguredCard(),
      );
    }

    return AuthScaffold(
      title: t.authSignInTitle,
      subtitle: t.authSignInSubtitle,
      icon: Icons.lock_outline_rounded,
      footer: AuthLinkRow(
        question: t.authNoAccount,
        linkLabel: t.authCreateAccount,
        onTap: () => context.push(kSignupPath),
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
                validator: (v) => existingEmailFieldError(t, v),
              ),
              const SizedBox(height: AppSpacing.md),
              AuthTextField(
                label: t.authPassword,
                icon: Icons.lock_outline_rounded,
                controller: _passwordCtrl,
                hint: t.authPasswordHint,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                enabled: !_busy,
                suffix: PasswordVisibilityToggle(
                  obscured: _obscure,
                  onToggle: () => setState(() => _obscure = !_obscure),
                ),
                validator: (v) =>
                    (v ?? '').isEmpty ? t.authPasswordRequired : null,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.s),
              Align(
                alignment: Alignment.centerRight,
                child: AuthLink(
                  label: t.authForgotPassword,
                  onTap: () => context.push(kForgotPath),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                AuthErrorBanner(
                  message: _errorMessage(t),
                  details: authErrorDetails(_error!),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AuthPrimaryButton(
                label: t.authSignIn,
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

class _NotConfiguredCard extends StatelessWidget {
  const _NotConfiguredCard();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.cloud_off_rounded,
            size: 30,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          t.authNotConfiguredTitle,
          textAlign: TextAlign.center,
          style: AppTypography.titleMedium.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          t.authNotConfiguredBody,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
