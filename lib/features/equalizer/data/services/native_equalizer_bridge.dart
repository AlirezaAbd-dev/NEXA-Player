import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nexa_player/features/equalizer/domain/entities/equalizer_state.dart';
import 'package:nexa_player/features/player/domain/services/audio_engine.dart';

/// Abstraction for forwarding [EqualizerState] changes to a native audio DSP backend.
abstract interface class IEqualizerDspBridge {
  Future<void> applyState(EqualizerState state);
  void dispose();
}

/// Bridges [EqualizerState] to Android's native `AudioEffect` pipeline
/// (`Equalizer`, `BassBoost`, `Virtualizer`, `PresetReverb`, `LoudnessEnhancer`)
/// bound to the active `just_audio` Android audio session ID.
class AndroidEqualizerDspBridge implements IEqualizerDspBridge {
  AndroidEqualizerDspBridge({
    required IAudioSessionProvider? audioSessionProvider,
    MethodChannel? channel,
    bool? isAndroidOverride,
  })  : _audioSessionProvider = audioSessionProvider,
        _channel = channel ?? const MethodChannel(_channelName),
        _isAndroid = isAndroidOverride ?? Platform.isAndroid {
    _currentSessionId = _audioSessionProvider?.androidAudioSessionId;
    _sessionSub = _audioSessionProvider?.androidAudioSessionIdStream.listen(
      (sessionId) {
        if (sessionId == null || sessionId <= 0) return;
        final changed = _currentSessionId != sessionId;
        _currentSessionId = sessionId;
        final latest = _latestState;
        if (changed && latest != null) {
          unawaited(applyState(latest));
        }
      },
    );
  }

  static const String _channelName = 'com.nexa.player/equalizer';

  final IAudioSessionProvider? _audioSessionProvider;
  final MethodChannel _channel;
  final bool _isAndroid;

  StreamSubscription<int?>? _sessionSub;
  int? _currentSessionId;
  EqualizerState? _latestState;

  @override
  Future<void> applyState(EqualizerState state) async {
    _latestState = state;
    if (!_isAndroid) return;

    final sessionId =
        _audioSessionProvider?.androidAudioSessionId ?? _currentSessionId;
    if (sessionId == null || sessionId <= 0) return;
    _currentSessionId = sessionId;

    try {
      await _channel.invokeMethod<void>('applyState', {
        'audioSessionId': sessionId,
        'isEnabled': state.isEnabled,
        'preamp': state.preamp,
        'bassBoost': state.bassBoost,
        'virtualizer': state.virtualizer,
        'reverb': state.reverb.name,
        'bands': state.bands
            .map((b) => {
                  'frequency': b.centerFrequency,
                  'gain': b.gain,
                })
            .toList(growable: false),
      });
    } on MissingPluginException {
      // Safe no-op in tests or unsupported platforms.
    } catch (e) {
      debugPrint('AndroidEqualizerDspBridge.applyState error: $e');
    }
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    _sessionSub = null;
    if (_isAndroid) {
      _channel.invokeMethod<void>('release').catchError((_) {});
    }
  }
}
