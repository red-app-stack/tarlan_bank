import 'dart:developer' as developer;

/// Lightweight structured logger built on `dart:developer`.
///
/// Replaces ad-hoc `print()` calls. Logs are namespaced and levelled, show up in
/// the debug console / DevTools, and do not leak into release stdout the way
/// `print` does. Inject an [AppLogger] per service/repository.
enum LogLevel { debug, info, warning, error }

class AppLogger {
  const AppLogger(this.name);

  final String name;

  void debug(String message) => _log(LogLevel.debug, message);
  void info(String message) => _log(LogLevel.info, message);
  void warning(String message, [Object? error]) =>
      _log(LogLevel.warning, message, error);
  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _log(LogLevel.error, message, error, stackTrace);

  void _log(LogLevel level, String message, [Object? error, StackTrace? st]) {
    developer.log(
      message,
      name: name,
      level: _levelValue(level),
      error: error,
      stackTrace: st,
    );
  }

  static int _levelValue(LogLevel level) => switch (level) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warning => 900,
        LogLevel.error => 1000,
      };
}