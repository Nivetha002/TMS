import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Reusable text field: label on top + icon + optional show/hide password.
/// Any form in the app (login, add user, etc.) can use this later.
class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool isPassword;
  final bool enabled;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.isPassword = false,
    this.enabled = true,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onSubmitted,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  // Only this widget cares about show/hide, so local state is correct here.
  bool _obscure = true;

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          obscureText: widget.isPassword && _obscure,
          autocorrect: false,
          enableSuggestions: !widget.isPassword,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          onFieldSubmitted: widget.onSubmitted,
          style: const TextStyle(fontSize: 15, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(color: AppColors.textLight),
            filled: true,
            fillColor: AppColors.fieldBackground,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            prefixIcon: Icon(widget.prefixIcon, color: AppColors.textLight),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textLight,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
            border: _border(AppColors.border),
            enabledBorder: _border(AppColors.border),
            disabledBorder: _border(AppColors.border),
            focusedBorder: _border(AppColors.primary, width: 1.5),
            errorBorder: _border(AppColors.errorText),
            focusedErrorBorder: _border(AppColors.errorText, width: 1.5),
          ),
        ),
      ],
    );
  }
}