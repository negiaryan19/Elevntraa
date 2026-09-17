import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../auth_redirect.dart';
import 'auth_scaffold.dart';
import 'auth_widgets.dart';

/// Why the doctor is entering an e-mail code.
enum VerifyPurpose {
  /// Confirming a brand-new account; success signs the doctor in.
  signup,

  /// Proving ownership before a password reset; success opens
  /// `/reset-password`.
  recovery;

  static VerifyPurpose parse(String? raw) => raw == VerifyPurpose.recovery.name
      ? VerifyPurpose.recovery
      : VerifyPurpose.signup;
}

/// Builds `/verify?email=…&purpose=…` for `context.push` / `context.go`.
String verifyLocation({required String email, required VerifyPurpose purpose}) {
  return Uri(
    path: kVerifyPath,
    queryParameters: {'email': email.trim(), 'purpose': purpose.name},
  ).toString();
}

/// Enter the 8-digit code Supabase e-mailed (`{{ .Token }}`; the project's
/// templates carry no links, so this is the only confirmation path).
class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({
    super.key,
    required this.email,
    required this.purpose,
  });

  final String email;
  final VerifyPurpose purpose;

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  static const int _codeLength = 8;
  static const int _cooldownSeconds = 60;

  final _codeCtrl = TextEditingController();
  final _focus = FocusNode();

  bool _busy = false;
  bool _resending = false;
  Object? _error;
  String? _localMessage;
  int _secondsLeft = _cooldownSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // A code was just sent by the previous screen: start the cooldown now.
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _restartCooldown() {
    setState(() => _secondsLeft = _cooldownSeconds);
    _startTimer();
  }

  Future<void> _verify() async {
    if (_busy) return;
    final t = AppLocalizations.of(context)!;
    final code = _codeCtrl.text.trim();
    if (code.length != _codeLength) {
      setState(() {
        _localMessage = t.authCodeIncomplete;
        _error = null;
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _localMessage = null;
    });
    final auth = ref.read(authControllerProvider);
    try {
      switch (widget.purpose) {
        case VerifyPurpose.signup:
          await auth.verifySignUp(email: widget.email, token: code);
          // A session now exists; the router redirects to splash/onboarding.
          return;
        case VerifyPurpose.recovery:
          await auth.verifyRecovery(email: widget.email, token: code);
          if (mounted) context.go(kResetPasswordPath);
          return;
      }
    } catch (e) {
      if (!mounted) return;
      final kind = authErrorKind(e);
      setState(() {
        _error = e;
        _busy = false;
      });
      if (kind == AuthErrorKind.otpInvalid ||
          kind == AuthErrorKind.otpExpired) {
        _codeCtrl.clear();
        _focus.requestFocus();
      }
    }
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0 || _resending || _busy) return;
    final t = AppLocalizations.of(context)!;
    setState(() {
      _resending = true;
      _error = null;
      _localMessage = null;
    });
    final auth = ref.read(authControllerProvider);
    try {
      switch (widget.purpose) {
        case VerifyPurpose.signup:
          await auth.resendSignUpCode(widget.email);
        case VerifyPurpose.recovery:
          await auth.requestPasswordReset(widget.email);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.authCodeSent)));
      _restartCooldown();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final hasEmail = widget.email.trim().isNotEmpty;

    return AuthScaffold(
      title: t.authVerifyTitle,
      subtitle: hasEmail ? t.authVerifyBody(widget.email) : t.authVerifyTitle,
      icon: Icons.mark_email_read_outlined,
      showBack: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!hasEmail) ...[
            AuthErrorBanner(message: t.authErrorValidation),
            const SizedBox(height: AppSpacing.md),
            AuthPrimaryButton(
              label: t.authBackToSignIn,
              onTap: () => context.go(kLoginPath),
            ),
          ] else ...[
            Text(
              t.authCode,
              style: AppTypography.labelMedium.copyWith(
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            _CodeInput(
              controller: _codeCtrl,
              focusNode: _focus,
              length: _codeLength,
              enabled: !_busy,
              onCompleted: _verify,
            ),
            if (_error != null || _localMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              AuthErrorBanner(
                message: _localMessage ?? authErrorMessage(t, _error!),
                details: _error == null ? null : authErrorDetails(_error!),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AuthPrimaryButton(
              label: t.authVerify,
              loading: _busy,
              trailingIcon: Icons.arrow_forward_rounded,
              onTap: _verify,
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: _secondsLeft > 0
                  ? Text(
                      t.authResendIn(_secondsLeft),
                      style: AppTypography.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    )
                  : _resending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : AuthLink(label: t.authResendCode, onTap: _resend),
            ),
          ],
        ],
      ),
    );
  }
}

/// Eight big digit boxes backed by one invisible text field, so the system
/// keyboard, paste and one-time-code autofill all work as on any text input.
class _CodeInput extends StatelessWidget {
  const _CodeInput({
    required this.controller,
    required this.focusNode,
    required this.length,
    required this.enabled,
    required this.onCompleted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final bool enabled;
  final VoidCallback onCompleted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkPrimary : AppColors.primary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? focusNode.requestFocus : null,
      child: SizedBox(
        height: 56,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([controller, focusNode]),
                builder: (context, _) {
                  final text = controller.text;
                  final activeIndex = text.length.clamp(0, length - 1);
                  return Row(
                    children: [
                      for (var i = 0; i < length; i++) ...[
                        if (i > 0) const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: _DigitBox(
                            char: i < text.length ? text[i] : '',
                            active:
                                focusNode.hasFocus &&
                                i == activeIndex &&
                                text.length < length,
                            accent: accent,
                            scheme: scheme,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            // Invisible real input: receives taps, keyboard, paste, autofill.
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    ...kDigitInputFormatters,
                    LengthLimitingTextInputFormatter(length),
                  ],
                  showCursor: false,
                  enableInteractiveSelection: true,
                  style: const TextStyle(color: Colors.transparent),
                  cursorColor: Colors.transparent,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  onChanged: (value) {
                    if (value.length == length) onCompleted();
                  },
                  onSubmitted: (_) => onCompleted(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DigitBox extends StatelessWidget {
  const _DigitBox({
    required this.char,
    required this.active,
    required this.accent,
    required this.scheme,
  });

  final String char;
  final bool active;
  final Color accent;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active
            ? accent.withValues(alpha: 0.08)
            : scheme.surfaceContainerLow,
        borderRadius: AppSpacing.radiusMd,
        border: Border.all(
          color: active
              ? accent
              : char.isEmpty
              ? scheme.outline
              : scheme.outlineVariant,
          width: 2,
        ),
      ),
      child: Text(
        char,
        style: AppTypography.headlineMedium.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
