import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/equalizer_state.dart';
import '../../domain/services/equalizer_service.dart';
import 'equalizer_notifier.dart';

/// Exposes the active [IEqualizerService] singleton from GetIt to Riverpod.
final equalizerServiceProvider = Provider<IEqualizerService>((ref) {
  return getIt<IEqualizerService>();
});

/// Exposes the reactive [EqualizerNotifier] managing EQ and DSP states.
final equalizerNotifierProvider =
    StateNotifierProvider<EqualizerNotifier, EqualizerState>((ref) {
  final service = ref.watch(equalizerServiceProvider);
  return EqualizerNotifier(service);
});
