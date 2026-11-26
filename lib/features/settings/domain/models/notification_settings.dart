/// Immutable model representing status bar notification and widget controls.
class NotificationSettings {
  const NotificationSettings({
    this.showPlaybackNotification = true,
    this.notificationActions = const [
      'previous',
      'play_pause',
      'next',
      'favorite',
      'seek',
    ],
    this.widgetFormat = '4x1', // 2x2, 4x1, 4x2
    this.androidAuto = true,
    this.wearOs = false,
    this.lockScreenPlayer = false,
  });

  final bool showPlaybackNotification;
  final List<String> notificationActions;
  final String widgetFormat;
  final bool androidAuto;
  final bool wearOs;
  final bool lockScreenPlayer;

  NotificationSettings copyWith({
    bool? showPlaybackNotification,
    List<String>? notificationActions,
    String? widgetFormat,
    bool? androidAuto,
    bool? wearOs,
    bool? lockScreenPlayer,
  }) {
    return NotificationSettings(
      showPlaybackNotification:
          showPlaybackNotification ?? this.showPlaybackNotification,
      notificationActions:
          notificationActions ?? List.of(this.notificationActions),
      widgetFormat: widgetFormat ?? this.widgetFormat,
      androidAuto: androidAuto ?? this.androidAuto,
      wearOs: wearOs ?? this.wearOs,
      lockScreenPlayer: lockScreenPlayer ?? this.lockScreenPlayer,
    );
  }

  Map<String, dynamic> toJson() => {
        'showPlaybackNotification': showPlaybackNotification,
        'notificationActions': notificationActions,
        'widgetFormat': widgetFormat,
        'androidAuto': androidAuto,
        'wearOs': wearOs,
        'lockScreenPlayer': lockScreenPlayer,
      };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      NotificationSettings(
        showPlaybackNotification:
            json['showPlaybackNotification'] as bool? ?? true,
        notificationActions: (json['notificationActions'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [
              'previous',
              'play_pause',
              'next',
              'favorite',
              'seek',
            ],
        widgetFormat: json['widgetFormat'] as String? ?? '4x1',
        androidAuto: json['androidAuto'] as bool? ?? true,
        wearOs: json['wearOs'] as bool? ?? false,
        lockScreenPlayer: json['lockScreenPlayer'] as bool? ?? false,
      );
}
