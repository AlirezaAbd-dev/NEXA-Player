import 'failure.dart';
export 'failure.dart';

/// Shorthand alias for a [Result] with standard [Failure].
typedef SimpleResult<T> = Result<T, Failure>;

/// Sealed monad representing either a computation success ([Success])
/// or a domain failure ([Error]).
sealed class Result<T, E extends Failure> {
  const Result();

  /// Creates a successful result wrapping [value].
  const factory Result.success(T value) = Success<T, E>;

  /// Creates a failed result wrapping [failure].
  const factory Result.failure(E failure) = Error<T, E>;

  /// Safely executes a synchronous [computation] block, returning [Success] if it
  /// succeeds, or [Error] wrapping the caught exception as a [Failure].
  static Result<T, Failure> guard<T>(T Function() computation) {
    try {
      return Result<T, Failure>.success(computation());
    } on Failure catch (e) {
      return Result<T, Failure>.failure(e);
    } catch (e, st) {
      return Result<T, Failure>.failure(UnexpectedFailure(e.toString(), e, st));
    }
  }

  /// Safely executes an asynchronous [computation] block, returning [Success] if
  /// it resolves, or [Error] wrapping the caught exception as a [Failure].
  static Future<Result<T, Failure>> guardAsync<T>(
    Future<T> Function() computation,
  ) async {
    try {
      final value = await computation();
      return Result<T, Failure>.success(value);
    } on Failure catch (e) {
      return Result<T, Failure>.failure(e);
    } catch (e, st) {
      return Result<T, Failure>.failure(UnexpectedFailure(e.toString(), e, st));
    }
  }

  /// Returns `true` if the result is a [Success].
  bool get isSuccess;

  /// Returns `true` if the result is an [Error].
  bool get isFailure;

  /// Returns the wrapped value if successful, or `null` if failure.
  T? get valueOrNull;

  /// Returns the wrapped failure if failed, or `null` if success.
  E? get failureOrNull;

  /// Pattern-matches over the result branches.
  R when<R>({
    required R Function(T value) success,
    required R Function(E failure) failure,
  });

  /// Functional fold over the result branches.
  R fold<R>(
    R Function(T value) onSuccess,
    R Function(E failure) onFailure,
  );

  /// Transforms the value of a [Success] using [transform].
  Result<R, E> map<R>(R Function(T value) transform) {
    return when(
      success: (value) => Result<R, E>.success(transform(value)),
      failure: (failure) => Result<R, E>.failure(failure),
    );
  }

  /// Chains another [Result]-producing computation.
  Result<R, E> flatMap<R>(Result<R, E> Function(T value) transform) {
    return when(
      success: transform,
      failure: (failure) => Result<R, E>.failure(failure),
    );
  }

  /// Returns the wrapped value, or evaluates [orElse] with the failure if failed.
  T getOrElse(T Function(E failure) orElse) {
    return when(
      success: (value) => value,
      failure: orElse,
    );
  }

  /// Returns the wrapped value, or throws [failure] if failed.
  T getOrThrow() {
    return when(
      success: (value) => value,
      failure: (failure) => throw failure,
    );
  }
}

/// Concrete successful branch of [Result].
final class Success<T, E extends Failure> extends Result<T, E> {
  const Success(this.value);

  final T value;

  @override
  bool get isSuccess => true;

  @override
  bool get isFailure => false;

  @override
  T? get valueOrNull => value;

  @override
  E? get failureOrNull => null;

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(E failure) failure,
  }) {
    return success(value);
  }

  @override
  R fold<R>(
    R Function(T value) onSuccess,
    R Function(E failure) onFailure,
  ) {
    return onSuccess(value);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Success<T, E> && other.value == value;
  }

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() => 'Result.success($value)';
}

/// Concrete failure branch of [Result].
final class Error<T, E extends Failure> extends Result<T, E> {
  const Error(this.failure);

  final E failure;

  @override
  bool get isSuccess => false;

  @override
  bool get isFailure => true;

  @override
  T? get valueOrNull => null;

  @override
  E? get failureOrNull => failure;

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(E failure) failure,
  }) {
    return failure(this.failure);
  }

  @override
  R fold<R>(
    R Function(T value) onSuccess,
    R Function(E failure) onFailure,
  ) {
    return onFailure(failure);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Error<T, E> && other.failure == failure;
  }

  @override
  int get hashCode => Object.hash(runtimeType, failure);

  @override
  String toString() => 'Result.failure($failure)';
}
