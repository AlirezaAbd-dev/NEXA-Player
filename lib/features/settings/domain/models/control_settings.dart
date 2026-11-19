/// Immutable model representing gestures, buttons, and system integration controls.
class ControlSettings {
  const ControlSettings({
    this.resumeAfterCall = true,
    this.audioFocusPolicy = 'pause_short_stop_long', // pause_short_stop_long, ignore, pause_always
    this.headsetUnpluggedAction = 'pause', // pause, stop, nothing
    this.headsetPluggedAction = 'resume', // play, resume, nothing
    this.bluetoothConnectedAction = 'resume', // play, resume, nothing
    this.volumeButtonsAction = 'volume', // volume, track_skip, fast_forward
    this.pauseOnZeroVolume = true,
    this.shakeForNextTrack = false,
    this.shakeSensitivity = 'medium', // low, medium, high
    this.longPressPlayAction = 'sleep_timer', // stop, sleep_timer, nothing
    this.doubleTapAction = 'next', // next, restart, mute
    this.swipeNotificationAction = 'skip', // seek, skip
    this.carMode = false,
    this.defaultSleepTimerMinutes = 30,
  });

  final bool resumeAfterCall;
  final String audioFocusPolicy;
  final String headsetUnpluggedAction;
  final String headsetPluggedAction;
  final String bluetoothConnectedAction;
  final String volumeButtonsAction;
  final bool pauseOnZeroVolume;
  final bool shakeForNextTrack;
  final String shakeSensitivity;
  final String longPressPlayAction;
  final String doubleTapAction;
  final String swipeNotificationAction;
  final bool carMode;
  final int defaultSleepTimerMinutes;

  ControlSettings copyWith({
    bool? resumeAfterCall,
    String? audioFocusPolicy,
    String? headsetUnpluggedAction,
    String? headsetPluggedAction,
    String? bluetoothConnectedAction,
    String? volumeButtonsAction,
    bool? pauseOnZeroVolume,
    bool? shakeForNextTrack,
    String? shakeSensitivity,
    String? longPressPlayAction,
    String? doubleTapAction,
    String? swipeNotificationAction,
    bool? carMode,
    int? defaultSleepTimerMinutes,
  }) {
    return ControlSettings(
      resumeAfterCall: resumeAfterCall ?? this.resumeAfterCall,
      audioFocusPolicy: audioFocusPolicy ?? this.audioFocusPolicy,
      headsetUnpluggedAction:
          headsetUnpluggedAction ?? this.headsetUnpluggedAction,
      headsetPluggedAction: headsetPluggedAction ?? this.headsetPluggedAction,
      bluetoothConnectedAction:
          bluetoothConnectedAction ?? this.bluetoothConnectedAction,
      volumeButtonsAction: volumeButtonsAction ?? this.volumeButtonsAction,
      pauseOnZeroVolume: pauseOnZeroVolume ?? this.pauseOnZeroVolume,
      shakeForNextTrack: shakeForNextTrack ?? this.shakeForNextTrack,
      shakeSensitivity: shakeSensitivity ?? this.shakeSensitivity,
      longPressPlayAction: longPressPlayAction ?? this.longPressPlayAction,
      doubleTapAction: doubleTapAction ?? this.doubleTapAction,
      swipeNotificationAction:
          swipeNotificationAction ?? this.swipeNotificationAction,
      carMode: carMode ?? this.carMode,
      defaultSleepTimerMinutes:
          defaultSleepTimerMinutes ?? this.defaultSleepTimerMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'resumeAfterCall': resumeAfterCall,
        'audioFocusPolicy': audioFocusPolicy,
        'headsetUnpluggedAction': headsetUnpluggedAction,
        'headsetPluggedAction': headsetPluggedAction,
        'bluetoothConnectedAction': bluetoothConnectedAction,
        'volumeButtonsAction': volumeButtonsAction,
        'pauseOnZeroVolume': pauseOnZeroVolume,
        'shakeForNextTrack': shakeForNextTrack,
        'shakeSensitivity': shakeSensitivity,
        'longPressPlayAction': longPressPlayAction,
        'doubleTapAction': doubleTapAction,
        'swipeNotificationAction': swipeNotificationAction,
        'carMode': carMode,
        'defaultSleepTimerMinutes': defaultSleepTimerMinutes,
      };

  factory ControlSettings.fromJson(Map<String, dynamic> json) =>
      ControlSettings(
        resumeAfterCall: json['resumeAfterCall'] as bool? ?? true,
        audioFocusPolicy:
            json['audioFocusPolicy'] as String? ?? 'pause_short_stop_long',
        headsetUnpluggedAction:
            json['headsetUnpluggedAction'] as String? ?? 'pause',
        headsetPluggedAction:
            json['headsetPluggedAction'] as String? ?? 'resume',
        bluetoothConnectedAction:
            json['bluetoothConnectedAction'] as String? ?? 'resume',
        volumeButtonsAction:
            json['volumeButtonsAction'] as String? ?? 'volume',
        pauseOnZeroVolume: json['pauseOnZeroVolume'] as bool? ?? true,
        shakeForNextTrack: json['shakeForNextTrack'] as bool? ?? false,
        shakeSensitivity: json['shakeSensitivity'] as String? ?? 'medium',
        longPressPlayAction:
            json['longPressPlayAction'] as String? ?? 'sleep_timer',
        doubleTapAction: json['doubleTapAction'] as String? ?? 'next',
        swipeNotificationAction:
            json['swipeNotificationAction'] as String? ?? 'skip',
        carMode: json['carMode'] as bool? ?? false,
        defaultSleepTimerMinutes:
            (json['defaultSleepTimerMinutes'] as num?)?.toInt() ?? 30,
      );
}
