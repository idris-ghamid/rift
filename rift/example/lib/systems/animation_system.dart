import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Animation system for consistent transitions and animations
class AnimationSystem {
  // Standard durations
  static const Duration fastDuration = Duration(milliseconds: 200);
  static const Duration normalDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 400);

  // Standard curves
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve entranceCurve = Curves.easeOut;
  static const Curve exitCurve = Curves.easeIn;
  static const Curve bounceCurve = Curves.elasticOut;

  // Reduce motion flag (from system accessibility settings)
  static bool _reduceMotion = false;

  /// Get transition duration
  static Duration getTransitionDuration(
      {bool fast = false, bool slow = false}) {
    if (_reduceMotion) return Duration.zero;
    if (fast) return fastDuration;
    if (slow) return slowDuration;
    return normalDuration;
  }

  /// Get transition curve
  static Curve getTransitionCurve({bool entrance = false, bool exit = false}) {
    if (_reduceMotion) return Curves.linear;
    if (entrance) return entranceCurve;
    if (exit) return exitCurve;
    return defaultCurve;
  }

  /// Set reduce motion preference
  static void setReduceMotion(bool reduce) {
    _reduceMotion = reduce;
  }

  /// Check if should reduce motion
  static bool shouldReduceMotion() {
    return _reduceMotion;
  }

  /// Create slide transition page route
  static PageRoute<T> createSlideTransition<T>({
    required Widget page,
    SlideDirection direction = SlideDirection.fromRight,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: getTransitionDuration(),
      reverseTransitionDuration: getTransitionDuration(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (_reduceMotion) return child;

        Offset begin;
        switch (direction) {
          case SlideDirection.fromRight:
            begin = const Offset(1.0, 0.0);
            break;
          case SlideDirection.fromLeft:
            begin = const Offset(-1.0, 0.0);
            break;
          case SlideDirection.fromTop:
            begin = const Offset(0.0, -1.0);
            break;
          case SlideDirection.fromBottom:
            begin = const Offset(0.0, 1.0);
            break;
        }

        final tween = Tween(begin: begin, end: Offset.zero)
            .chain(CurveTween(curve: entranceCurve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// Create fade transition page route
  static PageRoute<T> createFadeTransition<T>({
    required Widget page,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: getTransitionDuration(),
      reverseTransitionDuration: getTransitionDuration(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (_reduceMotion) return child;

        return FadeTransition(
          opacity: animation.drive(CurveTween(curve: defaultCurve)),
          child: child,
        );
      },
    );
  }

  /// Create scale transition page route
  static PageRoute<T> createScaleTransition<T>({
    required Widget page,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: getTransitionDuration(),
      reverseTransitionDuration: getTransitionDuration(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (_reduceMotion) return child;

        return ScaleTransition(
          scale: animation.drive(
            Tween(begin: 0.8, end: 1.0).chain(CurveTween(curve: entranceCurve)),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  /// Animate card expansion
  static Widget animateCardExpansion({
    required Widget child,
    required bool expanded,
    Duration? duration,
  }) {
    return AnimatedContainer(
      duration: duration ?? getTransitionDuration(),
      curve: defaultCurve,
      child: AnimatedSize(
        duration: duration ?? getTransitionDuration(),
        curve: defaultCurve,
        child: child,
      ),
    );
  }

  /// Animate fade in with delay
  static Widget animateFadeIn({
    required Widget child,
    Duration? delay,
    Duration? duration,
  }) {
    if (_reduceMotion) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration ?? getTransitionDuration(),
      curve: entranceCurve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Animate slide in
  static Widget animateSlideIn({
    required Widget child,
    required Offset offset,
    Duration? delay,
    Duration? duration,
  }) {
    if (_reduceMotion) return child;

    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: offset, end: Offset.zero),
      duration: duration ?? getTransitionDuration(),
      curve: entranceCurve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Animate scale
  static Widget animateScale({
    required Widget child,
    required bool visible,
    Duration? duration,
  }) {
    if (_reduceMotion) {
      return visible ? child : const SizedBox.shrink();
    }

    return AnimatedScale(
      scale: visible ? 1.0 : 0.0,
      duration: duration ?? getTransitionDuration(),
      curve: defaultCurve,
      child: child,
    );
  }

  /// Provide haptic feedback
  static void hapticFeedback(
      {HapticFeedbackType type = HapticFeedbackType.light}) {
    if (_reduceMotion) return;

    switch (type) {
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selection:
        HapticFeedback.selectionClick();
        break;
    }
  }

  /// Staggered animation builder
  static Widget buildStaggeredList({
    required List<Widget> children,
    Duration? staggerDelay,
    Duration? itemDuration,
  }) {
    if (_reduceMotion) {
      return Column(children: children);
    }

    final staggerDelayValue = staggerDelay ?? const Duration(milliseconds: 50);
    final duration = itemDuration ?? getTransitionDuration();

    return Column(
      children: List.generate(
        children.length,
        (index) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: duration + (staggerDelayValue * index),
          curve: entranceCurve,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: children[index],
        ),
      ),
    );
  }

  /// Animated list item builder
  static Widget buildAnimatedListItem({
    required Widget child,
    required Animation<double> animation,
  }) {
    if (_reduceMotion) return child;

    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  /// Shimmer loading animation
  static Widget buildShimmer({
    required Widget child,
    bool enabled = true,
  }) {
    if (!enabled || _reduceMotion) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -1.0, end: 2.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.linear,
      builder: (context, value, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Colors.transparent,
                Colors.white24,
                Colors.transparent,
              ],
              stops: [
                (value - 0.3).clamp(0.0, 1.0),
                value.clamp(0.0, 1.0),
                (value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      onEnd: () {
        // Loop animation
      },
      child: child,
    );
  }
}

/// Slide direction enum
enum SlideDirection {
  fromRight,
  fromLeft,
  fromTop,
  fromBottom,
}

/// Haptic feedback type enum
enum HapticFeedbackType {
  light,
  medium,
  heavy,
  selection,
}
