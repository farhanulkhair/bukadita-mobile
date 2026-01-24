import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Error Alert widget untuk menampilkan error message
/// Muncul dengan slide animation dari atas
class ErrorAlert extends StatefulWidget {
  final String message;
  final VoidCallback? onDismiss;

  const ErrorAlert({super.key, required this.message, this.onDismiss});

  @override
  State<ErrorAlert> createState() => _ErrorAlertState();
}

class _ErrorAlertState extends State<ErrorAlert>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.red50,
          border: Border.all(color: AppColors.red200, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Warning Icon
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: AppColors.red500,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_rounded,
                size: 12,
                color: AppColors.white,
              ),
            ),
            const SizedBox(width: 12),

            // Error Message
            Expanded(
              child: Text(
                widget.message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.red700,
                  fontSize: 13,
                ),
              ),
            ),

            // Dismiss Button (optional)
            if (widget.onDismiss != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onDismiss,
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.red700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
