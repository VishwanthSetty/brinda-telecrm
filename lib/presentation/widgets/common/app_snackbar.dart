import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AppSnackbar {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError ? AppColors.error : AppColors.success,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          duration: duration,
          backgroundColor: AppColors.onBackground,
        ),
      );
  }

  static void showError(BuildContext context, String message) =>
      show(context, message, isError: true);

  static void showSuccess(BuildContext context, String message) =>
      show(context, message);
}
