import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/shared/widgets/glass/glass_app_bar.dart';
import '../providers/settings_providers.dart';
import '../widgets/settings_tiles.dart';

/// Status bar media notification, lock screen, and automotive integration screen.
class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notif = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        titleText: 'Notifications & Widgets',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 100.0, 16.0, 130.0),
        children: [
          // Media Notification
          SettingsGroupCard(
            title: 'Media Notification Bar',
            children: [
              SettingsSwitchTile(
                title: 'Show Playback Notification',
                subtitle: 'Persistent Android media style notification with transport controls',
                icon: Icons.notifications_active_rounded,
                iconColor: Colors.blueAccent,
                value: notif.showPlaybackNotification,
                onChanged: (val) => notifier.update(
                  notif.copyWith(showPlaybackNotification: val),
                ),
              ),
              SettingsSelectorTile<String>(
                title: 'Action Buttons Layout',
                subtitle: 'Configured media button action slots',
                icon: Icons.smart_button_rounded,
                iconColor: Colors.cyanAccent,
                selectedValue: notif.notificationActions.length > 3
                    ? 'extended'
                    : 'compact',
                options: const {
                  'compact': 'Compact (3 slots: Prev, Play/Pause, Next)',
                  'extended': 'Extended (5 slots: Prev, Play/Pause, Next, Favorite, Seek)',
                },
                onSelected: (val) {
                  if (val == 'compact') {
                    notifier.update(
                      notif.copyWith(
                        notificationActions: ['previous', 'play_pause', 'next'],
                      ),
                    );
                  } else {
                    notifier.update(
                      notif.copyWith(
                        notificationActions: [
                          'previous',
                          'play_pause',
                          'next',
                          'favorite',
                          'seek',
                        ],
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Home Screen Widgets
          SettingsGroupCard(
            title: 'Home Screen Widgets',
            children: [
              SettingsSelectorTile<String>(
                title: 'Default Widget Layout',
                subtitle: 'Aspect ratio and information density for Android desktop widget',
                icon: Icons.widgets_rounded,
                iconColor: Colors.purpleAccent,
                selectedValue: notif.widgetFormat,
                options: const {
                  '2x2': 'Compact Tile (2×2 Artwork & Play)',
                  '4x1': 'Horizontal Bar (4×1 Slim Transport)',
                  '4x2': 'Full Canvas (4×2 Artwork + Seek + Waveform)',
                },
                onSelected: (val) =>
                    notifier.update(notif.copyWith(widgetFormat: val)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Connected Ecosystem
          SettingsGroupCard(
            title: 'Connected Ecosystem',
            children: [
              SettingsSwitchTile(
                title: 'Android Auto & CarPlay',
                subtitle: 'Browse library and control playback on dashboard displays',
                icon: Icons.directions_car_filled_rounded,
                iconColor: Colors.amberAccent,
                value: notif.androidAuto,
                onChanged: (val) =>
                    notifier.update(notif.copyWith(androidAuto: val)),
              ),
              SettingsSwitchTile(
                title: 'Wear OS Smartwatch Sync',
                subtitle: 'Sync queue and remote playback commands to wearable watch',
                icon: Icons.watch_rounded,
                iconColor: Colors.pinkAccent,
                value: notif.wearOs,
                onChanged: (val) =>
                    notifier.update(notif.copyWith(wearOs: val)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
