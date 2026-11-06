/// Segregated interface contract for structured application logging.
abstract interface class ILoggingService {
  /// Logs diagnostic information for development.
  void debug(String message);

  /// Logs informational events occurring during normal operation.
  void info(String message);

  /// Logs unexpected conditions that do not halt operation.
  void warning(String message);

  /// Logs errors and exceptions with optional stack trace.
  void error(String message, [Object? error, StackTrace? stackTrace]);
}
