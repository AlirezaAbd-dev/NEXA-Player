import 'package:equatable/equatable.dart';

/// Form factors available for homescreen widgets.
enum WidgetFormFactor {
  /// 4x1 horizontal bar with artwork, track info, and playback buttons.
  compact,

  /// 4x2 hero card with album sleeve, spinning vinyl, seekbar, and controls.
  heroVinyl,

  /// 2x2 square tile with full-bleed cover and circular progress.
  square,

  /// 4x3 card featuring live synced lyric lines.
  karaokeLyrics,
}

/// User styling preferences for homescreen and lockscreen widgets.
class WidgetConfig extends Equatable {
  const WidgetConfig({
    this.backgroundOpacity = 0.85,
    this.cornerRadius = 24.0,
    this.showGlow = true,
    this.showVinyl = true,
    this.adaptiveColors = true,
  });

  final double backgroundOpacity;
  final double cornerRadius;
  final bool showGlow;
  final bool showVinyl;
  final bool adaptiveColors;

  WidgetConfig copyWith({
    double? backgroundOpacity,
    double? cornerRadius,
    bool? showGlow,
    bool? showVinyl,
    bool? adaptiveColors,
  }) {
    return WidgetConfig(
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      showGlow: showGlow ?? this.showGlow,
      showVinyl: showVinyl ?? this.showVinyl,
      adaptiveColors: adaptiveColors ?? this.adaptiveColors,
    );
  }

  @override
  List<Object?> get props => [
        backgroundOpacity,
        cornerRadius,
        showGlow,
        showVinyl,
        adaptiveColors,
      ];
}
