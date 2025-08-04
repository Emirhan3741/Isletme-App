enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

extension LogLevelExtension on LogLevel {
  String get displayName {
    switch (this) {
      case LogLevel.debug:
        return 'Debug';
      case LogLevel.info:
        return 'Info';
      case LogLevel.warning:
        return 'Warning';
      case LogLevel.error:
        return 'Error';
      case LogLevel.critical:
        return 'Critical';
    }
  }
}
// Cleaned and fixed for web build
