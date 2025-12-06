import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum ErrorType {
  network,
  database,
  validation,
  unknown,
}

class AppError {
  final String message;
  final ErrorType type;
  final Object? originalError;

  AppError({
    required this.message,
    required this.type,
    this.originalError,
  });

  static AppError fromException(Object error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || 
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return AppError(
        message: 'Network error. Please check your connection.',
        type: ErrorType.network,
        originalError: error,
      );
    }
    
    if (errorString.contains('database') || 
        errorString.contains('isar') ||
        errorString.contains('sql')) {
      return AppError(
        message: 'Database error. Please try again.',
        type: ErrorType.database,
        originalError: error,
      );
    }
    
    if (errorString.contains('validation') || 
        errorString.contains('invalid')) {
      return AppError(
        message: 'Invalid input. Please check your data.',
        type: ErrorType.validation,
        originalError: error,
      );
    }
    
    return AppError(
      message: 'An unexpected error occurred. Please try again.',
      type: ErrorType.unknown,
      originalError: error,
    );
  }
}

class ErrorHandler {
  static void showError(BuildContext context, Object error, {VoidCallback? onRetry}) {
    final appError = AppError.fromException(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getErrorIcon(appError.type),
              color: AppColors.textPrimary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                appError.message,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onRetry();
                },
                child: const Text(
                  'RETRY',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Future<void> showErrorDialog(
    BuildContext context,
    Object error, {
    VoidCallback? onRetry,
  }) async {
    final appError = AppError.fromException(error);
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Icon(
              _getErrorIcon(appError.type),
              color: AppColors.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Error',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          appError.message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onRetry();
              },
              child: Text(
                'Retry',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off_rounded;
      case ErrorType.database:
        return Icons.storage_rounded;
      case ErrorType.validation:
        return Icons.error_outline_rounded;
      case ErrorType.unknown:
        return Icons.warning_rounded;
    }
  }

  static String getUserFriendlyMessage(Object error) {
    return AppError.fromException(error).message;
  }
}

