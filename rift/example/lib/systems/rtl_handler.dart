import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

/// RTL handler for bidirectional layout support
class RTLHandler {
  /// Check if current locale is RTL
  static bool isRTL(BuildContext context) {
    return Directionality.of(context) == TextDirection.rtl;
  }

  /// Get text direction for current locale
  static TextDirection getTextDirection(BuildContext context) {
    return Directionality.of(context);
  }

  /// Check if a locale is RTL
  static bool isRTLLocale(Locale locale) {
    final rtlLanguages = ['ar', 'he', 'fa', 'ur'];
    return rtlLanguages.contains(locale.languageCode);
  }

  /// Mirror padding for RTL
  static EdgeInsets mirrorPadding(EdgeInsets padding, bool isRTL) {
    if (!isRTL) return padding;

    return EdgeInsets.only(
      left: padding.right,
      right: padding.left,
      top: padding.top,
      bottom: padding.bottom,
    );
  }

  /// Mirror alignment for RTL
  static Alignment mirrorAlignment(Alignment alignment, bool isRTL) {
    if (!isRTL) return alignment;

    return Alignment(
      -alignment.x,
      alignment.y,
    );
  }

  /// Get directional padding (automatically handles RTL)
  static EdgeInsetsDirectional getDirectionalPadding({
    double start = 0,
    double end = 0,
    double top = 0,
    double bottom = 0,
  }) {
    return EdgeInsetsDirectional.only(
      start: start,
      end: end,
      top: top,
      bottom: bottom,
    );
  }

  /// Get directional alignment (automatically handles RTL)
  static AlignmentDirectional getDirectionalAlignment({
    required double start,
    required double y,
  }) {
    return AlignmentDirectional(start, y);
  }

  /// Flip icon for RTL (for directional icons like arrows)
  static IconData flipIcon(IconData icon, bool isRTL) {
    if (!isRTL) return icon;

    // Map of icons that should be flipped
    final flipMap = {
      Icons.arrow_forward: Icons.arrow_back,
      Icons.arrow_back: Icons.arrow_forward,
      Icons.arrow_forward_ios: Icons.arrow_back_ios,
      Icons.arrow_back_ios: Icons.arrow_forward_ios,
      Icons.chevron_right: Icons.chevron_left,
      Icons.chevron_left: Icons.chevron_right,
      Icons.navigate_next: Icons.navigate_before,
      Icons.navigate_before: Icons.navigate_next,
      Icons.arrow_right: Icons.arrow_back,
      Icons.arrow_left: Icons.arrow_right,
    };

    return flipMap[icon] ?? icon;
  }

  /// Format number according to locale
  static String formatNumber(int number, Locale locale) {
    final formatter = intl.NumberFormat.decimalPattern(locale.toString());
    return formatter.format(number);
  }

  /// Format decimal number according to locale
  static String formatDecimal(double number, Locale locale,
      {int decimals = 2}) {
    final formatter = intl.NumberFormat.decimalPattern(locale.toString());
    return formatter.format(number);
  }

  /// Get appropriate font family for Arabic
  static String? getArabicFontFamily(Locale locale) {
    if (locale.languageCode == 'ar') {
      // Return null to use system default Arabic font
      // Or specify a custom Arabic font if added to assets
      return null;
    }
    return null;
  }

  /// Wrap widget with Directionality based on locale
  static Widget wrapWithDirectionality({
    required Widget child,
    required Locale locale,
  }) {
    final textDirection =
        isRTLLocale(locale) ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: child,
    );
  }

  /// Get text alignment for current direction
  static TextAlign getTextAlign(BuildContext context, {bool start = true}) {
    final isRtl = isRTL(context);

    if (start) {
      return isRtl ? TextAlign.right : TextAlign.left;
    } else {
      return isRtl ? TextAlign.left : TextAlign.right;
    }
  }

  /// Get cross axis alignment for current direction
  static CrossAxisAlignment getCrossAxisAlignment(
    BuildContext context, {
    bool start = true,
  }) {
    final isRtl = isRTL(context);

    if (start) {
      return isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    } else {
      return isRtl ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    }
  }

  /// Get main axis alignment for current direction
  static MainAxisAlignment getMainAxisAlignment(
    BuildContext context, {
    bool start = true,
  }) {
    final isRtl = isRTL(context);

    if (start) {
      return isRtl ? MainAxisAlignment.end : MainAxisAlignment.start;
    } else {
      return isRtl ? MainAxisAlignment.start : MainAxisAlignment.end;
    }
  }

  /// Reverse list for RTL
  static List<T> reverseForRTL<T>(List<T> list, bool isRTL) {
    if (!isRTL) return list;
    return list.reversed.toList();
  }

  /// Get border radius for RTL
  static BorderRadius getBorderRadius({
    required bool isRTL,
    double topStart = 0,
    double topEnd = 0,
    double bottomStart = 0,
    double bottomEnd = 0,
  }) {
    if (!isRTL) {
      return BorderRadius.only(
        topLeft: Radius.circular(topStart),
        topRight: Radius.circular(topEnd),
        bottomLeft: Radius.circular(bottomStart),
        bottomRight: Radius.circular(bottomEnd),
      );
    } else {
      return BorderRadius.only(
        topLeft: Radius.circular(topEnd),
        topRight: Radius.circular(topStart),
        bottomLeft: Radius.circular(bottomEnd),
        bottomRight: Radius.circular(bottomStart),
      );
    }
  }
}
