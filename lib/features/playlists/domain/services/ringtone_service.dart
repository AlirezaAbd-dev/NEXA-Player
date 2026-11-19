import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/shared/models/track.dart';
import '../models/ringtone_trim_range.dart';

/// Contract for precision trimming of audio files and exporting as ringtones, alarms, or notifications.
abstract interface class IRingtoneService {
  /// Trims an audio file to the specified [range] and saves it for [target].
  /// Returns the absolute path of the generated audio file.
  Future<Result<String, Failure>> trimAudio({
    required Track track,
    required RingtoneTrimRange range,
    required RingtoneTarget target,
  });
}
