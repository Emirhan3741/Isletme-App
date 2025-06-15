import 'dart:developer' as developer;

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class Logger {
  static const bool _enableLogging = false; // Production'da false olacak
  static const String _appName = 'RandevuERP';

  static void debug(String message, {String? context}) {
    _log(LogLevel.debug, message, context: context);
  }

  static void info(String message, {String? context}) {
    _log(LogLevel.info, message, context: context);
  }

  static void warning(String message, {String? context}) {
    _log(LogLevel.warning, message, context: context);
  }

  static void error(String message, {String? context, dynamic error}) {
    _log(LogLevel.error, message, context: context, error: error);
  }

  static void _log(
    LogLevel level,
    String message, {
    String? context,
    dynamic error,
  }) {
    if (!_enableLogging) return;

    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? '[$context] ' : '';
    final levelStr = level.name.toUpperCase();
    
    final logMessage = '[$timestamp] [$_appName] [$levelStr] $contextStr$message';
    
    if (error != null) {
      developer.log(
        '$logMessage\nError: $error',
        name: _appName,
        level: _getLevelValue(level),
        error: error,
      );
    } else {
      developer.log(
        logMessage,
        name: _appName,
        level: _getLevelValue(level),
      );
    }
  }

  static int _getLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }

  // Specific loggers for different contexts
  static void authLog(String message, {LogLevel level = LogLevel.info}) {
    _log(level, message, context: 'Auth');
  }

  static void serviceLog(String message, String service, {LogLevel level = LogLevel.info}) {
    _log(level, message, context: service);
  }

  static void uiLog(String message, {LogLevel level = LogLevel.info}) {
    _log(level, message, context: 'UI');
  }

  static void firebaseLog(String message, {LogLevel level = LogLevel.info, dynamic error}) {
    _log(level, message, context: 'Firebase', error: error);
  }
} 