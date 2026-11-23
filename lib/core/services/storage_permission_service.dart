import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service managing device storage and media permissions for local music indexing.
abstract final class StoragePermissionService {
  /// Requests necessary read permissions to access local audio files.
  ///
  /// On Android 13+ (API 33+), requests [Permission.audio].
  /// On Android 12 and below, requests [Permission.storage].
  /// Returns `true` if permission is granted or limited, `false` otherwise.
  static Future<bool> requestStoragePermission() async {
    if (kIsWeb || !Platform.isAndroid) {
      return true;
    }

    try {
      // 1. Check & Request Android 13+ (READ_MEDIA_AUDIO)
      final audioStatus = await Permission.audio.status;
      if (audioStatus.isGranted || audioStatus.isLimited) {
        return true;
      }

      final audioReq = await Permission.audio.request();
      if (audioReq.isGranted || audioReq.isLimited) {
        return true;
      }

      // 2. Check & Request Android 12 and below (READ_EXTERNAL_STORAGE)
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted || storageStatus.isLimited) {
        return true;
      }

      final storageReq = await Permission.storage.request();
      if (storageReq.isGranted || storageReq.isLimited) {
        return true;
      }

      // 3. Optional fallback for devices requiring manageExternalStorage
      final manageStatus = await Permission.manageExternalStorage.status;
      if (manageStatus.isGranted) {
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('[StoragePermissionService] Error requesting permission: $e');
      return false;
    }
  }

  /// Checks whether storage permission is currently granted without prompting.
  static Future<bool> hasStoragePermission() async {
    if (kIsWeb || !Platform.isAndroid) {
      return true;
    }

    try {
      final audioGranted = await Permission.audio.isGranted || await Permission.audio.isLimited;
      if (audioGranted) return true;

      final storageGranted = await Permission.storage.isGranted || await Permission.storage.isLimited;
      if (storageGranted) return true;

      final manageGranted = await Permission.manageExternalStorage.isGranted;
      if (manageGranted) return true;

      return false;
    } catch (_) {
      return false;
    }
  }

  /// Opens application system settings so the user can manually grant permissions.
  static Future<bool> openSettings() async {
    return openAppSettings();
  }

  /// Discovers existing default audio directories on the device.
  static List<String> discoverStandardMusicDirectories() {
    if (!Platform.isAndroid) return [];

    const candidates = [
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Audio',
      '/storage/emulated/0/Recordings',
      '/sdcard/Music',
      '/sdcard/Download',
    ];

    final existing = <String>[];
    for (final path in candidates) {
      try {
        final dir = Directory(path);
        if (dir.existsSync()) {
          existing.add(path);
        }
      } catch (_) {
        // Silently skip unreadable paths
      }
    }

    return existing;
  }
}
