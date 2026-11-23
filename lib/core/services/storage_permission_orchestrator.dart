import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Orchestrates Android 10-14+ storage and audio media permissions with
/// EMUI 10 / Kirin-safe ordering and rationale dialogs.
abstract final class StoragePermissionOrchestrator {
  static const MethodChannel _mediaStoreChannel =
      MethodChannel('com.nexa.player/media_store');

  /// Cached Android SDK version.
  static int? _cachedSdkInt;

  /// Returns the Android SDK version (e.g., 29 for Android 10, 33 for Android 13).
  static Future<int> getAndroidSdkInt() async {
    if (_cachedSdkInt != null) return _cachedSdkInt!;
    if (kIsWeb || !Platform.isAndroid) return 0;

    try {
      final sdk = await _mediaStoreChannel.invokeMethod<int>('getSdkInt');
      _cachedSdkInt = sdk ?? 29;
    } catch (_) {
      _cachedSdkInt = 29; // Safe default for Android 10 / EMUI 10 devices like Huawei Y9s
    }
    return _cachedSdkInt!;
  }

  @visibleForTesting
  static void setMockSdkInt(int? sdk) {
    _cachedSdkInt = sdk;
  }

  /// Determines the relevant permission target based on Android SDK level.
  static Future<Permission> getRequiredPermission() async {
    final sdk = await getAndroidSdkInt();
    return (sdk >= 33) ? Permission.audio : Permission.storage;
  }

  /// Checks whether storage access permission is granted without prompting.
  static Future<bool> hasStoragePermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    final permission = await getRequiredPermission();
    final status = await permission.status;
    return status.isGranted || status.isLimited;
  }

  /// Requests storage permission with EMUI 10 safe ordering:
  /// 1. Check current status; if granted, return true.
  /// 2. Request first! (Do not check isPermanentlyDenied before requesting).
  /// 3. If post-request status is permanently denied, optionally display rationale dialog.
  static Future<bool> ensureStoragePermission(
    BuildContext? context, {
    bool showRationaleIfDenied = true,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return true;

    final permission = await getRequiredPermission();

    // 1. Check current status
    final currentStatus = await permission.status;
    if (currentStatus.isGranted || currentStatus.isLimited) {
      return true;
    }

    // 2. Request permission directly
    final reqStatus = await permission.request();
    if (reqStatus.isGranted || reqStatus.isLimited) {
      return true;
    }

    // 3. Post-request check for permanently denied
    if (reqStatus.isPermanentlyDenied && showRationaleIfDenied && context != null && context.mounted) {
      await showPermanentlyDeniedDialog(context);
    }

    return false;
  }

  /// Displays an educational glass rationale dialog with direct App Settings CTA.
  static Future<void> showPermanentlyDeniedDialog(BuildContext context) async {
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14151B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.folder_shared_rounded, color: Colors.amberAccent, size: 24),
            SizedBox(width: 10),
            Text('Storage Access Required', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'NEXA Player requires storage permissions to index and play audio files from your internal storage and MicroSD card.\n\nPlease tap "Open Settings" and allow Storage access.',
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: const Text('Open Settings', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
