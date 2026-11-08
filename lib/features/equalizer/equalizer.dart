/// Equalizer & Psychoacoustic DSP feature module for NEXA Player.
library;

// Domain Entities
export 'domain/entities/equalizer_band.dart';
export 'domain/entities/equalizer_preset.dart';
export 'domain/entities/equalizer_state.dart';
export 'domain/entities/reverb_preset.dart';

// Domain Services
export 'domain/services/equalizer_service.dart';

// Data Services
export 'data/services/pure_dart_equalizer_service.dart';

// Presentation Providers
export 'presentation/providers/equalizer_notifier.dart';
export 'presentation/providers/equalizer_providers.dart';

// Presentation Widgets
export 'presentation/widgets/dsp_knob_slider.dart';
export 'presentation/widgets/eq_band_slider.dart';
export 'presentation/widgets/eq_curve_painter.dart';
export 'presentation/widgets/preset_selector_modal.dart';
export 'presentation/widgets/reverb_selector.dart';

// Presentation Screens
export 'presentation/screens/equalizer_screen.dart';
