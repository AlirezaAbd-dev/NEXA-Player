import 'package:equatable/equatable.dart';

/// Base class for all domain failures in NEXA Player.
abstract class Failure extends Equatable {
  const Failure(this.message, [this.cause, this.stackTrace]);

  /// Human-readable description of the failure.
  final String message;

  /// Optional underlying error or exception.
  final Object? cause;

  /// Optional stack trace captured when the failure occurred.
  final StackTrace? stackTrace;

  @override
  List<Object?> get props => [message, cause];

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType: $message');
    if (cause != null) {
      buffer.write(' (Cause: $cause)');
    }
    return buffer.toString();
  }
}

/// Generic unexpected failure for unhandled exceptions.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([
    super.message = 'An unexpected error occurred.',
    super.cause,
    super.stackTrace,
  ]);
}

/// Failure representing input or validation errors.
class ValidationFailure extends Failure {
  const ValidationFailure(
    super.message, [
    super.cause,
    super.stackTrace,
  ]);
}
