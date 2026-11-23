import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/service_providers.dart';
import '../../../../shared/services/storage/storage_service.dart';
import '../../domain/models/track_bookmark.dart';

/// Local data access object for waveform micro-bookmarks.
class TrackBookmarkDao {
  TrackBookmarkDao(this._storage);

  final IStorageService _storage;
  static const String _storagePrefix = 'track_bookmarks_';

  String _key(String trackId) => '$_storagePrefix$trackId';

  Future<List<TrackBookmark>> getBookmarks(String trackId) async {
    final raw = await _storage.getString(_key(trackId));
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => TrackBookmark.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addBookmark(TrackBookmark bookmark) async {
    final current = await getBookmarks(bookmark.trackId);
    final updated = [...current, bookmark]..sort((a, b) => a.position.compareTo(b.position));
    final encoded = jsonEncode(updated.map((b) => b.toJson()).toList());
    await _storage.setString(_key(bookmark.trackId), encoded);
  }

  Future<void> removeBookmark(String trackId, String bookmarkId) async {
    final current = await getBookmarks(trackId);
    final updated = current.where((b) => b.id != bookmarkId).toList();
    final encoded = jsonEncode(updated.map((b) => b.toJson()).toList());
    await _storage.setString(_key(trackId), encoded);
  }

  Future<void> clearBookmarks(String trackId) async {
    await _storage.remove(_key(trackId));
  }
}

/// Provider for TrackBookmarkDao.
final trackBookmarkDaoProvider = Provider<TrackBookmarkDao>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return TrackBookmarkDao(storage);
});

/// Reactive state notifier for active A-B loop range on current playback.
class ABLoopNotifier extends StateNotifier<ABLoopRange> {
  ABLoopNotifier() : super(const ABLoopRange(trackId: ''));

  void setTrack(String trackId) {
    if (state.trackId != trackId) {
      state = ABLoopRange(trackId: trackId);
    }
  }

  void setPinA(Duration position) {
    state = state.copyWith(start: position);
    _validateAndEnable();
  }

  void setPinB(Duration position) {
    state = state.copyWith(end: position);
    _validateAndEnable();
  }

  void toggleEnabled() {
    if (state.isValid) {
      state = state.copyWith(isEnabled: !state.isEnabled);
    }
  }

  void clear() {
    state = ABLoopRange(trackId: state.trackId);
  }

  void _validateAndEnable() {
    if (state.start != null && state.end != null) {
      if (state.start! >= state.end!) {
        // Swap if end is before start
        state = ABLoopRange(
          trackId: state.trackId,
          start: state.end,
          end: state.start,
          isEnabled: true,
        );
      } else {
        state = state.copyWith(isEnabled: true);
      }
    }
  }
}

final abLoopNotifierProvider =
    StateNotifierProvider<ABLoopNotifier, ABLoopRange>((ref) {
  return ABLoopNotifier();
});
