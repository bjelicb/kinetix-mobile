import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum ErrorType {
  network,
  timeout,
  server,
  authentication,
  validation,
  database,
  offline,
  unknown,
}

class AppError {
  final String message;
  final String? detailedMessage; // Detaljnije objašnjenje zašto se desio error
  final ErrorType type;
  final Object? originalError;
  final int? statusCode; // HTTP status code ako postoji

  AppError({
    required this.message,
    this.detailedMessage,
    required this.type,
    this.originalError,
    this.statusCode,
  });

  static AppError fromException(Object error) {
    // Handle DioException (network errors, API errors)
    if (error is DioException) {
      return _fromDioException(error);
    }

    // Handle String messages directly (wrap in Exception for consistent handling)
    if (error is String) {
      return AppError(
        message: error,
        detailedMessage: error,
        type: ErrorType.unknown,
        originalError: error,
      );
    }

    // Handle timeout exceptions
    if (error.toString().contains('timeout') || 
        error.toString().contains('Request timeout')) {
      return AppError(
        message: 'Request timeout',
        detailedMessage: 'The request took too long to complete. Please check your internet connection and try again.',
        type: ErrorType.timeout,
        originalError: error,
      );
    }

    // Handle network errors
    if (error.toString().toLowerCase().contains('network') || 
        error.toString().toLowerCase().contains('connection') ||
        error.toString().toLowerCase().contains('socket')) {
      return AppError(
        message: 'Network connection error',
        detailedMessage: 'Unable to connect to the server. Please check your internet connection and try again.',
        type: ErrorType.network,
        originalError: error,
      );
    }
    
    // Handle database errors
    if (error.toString().toLowerCase().contains('database') || 
        error.toString().toLowerCase().contains('isar') ||
        error.toString().toLowerCase().contains('sql')) {
      return AppError(
        message: 'Database error',
        detailedMessage: 'An error occurred while saving data locally. Please try again or restart the app.',
        type: ErrorType.database,
        originalError: error,
      );
    }
    
    // Handle validation errors
    if (error.toString().toLowerCase().contains('validation') || 
        error.toString().toLowerCase().contains('invalid') ||
        error.toString().toLowerCase().contains('missing') ||
        error.toString().toLowerCase().contains('required')) {
      return AppError(
        message: 'Invalid data',
        detailedMessage: error.toString(),
        type: ErrorType.validation,
        originalError: error,
      );
    }
    
    // Unknown error
    return AppError(
      message: 'An unexpected error occurred',
      detailedMessage: 'Something went wrong. Please try again. If the problem persists, contact support.',
      type: ErrorType.unknown,
      originalError: error,
    );
  }

  static AppError _fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return AppError(
          message: 'Connection timeout',
          detailedMessage: 'The server took too long to respond. Please check your internet connection and try again.',
          type: ErrorType.timeout,
          originalError: error,
        );

      case DioExceptionType.sendTimeout:
        return AppError(
          message: 'Send timeout',
          detailedMessage: 'The request took too long to send. Please check your internet connection and try again.',
          type: ErrorType.timeout,
          originalError: error,
        );

      case DioExceptionType.receiveTimeout:
        return AppError(
          message: 'Receive timeout',
          detailedMessage: 'The server took too long to respond. Please check your internet connection and try again.',
          type: ErrorType.timeout,
          originalError: error,
        );

