import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/shared/services/storage/shared_preferences_storage_service.dart';
import 'package:nexa_player/shared/services/storage/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late IStorageService storageService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'existing_str': 'hello_nexa',
      'existing_bool': true,
    });
    prefs = await SharedPreferences.getInstance();
    storageService = SharedPreferencesStorageService(prefs);
  });

  group('SharedPreferencesStorageService', () {
    group('String operations', () {
      test('getString returns existing value wrapped in Success', () {
        final result = storageService.getString('existing_str');

        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull, equals('hello_nexa'));
      });

      test('getString returns null wrapped in Success when key missing', () {
        final result = storageService.getString('non_existent');

        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull, isNull);
      });

      test('setString persists new value and returns Success', () async {
        final setResult = await storageService.setString('new_key', 'new_val');
        expect(setResult.isSuccess, isTrue);

        final getResult = storageService.getString('new_key');
        expect(getResult.valueOrNull, equals('new_val'));
      });

      test('setString overwrites previously stored string', () async {
        await storageService.setString('mode', 'dark');
        await storageService.setString('mode', 'light');

        final result = storageService.getString('mode');
        expect(result.valueOrNull, equals('light'));
      });
    });

    group('Bool operations', () {
      test('getBool returns existing boolean wrapped in Success', () {
        final result = storageService.getBool('existing_bool');

        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull, isTrue);
      });

      test('getBool returns null wrapped in Success when key missing', () {
        final result = storageService.getBool('non_existent');

        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull, isNull);
      });

      test('setBool persists new boolean and returns Success', () async {
        final setResult = await storageService.setBool('is_dark', false);
        expect(setResult.isSuccess, isTrue);

        final getResult = storageService.getBool('is_dark');
        expect(getResult.valueOrNull, isFalse);
      });

      test('setBool updates boolean flag from true to false', () async {
        await storageService.setBool('flag', true);
        await storageService.setBool('flag', false);

        final result = storageService.getBool('flag');
        expect(result.valueOrNull, isFalse);
      });
    });

    group('Remove operations', () {
      test('remove deletes key and subsequent read returns null', () async {
        final removeResult = await storageService.remove('existing_str');
        expect(removeResult.isSuccess, isTrue);

        final getResult = storageService.getString('existing_str');
        expect(getResult.valueOrNull, isNull);
      });

      test('remove returns Success even if key does not exist', () async {
        final result = await storageService.remove('non_existent');
        expect(result.isSuccess, isTrue);
      });
    });

    group('Clear operations', () {
      test('clear removes all entries from storage', () async {
        final clearResult = await storageService.clear();
        expect(clearResult.isSuccess, isTrue);

        expect(storageService.getString('existing_str').valueOrNull, isNull);
        expect(storageService.getBool('existing_bool').valueOrNull, isNull);
      });
    });

    group('Error handling and type mismatch', () {
      test('getString returns StorageFailure when underlying value is not a String', () async {
        await prefs.setInt('int_key', 42);

        final result = storageService.getString('int_key');
        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<StorageFailure>());
      });

      test('getBool returns StorageFailure when underlying value is not a Bool', () async {
        await prefs.setString('str_key', 'not_a_bool');

        final result = storageService.getBool('str_key');
        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<StorageFailure>());
      });
    });
  });
}
