import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/shared/models/track.dart';
import '../models/editable_track_metadata.dart';

/// Contract for updating ID3 audio metadata and synchronizing with the database.
abstract interface class ITagEditorService {
  /// Updates the metadata for [trackId] in SQLite database and ID3 file tags.
  Future<Result<Track, Failure>> updateTrackMetadata(
    String trackId,
    EditableTrackMetadata metadata,
  );
}
