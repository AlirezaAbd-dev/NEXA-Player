import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/di/service_providers.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/cloud/cloud.dart';
import 'package:nexa_player/shared/services/storage/storage_service.dart';

class TestStorageService implements IStorageService {
  final Map<String, dynamic> _data = {};

  @override
  Future<Result<void, StorageFailure>> setString(String key, String value) async {
    _data[key] = value;
    return const Result.success(null);
  }

  @override
  Result<String?, StorageFailure> getString(String key) => Result.success(_data[key] as String?);

  @override
  Future<Result<void, StorageFailure>> setBool(String key, bool value) async {
    _data[key] = value;
    return const Result.success(null);
  }

  @override
  Result<bool?, StorageFailure> getBool(String key) => Result.success(_data[key] as bool?);

  @override
  Future<Result<void, StorageFailure>> remove(String key) async {
    _data.remove(key);
    return const Result.success(null);
  }

  @override
  Future<Result<void, StorageFailure>> clear() async {
    _data.clear();
    return const Result.success(null);
  }
}

void main() {
  testWidgets('NetworkServerBrowserScreen renders directory contents', (tester) async {
    final storage = TestStorageService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
        ],
        child: const MaterialApp(
          home: NetworkServerBrowserScreen(serverId: 'nexa_demo_synology'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify title matches server name
    expect(find.text('Synology DiskStation (Master Vault)'), findsOneWidget);

    // Verify directory contents
    expect(find.text('Hi-Res DSD Master Vault'), findsOneWidget);
    expect(find.text('FLAC 24-bit 96kHz Lossless'), findsOneWidget);
    expect(find.text('Cybernetic Pulse'), findsOneWidget);
    expect(find.text('Play Folder (3)'), findsOneWidget);
  });
}
