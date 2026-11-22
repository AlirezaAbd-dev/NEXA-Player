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
  testWidgets('CloudStreamingHubScreen renders all sections cleanly', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final storage = TestStorageService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
        ],
        child: const MaterialApp(
          home: CloudStreamingHubScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Cloud & Network Hub'), findsOneWidget);

    // Verify Active Casting / Output card
    expect(find.text('Audio Output'), findsOneWidget);

    // Verify Network Storage section
    expect(find.text('NETWORK STORAGE & SERVERS'), findsOneWidget);
    expect(find.text('Add Endpoint'), findsOneWidget);
    expect(find.text('Synology DiskStation (Master Vault)'), findsOneWidget);

    // Verify Web Radio Card
    expect(find.text('Audiophile Web Radio'), findsOneWidget);
    expect(find.text('FLAC 24-BIT'), findsOneWidget);

    // Verify Cache & Streaming Settings
    expect(find.text('STREAMING & CACHE ENGINE'), findsOneWidget);
    expect(find.text('Streaming Disk Cache'), findsOneWidget);
    expect(find.text('Prefer Lossless FLAC/DSD'), findsOneWidget);
    expect(find.text('Auto-Discover Cast Devices'), findsOneWidget);
  });

  testWidgets('Tapping Add Endpoint opens ServerConfigDialog', (tester) async {
    final storage = TestStorageService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
        ],
        child: const MaterialApp(
          home: CloudStreamingHubScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final addBtn = find.byKey(const ValueKey('add_server_header_button'));
    expect(addBtn, findsOneWidget);
    await tester.tap(addBtn);
    await tester.pumpAndSettle();

    expect(find.text('Add Network Storage'), findsOneWidget);
    expect(find.text('WebDAV'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });
}
