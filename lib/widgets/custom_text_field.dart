import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/theme.dart';

/// Custom Text Field dengan styling sesuai desain BukaDita
/// Mendukung prefix icon, suffix icon (untuk password toggle), dan error state
class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool isPassword;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputType? keyboardType;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.isPassword = false,
    this.validator,
    this.onChanged,
    this.keyboardType,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isFocused = false;
  bool _obscureText = true;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(widget.label, style: AppTextStyles.label),
        const SizedBox(height: 8),

        // Text Field
        Focus(
          onFocusChange: (hasFocus) {
            setState(() {
              _isFocused = hasFocus;
            });
          },
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: TextFormField(
              controller: widget.controller,
              obscureText: widget.isPassword ? _obscureText : false,
              keyboardType: widget.keyboardType,
              style: AppTextStyles.input,
              onChanged: widget.onChanged,
              validator: widget.validator,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppTextStyles.hint,
                prefixIcon: Icon(
                  widget.prefixIcon,
                  size: 16,
                  color: _isFocused ? AppColors.primary : AppColors.gray400,
                ),
                suffixIcon:
                    widget.isPassword
                        ? GestureDetector(
                          onTap: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                          child: Icon(
                            _obscureText ? LucideIcons.eye : LucideIcons.eyeOff,
                            size: 16,
                            color: AppColors.gray400,
                          ),
                        )
                        : null,
                filled: true,
                fillColor: _isFocused ? AppColors.white : AppColors.gray50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.gray200,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color:
                        _isHovered
                            ? AppColors.primary.withOpacity(0.5)
                            : AppColors.gray200,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.red400,
                    width: 1,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.red400,
                    width: 1,
                  ),
                ),
                errorStyle: AppTextStyles.inputError,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
