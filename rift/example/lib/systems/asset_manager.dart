import 'package:flutter/material.dart';

/// Asset manager for loading, caching, and displaying images
class AssetManager {
  // Singleton pattern
  static final AssetManager _instance = AssetManager._internal();
  factory AssetManager() => _instance;
  AssetManager._internal();

  // Image cache
  final Map<String, ImageProvider> _imageCache = {};

  // Asset paths
  static const String profileImagePath = 'assets/idris.jpg';
  static const String companyLogoPath = 'assets/idrisium corp.jpg';

  /// Load image from assets with caching
  Future<ImageProvider> loadImage(String path) async {
    // Check cache first
    if (_imageCache.containsKey(path)) {
      return _imageCache[path]!;
    }

    // Load from assets
    final imageProvider = AssetImage(path);

    // Cache the image
    _imageCache[path] = imageProvider;

    return imageProvider;
  }

  /// Load profile image
  Future<ImageProvider> loadProfileImage() async {
    return loadImage(profileImagePath);
  }

  /// Load company logo
  Future<ImageProvider> loadCompanyLogo() async {
    return loadImage(companyLogoPath);
  }

  /// Cache an image
  void cacheImage(String path, ImageProvider image) {
    _imageCache[path] = image;
  }

  /// Get cached image if available
  ImageProvider? getCachedImage(String path) {
    return _imageCache[path];
  }

  /// Clear all cached images
  void clearCache() {
    _imageCache.clear();
  }

  /// Build shimmer placeholder for loading states
  Widget buildShimmerPlaceholder({
    double width = 100,
    double height = 100,
    double borderRadius = 12,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE0E0E0),
            Color(0xFFF5F5F5),
            Color(0xFFE0E0E0),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
        ),
      ),
    );
  }

  /// Build error placeholder for failed image loads
  Widget buildErrorPlaceholder({
    double width = 100,
    double height = 100,
    double borderRadius = 12,
    Color backgroundColor = const Color(0xFFF2F2F7),
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Center(
        child: Icon(
          Icons.broken_image_rounded,
          size: 40,
          color: Color(0xFF8E8E93),
        ),
      ),
    );
  }

  /// Build rounded image with specified radius
  Widget buildRoundedImage(
    ImageProvider image, {
    required double width,
    required double height,
    double borderRadius = 12,
    BoxFit fit = BoxFit.cover,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image(
        image: image,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return buildErrorPlaceholder(
            width: width,
            height: height,
            borderRadius: borderRadius,
          );
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) {
            return child;
          }
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: child,
          );
        },
      ),
    );
  }

  /// Build circular image
  Widget buildCircularImage(
    ImageProvider image, {
    required double size,
    BoxFit fit = BoxFit.cover,
  }) {
    return ClipOval(
      child: Image(
        image: image,
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: Color(0xFFF2F2F7),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.person_rounded,
                size: 40,
                color: Color(0xFF8E8E93),
              ),
            ),
          );
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) {
            return child;
          }
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: child,
          );
        },
      ),
    );
  }

  /// Build image with loading and error states
  Widget buildManagedImage({
    required String path,
    required double width,
    required double height,
    double borderRadius = 12,
    bool circular = false,
    BoxFit fit = BoxFit.cover,
  }) {
    return FutureBuilder<ImageProvider>(
      future: loadImage(path),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return buildShimmerPlaceholder(
            width: width,
            height: height,
            borderRadius: circular ? width / 2 : borderRadius,
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return buildErrorPlaceholder(
            width: width,
            height: height,
            borderRadius: circular ? width / 2 : borderRadius,
          );
        }

        if (circular) {
          return buildCircularImage(
            snapshot.data!,
            size: width,
            fit: fit,
          );
        } else {
          return buildRoundedImage(
            snapshot.data!,
            width: width,
            height: height,
            borderRadius: borderRadius,
            fit: fit,
          );
        }
      },
    );
  }
}
