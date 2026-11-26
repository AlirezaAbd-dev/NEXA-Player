import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/equalizer/data/services/native_equalizer_bridge.dart';
import 'package:nexa_player/features/equalizer/data/services/pure_dart_equalizer_service.dart';
import 'package:nexa_player/features/equalizer/domain/entities/reverb_preset.dart';
import 'package:nexa_player/features/player/domain/services/audio_engine.dart';

class _FakeSessionProvider implements IAudioSessionProvider {
  final _controller = StreamController<int?>.broadcast();
  int? _sessionId;

  @override
  int? get androidAudioSessionId => _sessionId;

  @override
  Stream<int?> get androidAudioSessionIdStream => _controller.stream;

  void emitSession(int? id) {
    _sessionId = id;
    _controller.add(id);
  }

  Future<void> close() => _controller.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PureDartEqualizerService forwards band, preamp, bass, virtualizer, and reverb changes to DSP bridge',
      () async {
    final calls = <MethodCall>[];
    const channel = MethodChannel('com.nexa.player/equalizer_test_1');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final sessionProvider = _FakeSessionProvider();
    addTearDown(sessionProvider.close);

    final bridge = AndroidEqualizerDspBridge(
      audioSessionProvider: sessionProvider,
      channel: channel,
      isAndroidOverride: true,
    );
    final service = PureDartEqualizerService(dspBridge: bridge);
    await service.initialize();

    // No session yet: nothing sent until session ID arrives.
    expect(calls, isEmpty);

    // Once audio session starts, bridge immediately applies latest state.
    sessionProvider.emitSession(42);
    await Future<void>.delayed(Duration.zero);
    expect(calls.length, 1);
    expect(calls.last.method, 'applyState');
    expect((calls.last.arguments as Map)['audioSessionId'], 42);

    // Changing band gain, bassBoost, preamp, virtualizer, reverb all invoke native applyState.
    await service.setBandGain(0, 6.5);
    await service.setBassBoost(0.7);
    await service.setPreamp(-3.0);
    await service.setVirtualizer(0.5);
    await service.setReverb(ReverbPreset.hall);

    expect(calls.length, 6);
    final lastArgs = calls.last.arguments as Map;
    expect(lastArgs['audioSessionId'], 42);
    expect(lastArgs['bassBoost'], 0.7);
    expect(lastArgs['preamp'], -3.0);
    expect(lastArgs['virtualizer'], 0.5);
    expect(lastArgs['reverb'], 'hall');
    final bands = lastArgs['bands'] as List;
    expect((bands.first as Map)['gain'], 6.5);

    service.dispose();
  });
}
