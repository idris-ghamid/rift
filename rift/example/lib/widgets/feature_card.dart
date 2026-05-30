import 'package:flutter/material.dart';
import '../home_page.dart';
import '../systems/layout_engine.dart';
import '../systems/animation_system.dart';

/// Feature card widget with Material Design 3 styling
///
/// Displays a feature with:
/// - Category icon with colored background
/// - Feature name (bold, 16-18px)
/// - Feature description (2 lines, 13-14px)
/// - Category badge in bottom right
/// - Tap gesture for navigation
/// - Responsive sizing based on screen width
class FeatureCard extends StatefulWidget {
  final FeatureInfo feature;
  final VoidCallback? onTap;
  final bool showCategoryBadge;

  const FeatureCard({
    super.key,
    required this.feature,
    this.onTap,
    this.showCategoryBadge = true,
  });

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: AnimationSystem.fastDuration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: AnimationSystem.entranceCurve,
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final layoutType = LayoutEngine.getLayoutType(width);
    final cardHeight = LayoutEngine.getCardHeight(width);
    final catColor = widget.feature.category.color;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: cardHeight,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withAlpha(51)
                    : Colors.black.withAlpha(13),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon and category badge row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category icon with colored background
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: catColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.feature.icon,
                        size: 24,
                        color: catColor,
                      ),
                    ),
                    // Category badge (optional)
                    if (widget.showCategoryBadge)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: catColor.withAlpha(26),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.feature.category.icon,
                              size: 10,
                              color: catColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.feature.category.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: catColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                // Feature name
                Text(
                  widget.feature.name,
                  style: TextStyle(
                    fontSize: layoutType == LayoutType.mobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Feature description
                Text(
                  widget.feature.description,
                  style: TextStyle(
                    fontSize: layoutType == LayoutType.mobile ? 13 : 14,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
