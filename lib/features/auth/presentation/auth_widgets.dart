import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../auth_validation.dart';

export '../auth_validation.dart'
    show isValidEmail, looksLikeEmail, suggestEmailFix;

/// The e-mail error for a NEW address (sign-up), or null when it is
/// acceptable.
///
/// Only a malformed address gets an error here, with "Did you mean …?"
/// appended when it is also near a common provider (`doctor@gmailcom`). A
/// well-formed typo such as `doctor@gmial.com` passes: blocking it would
/// strand the rare doctor whose address really is like that. The sign-up
/// screen warns about those once instead, before the OTP e-mail is sent to
/// a domain that cannot receive it.
String? emailFieldError(AppLocalizations t, String? value) {
  final text = value ?? '';
  if (isValidEmail(text)) return null;
  final suggestion = suggestEmailFix(text);
  if (suggestion == null) return t.authEmailInvalid;
  return '${t.authEmailInvalid}. ${t.authEmailDidYouMean(suggestion)}';
}

/// The e-mail error for an EXISTING account (log in, forgot password), or
/// null when the field may be submitted.
///
/// Deliberately permissive: the address was accepted when the account was
/// created, so the form must not be the thing that refuses it. Only input
/// that cannot be an e-mail address at all is blocked. A near-miss of a
/// common provider is surfaced after the attempt fails instead — see
/// [emailTypoHint].
String? existingEmailFieldError(AppLocalizations t, String? value) =>
    looksLikeEmail(value ?? '') ? null : t.authEmailInvalid;

/// "Did you mean …?" for an address that failed to sign in, or null.
///
/// Shown next to the error the server returned, where it explains a failure
/// that has already happened rather than blocking the form.
String? emailTypoHint(AppLocalizations t, String email) {
  final suggestion = suggestEmailFix(email);
  return suggestion == null ? null : t.authEmailDidYouMean(suggestion);
}

/// The new-password error for [value], or null when it meets every rule the
/// Supabase project enforces (`lower_upper_letters_digits_symbols`).
///
/// Reports one rule at a time, in [PasswordRule] order, so the doctor is
/// told the next thing to fix instead of the whole list at once. Sign-in does
/// NOT use this: accounts made before the policy may have weaker passwords.
String? newPasswordFieldError(AppLocalizations t, String? value) {
  final issues = passwordIssues(value ?? '');
  if (issues.isEmpty) return null;
  for (final rule in PasswordRule.values) {
    if (!issues.contains(rule)) continue;
    return switch (rule) {
      PasswordRule.minLength => t.authPasswordTooShort,
      PasswordRule.maxLength => t.authPasswordTooLong,
      PasswordRule.lowercase => t.authPasswordNeedsLowercase,
      PasswordRule.uppercase => t.authPasswordNeedsUppercase,
      PasswordRule.digit => t.authPasswordNeedsDigit,
      PasswordRule.symbol => t.authPasswordNeedsSymbol,
    };
  }
  return t.authPasswordRules;
}

/// Localized headline for any auth error. Raw exception text is never shown
/// as the message; [authErrorDetails] exposes it only for unknown errors.
String authErrorMessage(AppLocalizations t, Object error) {
  return switch (authErrorKind(error)) {
    AuthErrorKind.invalidCredentials => t.authErrorInvalidCredentials,
    AuthErrorKind.emailNotConfirmed => t.authErrorEmailNotConfirmed,
    AuthErrorKind.userAlreadyExists => t.authErrorUserExists,
    AuthErrorKind.weakPassword => t.authErrorWeakPassword,
    AuthErrorKind.otpExpired => t.authErrorOtpExpired,
    AuthErrorKind.otpInvalid => t.authErrorOtpInvalid,
    AuthErrorKind.rateLimited => t.authErrorRateLimited,
    AuthErrorKind.emailSendFailed => t.authErrorEmailSendFailed,
    AuthErrorKind.network => t.authErrorNetwork,
    AuthErrorKind.signupDisabled => t.authErrorSignupDisabled,
    AuthErrorKind.validation => t.authErrorValidation,
    AuthErrorKind.notConfigured => t.authErrorNotConfigured,
    AuthErrorKind.unknown => t.authErrorUnknown,
  };
}

/// Developer-readable detail for unknown errors only; null otherwise.
String? authErrorDetails(Object error) {
  if (authErrorKind(error) != AuthErrorKind.unknown) return null;
  final text = error is Failure ? error.message : error.toString();
  return text.trim().isEmpty ? null : text.trim();
}

