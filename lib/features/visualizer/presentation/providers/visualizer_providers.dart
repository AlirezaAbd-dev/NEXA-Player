import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/constants/storage_keys.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/core/di/service_providers.dart' hide audioEngineProvider;
import 'package:nexa_player/features/player/domain/services/audio_engine.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../domain/models/visualizer_settings.dart';
import '../../domain/services/fft_spectrum_processor.dart';
import '../../domain/services/waveform_pre_processor.dart';

/// Visualizer settings notifier managing style, sensitivity, smoothing, fps cap,
/// resolution, cover breathing, and optional lockscreen display.
class VisualizerSettingsNotifier extends StateNotifier<VisualizerSettings> {
  VisualizerSettingsNotifier(this._ref) : super(const VisualizerSettings()) {
    _load();
  }

  final Ref _ref;
  static const MethodChannel _fftControl =
      MethodChannel('com.nexa.player/fft_control');

  void _load() {
    try {
      final storage = _ref.read(storageServiceProvider);
      final styleRaw = storage.getString(StorageKeys.visualizerStyle).valueOrNull;
      final colorRaw = storage.getString(StorageKeys.visualizerColor).valueOrNull;
      final sensRaw = storage.getString(StorageKeys.visualizerSensitivity).valueOrNull;
      final smoothRaw = storage.getString(StorageKeys.visualizerSmoothing).valueOrNull;
      final fpsRaw = storage.getString(StorageKeys.visualizerFpsCap).valueOrNull;
      final fftSizeRaw = storage.getString(StorageKeys.visualizerFftSize).valueOrNull;
      final breathRaw = storage.getBool(StorageKeys.visualizerCoverBreathing).valueOrNull;
      final lockRaw = storage.getBool(StorageKeys.visualizerShowOnLockscreen).valueOrNull;

      state = VisualizerSettings(
        style: VisualizerStyle.values.firstWhere(
          (e) => e.name == styleRaw,
          orElse: () => VisualizerStyle.bars,
        ),
        colorHex: colorRaw ?? '0xFF00E5FF',
        sensitivity: (double.tryParse(sensRaw ?? '') ?? 1.0).clamp(0.5, 2.5),
        smoothing: (double.tryParse(smoothRaw ?? '') ?? 0.65).clamp(0.0, 0.95),
        fpsCap: int.tryParse(fpsRaw ?? '') ?? 60,
        fftSize: int.tryParse(fftSizeRaw ?? '') ?? 64,
        coverBreathing: breathRaw ?? true,
        showOnLockScreen: lockRaw ?? false,
      );
    } catch (_) {}
  }

  Future<void> update(VisualizerSettings settings) async {
    state = settings;
    try {
      final storage = _ref.read(storageServiceProvider);
      await storage.setString(StorageKeys.visualizerStyle, settings.style.name);
      await storage.setString(StorageKeys.visualizerColor, settings.colorHex);
      await storage.setString(
        StorageKeys.visualizerSensitivity,
        settings.sensitivity.toString(),
      );
      await storage.setString(
        StorageKeys.visualizerSmoothing,
        settings.smoothing.toString(),
      );
      await storage.setString(
        StorageKeys.visualizerFpsCap,
        settings.fpsCap.toString(),
      );
      await storage.setString(
        StorageKeys.visualizerFftSize,
        settings.fftSize.toString(),
      );
      await storage.setBool(
        StorageKeys.visualizerCoverBreathing,
        settings.coverBreathing,
      );
      await storage.setBool(
        StorageKeys.visualizerShowOnLockscreen,
        settings.showOnLockScreen,
      );
    } catch (_) {}
  }

