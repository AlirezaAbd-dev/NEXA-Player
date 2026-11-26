import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridges Android native lockscreen window flags (`setShowWhenLocked`) and
/// `ACTION_SCREEN_ON` events with the Flutter `/lockscreen` player modal.
class LockscreenService {
  LockscreenService._();

  static const MethodChannel _channel =
      MethodChannel('com.nexa.player/lockscreen');

  static VoidCallback? _onOpenRequested;
  static bool _initialized = false;

  static void registerOpenHandler(VoidCallback onOpenRequested) {
    _onOpenRequested = onOpenRequested;
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openLockscreen') {
        _onOpenRequested?.call();
      }
    });
  }

  static void unregisterOpenHandler() {
    _onOpenRequested = null;
  }

  static Future<void> syncConfig({
    required bool enabled,
    required bool isPlaying,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('setLockscreenConfig', {
        'enabled': enabled,
        'isPlaying': isPlaying,
      });
    } on MissingPluginException {
      // Safe no-op in tests.
    } catch (e) {
      debugPrint('LockscreenService.syncConfig error: $e');
    }
  }

  static Future<void> dismissLockscreen() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('dismissLockscreen');
    } on MissingPluginException {
      // Safe no-op in tests.
    } catch (e) {
      debugPrint('LockscreenService.dismissLockscreen error: $e');
    }
  }
}
