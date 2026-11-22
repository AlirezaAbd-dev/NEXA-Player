import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/di/service_providers.dart';
import '../../../../shared/services/storage/storage_service.dart';
import '../../domain/models/widget_config.dart';

/// State notifier for homescreen widget styling preferences.
class WidgetConfigNotifier extends StateNotifier<WidgetConfig> {
  WidgetConfigNotifier(this._storage) : super(const WidgetConfig()) {
    _load();
  }

  final IStorageService _storage;

  void _load() {
    final opacityStr =
        _storage.getString(StorageKeys.widgetBackgroundOpacity).valueOrNull;
    final radiusStr =
        _storage.getString(StorageKeys.widgetCornerRadius).valueOrNull;
    final glow =
        _storage.getBool(StorageKeys.widgetShowGlow).valueOrNull ?? true;
    final vinyl =
        _storage.getBool(StorageKeys.widgetShowVinyl).valueOrNull ?? true;
    final adaptive =
        _storage.getBool(StorageKeys.widgetAdaptiveColors).valueOrNull ?? true;

    final opacity = double.tryParse(opacityStr ?? '') ?? 0.85;
    final radius = double.tryParse(radiusStr ?? '') ?? 24.0;

    state = WidgetConfig(
      backgroundOpacity: opacity,
      cornerRadius: radius,
      showGlow: glow,
      showVinyl: vinyl,
      adaptiveColors: adaptive,
    );
  }

  Future<void> update(WidgetConfig config) async {
    state = config;
    await _storage.setString(
        StorageKeys.widgetBackgroundOpacity, config.backgroundOpacity.toString());
    await _storage.setString(
        StorageKeys.widgetCornerRadius, config.cornerRadius.toString());
    await _storage.setBool(StorageKeys.widgetShowGlow, config.showGlow);
    await _storage.setBool(StorageKeys.widgetShowVinyl, config.showVinyl);
    await _storage.setBool(
        StorageKeys.widgetAdaptiveColors, config.adaptiveColors);
  }

  Future<void> updateBackgroundOpacity(double opacity) async {
    await update(state.copyWith(backgroundOpacity: opacity));
  }

  Future<void> updateCornerRadius(double radius) async {
    await update(state.copyWith(cornerRadius: radius));
  }

  Future<void> toggleGlow(bool showGlow) async {
    await update(state.copyWith(showGlow: showGlow));
  }

  Future<void> toggleVinyl(bool showVinyl) async {
    await update(state.copyWith(showVinyl: showVinyl));
  }

  Future<void> toggleAdaptiveColors(bool adaptive) async {
    await update(state.copyWith(adaptiveColors: adaptive));
  }
}

/// Provider for homescreen widget styling config.
final widgetConfigProvider =
    StateNotifierProvider<WidgetConfigNotifier, WidgetConfig>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return WidgetConfigNotifier(storage);
});

/// Currently previewed widget form factor in the showcase screen.
final selectedWidgetFormFactorProvider =
    StateProvider<WidgetFormFactor>((ref) => WidgetFormFactor.heroVinyl);