  /// Requests `RECORD_AUDIO` permission gracefully ONLY when the user actively
  /// enables live visualization on Android. Falls back cleanly to RMS envelope
  /// if denied or on non-Android platforms.
  Future<bool> requestLiveFftPermissionIfActivated() async {
    if (!Platform.isAndroid || state.style == VisualizerStyle.off) {
      return false;
    }
    try {
      final hasPerm = await _fftControl
          .invokeMethod<bool>('hasRecordAudioPermission')
          .timeout(const Duration(milliseconds: 250));
      if (hasPerm == true) return true;
      final status = await Permission.microphone.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  void cycleStyle() {
    const styles = VisualizerStyle.values;
    final nextIndex = (styles.indexOf(state.style) + 1) % styles.length;
    update(state.copyWith(style: styles[nextIndex]));
  }
}

final visualizerSettingsProvider =
    StateNotifierProvider<VisualizerSettingsNotifier, VisualizerSettings>((ref) {
  return VisualizerSettingsNotifier(ref);
});

/// Live real-time audio FFT magnitude stream backed by Android's native
/// `Visualizer` (`com.nexa.player/fft_stream`) with logarithmic `32Hz..16kHz`
/// octave binning, ballistic smoothing, 300ms silence decay on pause, and
/// pre-computed per-track RMS envelope fallback when OS FFT is unavailable.
final liveMagnitudesProvider = StreamProvider.autoDispose<List<double>>((ref) {
  final settings = ref.watch(visualizerSettingsProvider);
  final bool isPlaying;
  final Track? track;
  final Duration duration;
  try {
    isPlaying = ref.watch(playerNotifierProvider.select((s) => s.isPlaying));
    track = ref.watch(playerNotifierProvider.select((s) => s.currentTrack));
    duration = ref.watch(playerNotifierProvider.select((s) => s.duration));
  } catch (_) {
    return Stream.value(List<double>.filled(settings.fftSize, 0.0));
  }

  if (settings.style == VisualizerStyle.off) {
    return Stream.value(List<double>.filled(settings.fftSize, 0.0));
  }

  final engine = (() {
    try {
      return ref.read(audioEngineProvider);
    } catch (_) {
      return null;
    }
  })();
  final processor = FftSpectrumProcessor(
    bandCount: settings.fftSize,
    smoothing: settings.smoothing,
    sensitivity: settings.sensitivity,
  );

  final fps = settings.fpsCap.clamp(15, 120);
  final intervalMs = 1000 ~/ fps;
  final controller = StreamController<List<double>>();

  const eventChannel = EventChannel('com.nexa.player/fft_stream');
  const controlChannel = MethodChannel('com.nexa.player/fft_control');

  StreamSubscription<dynamic>? fftSub;
  StreamSubscription<int?>? sessionSub;
  Timer? fallbackOrDecayTimer;
  bool nativeStreamActive = false;
  List<double>? trackEnvelope;

  if (track != null && getIt.isRegistered<IWaveformPreProcessor>()) {
    ref
        .read(waveformPreProcessorProvider)
        .getOrAnalyzeWaveform(
          trackId: track.id,
          filePath: track.filePath ?? '',
          sampleCount: 56,
        )
        .then((env) {
      trackEnvelope = env;
    }).catchError((_) {});
  }

  void startFallbackOrDecayTimer() {
    fallbackOrDecayTimer?.cancel();
    fallbackOrDecayTimer = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) {
        if (controller.isClosed) return;
        final currentPlaying = ref.read(isPlayingProvider);
        if (!currentPlaying) {
          final decayed = processor.decayToSilence(intervalMs.toDouble());
          controller.add(decayed);
          if (decayed.every((v) => v == 0.0)) {
            fallbackOrDecayTimer?.cancel();
            fallbackOrDecayTimer = null;
          }
          return;
        }
        if (nativeStreamActive) return;

        final pos = engine?.position ?? ref.read(playerNotifierProvider).position;
        final dur = duration.inMilliseconds > 0 ? duration : (track?.duration ?? Duration.zero);
        final progress = dur.inMilliseconds > 0
            ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
            : 0.0;
        final env = trackEnvelope;
        if (env != null && env.isNotEmpty) {
          controller.add(
            processor.processWaveformEnvelopeFallback(
              env,
              progress: progress,
              isPlaying: true,
              dtMs: intervalMs.toDouble(),
            ),
          );
        }
      },
    );
  }

  Future<void> bindNativeFft() async {
    if (!Platform.isAndroid || !isPlaying) {
      if (Platform.isAndroid) {
        try {
          await controlChannel.invokeMethod<void>('setEnabled', {'enabled': false});
        } catch (_) {}
      }
      startFallbackOrDecayTimer();
      return;
    }

    int? sessionId;
    if (engine != null && engine is IAudioSessionProvider) {
      final sessionProvider = engine as IAudioSessionProvider;
      sessionId = sessionProvider.androidAudioSessionId;
      sessionSub = sessionProvider.androidAudioSessionIdStream.listen((id) {
        if (id != null && id > 0) {
          controlChannel.invokeMethod<void>('updateSession', {
            'audioSessionId': id,
            'fpsCap': fps,
            'enabled': true,
          }).catchError((_) {});
        }
      });
    }

    try {
      final hasPerm = await controlChannel
          .invokeMethod<bool>('hasRecordAudioPermission')
          .timeout(const Duration(milliseconds: 200));
      if (hasPerm != true) {
        nativeStreamActive = false;
        startFallbackOrDecayTimer();
        return;
      }

      fftSub = eventChannel
          .receiveBroadcastStream({
            'audioSessionId': sessionId ?? 0,
            'fpsCap': fps,
          })
          .listen(
            (event) {
              if (controller.isClosed) return;
              if (event is Map) {
                final bytes = event['bytes'];
                final capSize = (event['captureSize'] as num?)?.toInt();
                if (bytes is Uint8List) {
                  nativeStreamActive = true;
                  controller.add(
                    processor.processAndroidFftBytes(
                      bytes,
                      isPlaying: ref.read(isPlayingProvider),
                      captureSize: capSize,
                      dtMs: intervalMs.toDouble(),
                    ),
                  );
                }
              }
            },
            onError: (_) {
              nativeStreamActive = false;
              startFallbackOrDecayTimer();
            },
          );
    } catch (_) {
      nativeStreamActive = false;
    }

    startFallbackOrDecayTimer();
  }

  unawaited(bindNativeFft());

  ref.onDispose(() {
    fallbackOrDecayTimer?.cancel();
    fftSub?.cancel();
    sessionSub?.cancel();
    if (Platform.isAndroid) {
      controlChannel.invokeMethod<void>('stopCapture').catchError((_) {});
    }
    if (!controller.isClosed) {
      controller.close();
    }
  });

  return controller.stream;
});

/// Sub-bass (`20–80 Hz`) normalized energy (`0.0 .. 1.0`) driving cover art
/// breathing animations when [VisualizerSettings.coverBreathing] is enabled.
final subBassEnergyProvider = Provider.autoDispose<double>((ref) {
  final settings = ref.watch(visualizerSettingsProvider);
  bool isPlaying = false;
  try {
    isPlaying = ref.watch(isPlayingProvider);
  } catch (_) {
    return 0.0;
  }
  if (!settings.coverBreathing ||
      !isPlaying ||
      settings.style == VisualizerStyle.off) {
    return 0.0;
  }
  final mags = ref.watch(liveMagnitudesProvider).valueOrNull;
  if (mags == null || mags.isEmpty) return 0.0;
  final subCount = (mags.length * 0.10).round().clamp(1, 6);
  double sum = 0.0;
  for (int i = 0; i < subCount; i++) {
    final v = mags[i];
    if (!v.isNaN && !v.isInfinite) {
      sum += v.clamp(0.0, 1.0);
    }
  }
  return (sum / subCount).clamp(0.0, 1.0);
});
