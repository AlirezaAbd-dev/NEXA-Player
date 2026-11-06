import 'package:talker_flutter/talker_flutter.dart';
import 'logging_service.dart';

/// Implementation of [ILoggingService] powered by [Talker].
class TalkerLoggingService implements ILoggingService {
  TalkerLoggingService({Talker? talker}) : _talker = talker ?? Talker();

  final Talker _talker;

  /// Exposes the underlying [Talker] instance for UI screens and observers.
  Talker get talker => _talker;

  @override
  void debug(String message) {
    _talker.debug(message);
  }

  @override
  void info(String message) {
    _talker.info(message);
  }

  @override
  void warning(String message) {
    _talker.warning(message);
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _talker.error(message, error, stackTrace);
  }
}
