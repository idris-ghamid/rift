import 'package:flutter/material.dart';
import '../widgets/custom_buttons.dart';

/// Base empty state widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (iconColor ?? theme.colorScheme.primary).withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: iconColor ?? theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Message
            Text(
              message,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white60 : Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            // Action button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              PrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                icon: Icons.add_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// No search results empty state
class NoSearchResults extends StatelessWidget {
  final String query;
  final VoidCallback? onClear;

  const NoSearchResults({
    super.key,
    required this.query,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off_rounded,
      title: 'No Results Found',
      message:
          'We couldn\'t find any features matching "$query".\nTry different keywords or browse categories.',
      actionLabel: 'Clear Search',
      onAction: onClear,
      iconColor: const Color(0xFF007AFF),
    );
  }
}

/// No favorites empty state
class NoFavorites extends StatelessWidget {
  final VoidCallback? onBrowse;

  const NoFavorites({
    super.key,
    this.onBrowse,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.favorite_border_rounded,
      title: 'No Favorites Yet',
      message:
          'Start adding features to your favorites by tapping the heart icon on any feature card.',
      actionLabel: 'Browse Features',
      onAction: onBrowse,
      iconColor: const Color(0xFFFF3B30),
    );
  }
}

/// No history empty state
class NoHistory extends StatelessWidget {
  final VoidCallback? onBrowse;

  const NoHistory({
    super.key,
    this.onBrowse,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.history_rounded,
      title: 'No History',
      message:
          'Your recently viewed features will appear here once you start exploring.',
      actionLabel: 'Start Exploring',
      onAction: onBrowse,
      iconColor: const Color(0xFF5856D6),
    );
  }
}

/// Demo error empty state
class DemoError extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;

  const DemoError({
    super.key,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.error_outline_rounded,
      title: 'Demo Failed',
      message: errorMessage ??
          'Something went wrong while running the demo.\nPlease try again.',
      actionLabel: 'Retry',
      onAction: onRetry,
      iconColor: const Color(0xFFFF3B30),
    );
  }
}

/// Generic error state
class ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.warning_amber_rounded,
      title: title,
      message: message,
      actionLabel: onRetry != null ? 'Try Again' : null,
      onAction: onRetry,
      iconColor: const Color(0xFFFF9500),
    );
  }
}

/// Loading state with shimmer
class LoadingState extends StatelessWidget {
  final String? message;

  const LoadingState({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Offline indicator banner
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFF9500),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 20,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'You are offline',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              // Dismiss banner
            },
            child: const Icon(
              Icons.close_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