      case DioExceptionType.connectionError:
        return AppError(
          message: 'No internet connection',
          detailedMessage: 'Unable to connect to the server. Please check your internet connection and try again.',
          type: ErrorType.network,
          originalError: error,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          return AppError(
            message: 'Authentication error',
            detailedMessage: statusCode == 401
                ? 'Your session has expired. Please log in again.'
                : 'You don\'t have permission to perform this action. Please contact your trainer.',
            type: ErrorType.authentication,
            originalError: error,
            statusCode: statusCode,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return AppError(
            message: 'Server error',
            detailedMessage: 'The server encountered an error. Please try again later. If the problem persists, contact support.',
            type: ErrorType.server,
            originalError: error,
            statusCode: statusCode,
          );
        } else if (statusCode == 400 || statusCode == 422) {
          // Extract validation error message from response if available
          final errorMessage = error.response?.data?['message']?.toString() ?? 
                              error.response?.data?['error']?.toString() ??
                              'Invalid data provided. Please check your input.';
          return AppError(
            message: 'Invalid request',
            detailedMessage: errorMessage,
            type: ErrorType.validation,
            originalError: error,
            statusCode: statusCode,
          );
        } else {
          return AppError(
            message: 'Server error',
            detailedMessage: 'The server returned an error (${statusCode ?? 'unknown'}). Please try again.',
            type: ErrorType.server,
            originalError: error,
            statusCode: statusCode,
          );
        }

      case DioExceptionType.cancel:
        return AppError(
          message: 'Request cancelled',
          detailedMessage: 'The request was cancelled. Please try again.',
          type: ErrorType.unknown,
          originalError: error,
        );

      case DioExceptionType.unknown:
      default:
        // Check if it's a network error by examining the error message
        if (error.message?.toLowerCase().contains('network') == true ||
            error.message?.toLowerCase().contains('connection') == true) {
          return AppError(
            message: 'Network error',
            detailedMessage: 'Unable to connect to the server. Please check your internet connection and try again.',
            type: ErrorType.network,
            originalError: error,
          );
        }
        return AppError(
          message: 'Network error',
          detailedMessage: 'An unexpected network error occurred. Please check your internet connection and try again.',
          type: ErrorType.network,
          originalError: error,
        );
    }
  }
}

class ErrorHandler {
  /// Show error as SnackBar (for non-critical errors)
  static void showError(
    BuildContext context,
    Object error, {
    VoidCallback? onRetry,
    Duration? duration,
  }) {
    if (!context.mounted) return;
    
    final appError = AppError.fromException(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getErrorIcon(appError.type),
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    appError.message,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (appError.detailedMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                appError.detailedMessage!,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        backgroundColor: _getErrorColor(appError.type),
        duration: duration ?? const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: onRetry != null
            ? SnackBarAction(
                label: 'RETRY',
                textColor: AppColors.textPrimary,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onRetry();
                },
              )
            : null,
      ),
    );
  }

  /// Show error as Dialog (for critical errors that need user attention)
  static Future<void> showErrorDialog(
    BuildContext context,
    Object error, {
    VoidCallback? onRetry,
    String? customTitle,
  }) async {
    if (!context.mounted) return;
    
    final appError = AppError.fromException(error);
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Icon(
              _getErrorIcon(appError.type),
              color: _getErrorColor(appError.type),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                customTitle ?? 'Error',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appError.message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (appError.detailedMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                appError.detailedMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (appError.statusCode != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error code: ${appError.statusCode}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
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
                  fontWeight: FontWeight.bold,
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
      case ErrorType.offline:
        return Icons.wifi_off_rounded;
      case ErrorType.timeout:
        return Icons.timer_off_rounded;
      case ErrorType.server:
        return Icons.cloud_off_rounded;
      case ErrorType.authentication:
        return Icons.lock_outline_rounded;
      case ErrorType.database:
        return Icons.storage_rounded;
      case ErrorType.validation:
        return Icons.error_outline_rounded;
      case ErrorType.unknown:
        return Icons.warning_rounded;
    }
  }

  static Color _getErrorColor(ErrorType type) {
    switch (type) {
      case ErrorType.network:
      case ErrorType.offline:
      case ErrorType.timeout:
        return AppColors.warning;
      case ErrorType.server:
      case ErrorType.authentication:
      case ErrorType.validation:
      case ErrorType.database:
      case ErrorType.unknown:
        return AppColors.error;
    }
  }

  /// Get user-friendly error message (without detailed explanation)
  static String getUserFriendlyMessage(Object error) {
    return AppError.fromException(error).message;
  }

  /// Get detailed error message (with explanation)
  static String getDetailedErrorMessage(Object error) {
    final appError = AppError.fromException(error);
    if (appError.detailedMessage != null) {
      return '${appError.message}\n\n${appError.detailedMessage}';
    }
    return appError.message;
  }
}

