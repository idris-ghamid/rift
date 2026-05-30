import 'package:flutter/material.dart';
import '../home_page.dart';

/// Category badge widget
///
/// Displays a category name with category color in a rounded rectangle shape.
/// Supports both light and dark themes with automatic color adaptation.
class CategoryBadge extends StatelessWidget {
  final FeatureCategory category;
  final double fontSize;
  final double iconSize;
  final EdgeInsets padding;
  final bool showIcon;

  const CategoryBadge({
    super.key,
    required this.category,
    this.fontSize = 12,
    this.iconSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = category.color;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: catColor.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: catColor.withAlpha(51),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              category.icon,
              size: iconSize,
              color: catColor,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            category.label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: catColor,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact category badge (icon only)
class CategoryBadgeCompact extends StatelessWidget {
  final FeatureCategory category;
  final double size;

  const CategoryBadgeCompact({
    super.key,
    required this.category,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = category.color;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: catColor.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: catColor.withAlpha(51),
          width: 1,
        ),
      ),
      child: Icon(
        category.icon,
        size: size * 0.5,
        color: catColor,
      ),
    );
  }
}