/// Labelled outlined input matching the intake form fields.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.hint,
    this.helper,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.suffix,
    this.validator,
    this.onSubmitted,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String? hint;
  final String? helper;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final Widget? suffix;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkPrimary : AppColors.primary;

    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: AppSpacing.radiusMd,
      borderSide: BorderSide(color: color, width: 2),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelMedium.copyWith(
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s),
        TextFormField(
          controller: controller,
          enabled: enabled,
          autofocus: autofocus,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          obscureText: obscureText,
          autocorrect: false,
          enableSuggestions: !obscureText,
          validator: validator,
          onFieldSubmitted: onSubmitted,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: AppTypography.bodyMedium.copyWith(color: scheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            helperMaxLines: 2,
            // Flutter clips errorText to one line with an ellipsis unless
            // told otherwise. The e-mail error ends with the suggested
            // address and the translated password rules run long, so the
            // part that got cut off was the part the doctor needed.
            errorMaxLines: 3,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            helperStyle: AppTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14,
            ),
            suffixIcon: suffix,
            enabledBorder: border(scheme.outline),
            disabledBorder: border(scheme.outline),
            focusedBorder: border(accent),
            errorBorder: border(AppColors.error),
            focusedErrorBorder: border(AppColors.error),
            filled: false,
          ),
        ),
      ],
    );
  }
}

/// Eye toggle for password fields.
class PasswordVisibilityToggle extends StatelessWidget {
  const PasswordVisibilityToggle({
    super.key,
    required this.obscured,
    required this.onToggle,
  });

  final bool obscured;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return IconButton(
      tooltip: obscured ? t.authShowPassword : t.authHidePassword,
      onPressed: onToggle,
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Full-width gradient call-to-action, identical to the intake screen's.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null && !loading;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: enabled || loading
                ? const LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: enabled || loading ? null : scheme.surfaceContainerHigh,
            borderRadius: AppSpacing.radiusMd,
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleSmall.copyWith(
                            color: enabled
                                ? Colors.white
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (trailingIcon != null) ...[
                        const SizedBox(width: AppSpacing.s),
                        Icon(
                          trailingIcon,
                          size: 20,
                          color: enabled
                              ? Colors.white
                              : scheme.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Inline error card. [details] (raw exception text) is only passed for
/// unknown errors and stays collapsed behind a "Details" toggle.
class AuthErrorBanner extends StatefulWidget {
  const AuthErrorBanner({
    super.key,
    required this.message,
    this.details,
    this.action,
  });

  final String message;
  final String? details;

  /// Optional recovery action rendered under the message (e.g. "Sign in
  /// instead" when the account already exists).
  final Widget? action;

  @override
  State<AuthErrorBanner> createState() => _AuthErrorBannerState();
}

class _AuthErrorBannerState extends State<AuthErrorBanner> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: AppSpacing.radiusMd,
        border: Border.all(color: scheme.error.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline_rounded, size: 18, color: scheme.error),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Text(
                  widget.message,
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          if (widget.details != null) ...[
            const SizedBox(height: AppSpacing.xs),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.only(left: 26),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.authErrorDetails,
                      style: AppTypography.labelSmall.copyWith(
                        color: scheme.error,
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 16,
                      color: scheme.error,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.only(left: 26, top: AppSpacing.xs),
                child: SelectableText(
                  widget.details!,
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onErrorContainer,
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ),
          ],
          if (widget.action != null) ...[
            const SizedBox(height: AppSpacing.s),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: widget.action,
            ),
          ],
        ],
      ),
    );
  }
}

/// "Question? [Link]" row used under the cards.
class AuthLinkRow extends StatelessWidget {
  const AuthLinkRow({
    super.key,
    required this.question,
    required this.linkLabel,
    required this.onTap,
  });

  final String question;
  final String linkLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.xs,
      children: [
        Text(
          question,
          style: AppTypography.bodyMedium.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        AuthLink(label: linkLabel, onTap: onTap),
      ],
    );
  }
}

/// Inline text link in the brand colour.
class AuthLink extends StatelessWidget {
  const AuthLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.radiusSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          label,
          style: AppTypography.labelLarge.copyWith(color: scheme.primary),
        ),
      ),
    );
  }
}

/// Digits-only formatter for the code input.
final List<TextInputFormatter> kDigitInputFormatters = [
  FilteringTextInputFormatter.digitsOnly,
];
