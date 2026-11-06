import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/utils/result.dart';

void main() {
  group('Result Monad', () {
    const testValue = 42;
    const testFailure = UnexpectedFailure('Boom');

    group('Success', () {
      test('has correct flags and values', () {
        const result = Result<int, Failure>.success(testValue);

        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
        expect(result.valueOrNull, equals(testValue));
        expect(result.failureOrNull, isNull);
      });

      test('when executes success branch only', () {
        const result = Result<int, Failure>.success(testValue);
        var successCalled = false;
        var failureCalled = false;

        final mapped = result.when(
          success: (v) {
            successCalled = true;
            return v * 2;
          },
          failure: (_) {
            failureCalled = true;
            return -1;
          },
        );

        expect(successCalled, isTrue);
        expect(failureCalled, isFalse);
        expect(mapped, equals(84));
      });

      test('fold executes onSuccess callback', () {
        const result = Result<int, Failure>.success(testValue);
        final mapped = result.fold(
          (v) => 'Value: $v',
          (f) => 'Failure: ${f.message}',
        );

        expect(mapped, equals('Value: 42'));
      });

      test('map transforms value on success', () {
        const result = Result<int, Failure>.success(testValue);
        final mapped = result.map((v) => v.toString());

        expect(mapped, equals(const Result<String, Failure>.success('42')));
      });

      test('flatMap chains another Result on success', () {
        const result = Result<int, Failure>.success(testValue);
        final chained = result.flatMap(
          (v) => Result<String, Failure>.success('$v km'),
        );

        expect(chained, equals(const Result<String, Failure>.success('42 km')));
      });

      test('getOrElse returns value directly', () {
        const result = Result<int, Failure>.success(testValue);
        expect(result.getOrElse((_) => 0), equals(42));
      });

      test('getOrThrow returns value without throwing', () {
        const result = Result<int, Failure>.success(testValue);
        expect(result.getOrThrow(), equals(42));
      });

      test('supports void type as Result<void, Failure>', () {
        const result = Result<void, Failure>.success(null);
        expect(result.isSuccess, isTrue);
        expect(result.failureOrNull, isNull);
      });

      test('supports nullable values as Result<String?, Failure>', () {
        const result = Result<String?, Failure>.success(null);
        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull, isNull);
      });

      test('Dart 3 switch pattern matching destructures correctly', () {
        const Result<int, Failure> result = Result.success(testValue);
        final matched = switch (result) {
          Success(:final value) => 'Matched: $value',
          Error(:final failure) => 'Failed: $failure',
        };
        expect(matched, equals('Matched: 42'));
      });

      test('equality and hashCode match identical values', () {
        const r1 = Result<int, Failure>.success(42);
        const r2 = Result<int, Failure>.success(42);
        const r3 = Result<int, Failure>.success(99);

        expect(r1, equals(r2));
        expect(r1.hashCode, equals(r2.hashCode));
        expect(r1, isNot(equals(r3)));
      });
    });

    group('Error / Failure', () {
      test('has correct flags and values', () {
        const result = Result<int, Failure>.failure(testFailure);

        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.valueOrNull, isNull);
        expect(result.failureOrNull, equals(testFailure));
      });

      test('when executes failure branch only', () {
        const result = Result<int, Failure>.failure(testFailure);
        var successCalled = false;
        var failureCalled = false;

        final mapped = result.when(
          success: (v) {
            successCalled = true;
            return v * 2;
          },
          failure: (f) {
            failureCalled = true;
            return f.message;
          },
        );

        expect(successCalled, isFalse);
        expect(failureCalled, isTrue);
        expect(mapped, equals('Boom'));
      });

      test('fold executes onFailure callback', () {
        const result = Result<int, Failure>.failure(testFailure);
        final mapped = result.fold(
          (v) => 'Value: $v',
          (f) => 'Failure: ${f.message}',
        );

        expect(mapped, equals('Failure: Boom'));
      });

      test('map does not transform error', () {
        const result = Result<int, Failure>.failure(testFailure);
        final mapped = result.map((v) => v.toString());

        expect(mapped, equals(const Result<String, Failure>.failure(testFailure)));
      });

      test('flatMap retains error without calling transform', () {
        const result = Result<int, Failure>.failure(testFailure);
        var transformCalled = false;
        final chained = result.flatMap((v) {
          transformCalled = true;
          return Result<String, Failure>.success('$v km');
        });

        expect(transformCalled, isFalse);
        expect(chained.isFailure, isTrue);
        expect(chained.failureOrNull, equals(testFailure));
      });

      test('getOrElse evaluates fallback function', () {
        const result = Result<int, Failure>.failure(testFailure);
        expect(result.getOrElse((f) => -1), equals(-1));
      });

      test('getOrThrow throws underlying failure', () {
        const result = Result<int, Failure>.failure(testFailure);
        expect(() => result.getOrThrow(), throwsA(isA<UnexpectedFailure>()));
      });

      test('equality and hashCode match identical failures', () {
        const r1 = Result<int, Failure>.failure(UnexpectedFailure('Err'));
        const r2 = Result<int, Failure>.failure(UnexpectedFailure('Err'));
        const r3 = Result<int, Failure>.failure(UnexpectedFailure('Diff'));

        expect(r1, equals(r2));
        expect(r1.hashCode, equals(r2.hashCode));
        expect(r1, isNot(equals(r3)));
      });
    });

    group('Result.guard & Result.guardAsync', () {
      test('guard captures non-throwing block as Success', () {
        final res = Result.guard(() => int.parse('123'));
        expect(res.isSuccess, isTrue);
        expect(res.valueOrNull, equals(123));
      });

      test('guard captures throwing block as Error', () {
        final res = Result.guard(() => int.parse('not_a_number'));
        expect(res.isFailure, isTrue);
        expect(res.failureOrNull, isA<Failure>());
      });

      test('guardAsync captures resolving Future as Success', () async {
        final res = await Result.guardAsync(() async => Future.value('audio.mp3'));
        expect(res.isSuccess, isTrue);
        expect(res.valueOrNull, equals('audio.mp3'));
      });

      test('guardAsync captures rejecting Future as Error', () async {
        final res = await Result.guardAsync(() async => throw Exception('IO Error'));
        expect(res.isFailure, isTrue);
        expect(res.failureOrNull?.message, contains('IO Error'));
      });
    });
  });
}
