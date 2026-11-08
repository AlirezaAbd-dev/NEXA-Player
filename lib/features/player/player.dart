/// Player feature module for NEXA Player.
library;

export 'domain/entities/playback_state.dart';
export 'domain/services/audio_engine.dart';
export 'domain/services/playback_queue.dart';
export 'domain/services/sleep_timer_service.dart';
export 'data/services/playback_queue_impl.dart';
export 'data/services/sleep_timer_service_impl.dart';
export 'data/services/just_audio_engine.dart';
export 'data/services/nexa_audio_handler.dart';
export 'presentation/providers/player_notifier.dart';
export 'presentation/providers/player_providers.dart';
export 'presentation/screens/now_playing_screen.dart';
