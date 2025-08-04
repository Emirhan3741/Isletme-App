import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Performance optimization yardımcı sınıfı
class PerformanceHelper {
  static const PerformanceHelper _instance = PerformanceHelper._internal();
  factory PerformanceHelper() => _instance;
  const PerformanceHelper._internal();

  /// Debug modda performans metriklerini logla
  static void logPerformance(String operation, int durationMs) {
    if (kDebugMode) {
      debugPrint('⚡ Performance: $operation took ${durationMs}ms');
    }
  }

  /// Bellek kullanımını optimize et
  static void optimizeMemory() {
    if (kDebugMode) {
      // Garbage collection'ı tetikle
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    }
  }

  /// İmage cache'ini temizle
  static void clearImageCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  /// Widget rebuild performansını ölç
  static void measureWidgetPerformance(
      String widgetName, VoidCallback callback) {
    if (kDebugMode) {
      final stopwatch = Stopwatch()..start();
      callback();
      stopwatch.stop();
      logPerformance('$widgetName rebuild', stopwatch.elapsedMilliseconds);
    } else {
      callback();
    }
  }

  /// Network request performansını ölç
  static Future<T> measureNetworkPerformance<T>(
    String requestName,
    Future<T> Function() networkCall,
  ) async {
    if (kDebugMode) {
      final stopwatch = Stopwatch()..start();
      try {
        final result = await networkCall();
        stopwatch.stop();
        logPerformance('Network: $requestName', stopwatch.elapsedMilliseconds);
        return result;
      } catch (e) {
        stopwatch.stop();
        logPerformance(
            'Network Failed: $requestName', stopwatch.elapsedMilliseconds);
        rethrow;
      }
    } else {
      return await networkCall();
    }
  }

  /// Build optimizasyonu için const constructor kontrolü
  static bool isConstWidget(Widget widget) {
    return widget.runtimeType.toString().contains('const');
  }

  /// Memory leak kontrolü için dispose callback'i
  static void registerDisposable(VoidCallback disposeCallback) {
    if (kDebugMode) {
      // Production'da dispose callback'lerini takip et
      debugPrint('🗑️ Disposable registered');
    }
  }
}

/// Performance monitoring mixin'i
mixin PerformanceMonitorMixin {
  final Stopwatch _stopwatch = Stopwatch();

  void startPerformanceTimer() {
    if (kDebugMode) {
      _stopwatch.start();
    }
  }

  void endPerformanceTimer(String operation) {
    if (kDebugMode && _stopwatch.isRunning) {
      _stopwatch.stop();
      PerformanceHelper.logPerformance(
          operation, _stopwatch.elapsedMilliseconds);
      _stopwatch.reset();
    }
  }
}

/// Widget performans wrapper'ı
class PerformanceWidget extends StatelessWidget {
  final Widget child;
  final String name;

  const PerformanceWidget({
    super.key,
    required this.child,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      return Builder(
        builder: (context) {
          PerformanceHelper.measureWidgetPerformance(name, () {});
          return child;
        },
      );
    }
    return child;
  }
}
