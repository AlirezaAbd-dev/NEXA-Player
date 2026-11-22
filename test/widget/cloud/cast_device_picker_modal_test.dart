import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/cloud/cloud.dart';

void main() {
  testWidgets('CastDevicePickerModal renders header and discovered speakers', (tester) async {
    final discovery = UpnpSsdpDiscoveryService(enableMockFallbacks: true, broadcastPackets: false);
    await discovery.startDiscovery(timeout: const Duration(milliseconds: 50));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          castDiscoveryServiceProvider.overrideWithValue(discovery),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CastDevicePickerModal(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Cast to Network Audio'), findsOneWidget);
    expect(find.text('Select a DLNA or Chromecast receiver'), findsOneWidget);
    expect(find.text('Living Room Hi-Fi (DLNA)'), findsOneWidget);
    expect(find.text('Studio Lab Smart Display'), findsOneWidget);

    await discovery.dispose();
  });
}
