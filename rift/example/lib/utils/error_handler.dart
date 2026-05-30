import 'package:flutter/material.dart';

/// App error model
class AppError {
  final String type;
  final String message;
  final String? technicalDetails;
  final bool isRecoverable;
  final VoidCallback? retryAction;

  const AppError({
    required this.type,
    required this.message,
    this.technicalDetails,
    this.isRecoverable = true,
    this.retryAction,
  });

  factory AppError.network({String? details}) {
    return AppError(
      type: 'Network Error',
      message:
          'Unable to connect to the server. Please check your internet connection.',
      technicalDetails: details,
      isRecoverable: true,
    );
  }

  factory AppError.notFound({String? details}) {
    return AppError(
      type: 'Not Found',
      message: 'The requested resource was not found.',
      technicalDetails: details,
      isRecoverable: false,
    );
  }

  factory AppError.permission({String? details}) {
    return AppError(
      type: 'Permission Denied',
      message: 'You don\'t have permission to access this resource.',
      technicalDetails: details,
      isRecoverable: false,
    );
  }

  factory AppError.unknown({String? details}) {
    return AppError(
      type: 'Unknown Error',
      message: 'An unexpected error occurred. Please try again.',
      technicalDetails: details,
      isRecoverable: true,
    );
  }
}

/// Error handler for logging and displaying errors
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  /// Log error for debugging
  void logError(AppError error, {StackTrace? stackTrace}) {
    debugPrint('═══════════════════════════════════════');
    debugPrint('ERROR: ${error.type}');
    debugPrint('Message: ${error.message}');
    if (error.technicalDetails != null) {
      debugPrint('Details: ${error.technicalDetails}');
    }
    if (stackTrace != null) {
      debugPrint('Stack Trace:\n$stackTrace');
    }
    debugPrint('═══════════════════════════════════════');
  }

  /// Show error snackbar
  void showErrorSnackbar(BuildContext context, AppError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    error.type,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    error.message,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFF3B30),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: error.isRecoverable && error.retryAction != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: error.retryAction!,
              )
            : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show error dialog
  void showErrorDialog(BuildContext context, AppError error) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFFF3B30),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error.type,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1E),
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
              error.message,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.5,
              ),
            ),
            if (error.technicalDetails != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withAlpha(13)
                      : Colors.black.withAlpha(6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  error.technicalDetails!,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          if (error.isRecoverable && error.retryAction != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                error.retryAction!();
              },
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Color(0xFF007AFF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Handle error with automatic logging and display
  void handleError(
    BuildContext context,
    AppError error, {
    bool showDialog = false,
    StackTrace? stackTrace,
  }) {
    logError(error, stackTrace: stackTrace);

    if (showDialog) {
      showErrorDialog(context, error);
    } else {
      showErrorSnackbar(context, error);
    }
  }
}
