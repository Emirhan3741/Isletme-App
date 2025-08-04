import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Image optimization yardımcı sınıfı
class ImageOptimization {
  /// Optimized network image widget
  static Widget optimizedNetworkImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ??
            Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        if (kDebugMode) {
          debugPrint('Image load error: $error');
        }
        return errorWidget ?? const Icon(Icons.error, color: Colors.red);
      },
    );
  }

  /// Optimized asset image widget
  static Widget optimizedAssetImage({
    required String assetPath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
    );
  }

  /// Avatar image with optimization
  static Widget optimizedAvatar({
    String? imageUrl,
    required double radius,
    Widget? placeholder,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        child: Icon(Icons.person, size: radius),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(imageUrl),
      onBackgroundImageError: (exception, stackTrace) {
        if (kDebugMode) {
          debugPrint('Avatar image error: $exception');
        }
      },
      child: placeholder,
    );
  }

  /// Lazy loading image grid
  static Widget lazyImageGrid({
    required List<String> imageUrls,
    required int crossAxisCount,
    required double itemHeight,
  }) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisExtent: itemHeight,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return optimizedNetworkImage(
          imageUrl: imageUrls[index],
          height: itemHeight,
          placeholder: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  /// Memory-efficient image cache configuration
  static void configureImageCache() {
    PaintingBinding.instance.imageCache.maximumSize = 100;
    PaintingBinding.instance.imageCache.maximumSizeBytes =
        50 * 1024 * 1024; // 50MB
  }

  /// Clear image cache when memory pressure
  static void clearCacheOnMemoryPressure() {
    PaintingBinding.instance.imageCache.clear();
    if (kDebugMode) {
      debugPrint('🧹 Image cache cleared due to memory pressure');
    }
  }
}
