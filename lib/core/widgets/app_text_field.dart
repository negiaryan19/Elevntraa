import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Themed text input. Adds a visible above-field label (instead of M3's
/// floating label) because doctors filling forms quickly need scan-able
/// labels, not labels that vanish on focus.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.initialValue,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.autofocus = false,
    this.prefixIcon,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.inputFormatters,
    this.helper,
    this.errorText,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? initialValue;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool enabled;
  final bool autofocus;
  final IconData? prefixIcon;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final String? helper;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.gapS,
        ],
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          maxLength: maxLength,
          enabled: enabled,
          autofocus: autofocus,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          inputFormatters: inputFormatters,
          style: textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
            suffixIcon: suffix,
            errorText: errorText,
            helperText: helper,
            helperMaxLines: 2,
            counterText: '',
          ),
        ),
      ],
    );
  }
}
