/// Playlists & Track Operations feature module for NEXA Player.
library;

// Domain Models
export 'domain/models/editable_track_metadata.dart';
export 'domain/models/m3u_entry.dart';
export 'domain/models/ringtone_trim_range.dart';
export 'domain/models/smart_playlist.dart';

// Domain Services & Repositories
export 'domain/repositories/playlists_repository.dart';
export 'domain/services/m3u_service.dart';
export 'domain/services/ringtone_service.dart';
export 'domain/services/share_service.dart';
export 'domain/services/tag_editor_service.dart';

// Data Implementations
export 'data/repositories/sqlite_playlists_repository.dart';
export 'data/services/m3u_service_impl.dart';
export 'data/services/ringtone_service_impl.dart';
export 'data/services/share_service_impl.dart';
export 'data/services/tag_editor_service_impl.dart';

// Presentation Providers
export 'presentation/providers/playlists_providers.dart';

// Presentation Widgets
export 'presentation/widgets/add_to_playlist_bottom_sheet.dart';
export 'presentation/widgets/m3u_import_dialog.dart';
export 'presentation/widgets/track_tag_editor_modal.dart';

// Presentation Screens
export 'presentation/screens/playlist_detail_screen.dart';
export 'presentation/screens/playlists_tab_screen.dart';
export 'presentation/screens/ringtone_trimmer_screen.dart';
