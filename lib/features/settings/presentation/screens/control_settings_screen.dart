import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/shared/widgets/glass/glass_app_bar.dart';
import '../providers/settings_providers.dart';
import '../widgets/settings_tiles.dart';

/// Playback gestures, hardware buttons, and telephony control settings screen.
class ControlSettingsScreen extends ConsumerWidget {
  const ControlSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final control = ref.watch(controlSettingsProvider);
    final notifier = ref.read(controlSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        titleText: 'Playback & Controls',
      ),
      body: ListView(
        padding: nexaScrollPadding(context, horizontal: 16.0, top: 100.0),
        children: [
          // Audio Focus & Telephony
          SettingsGroupCard(
            title: 'Audio Focus & Telephony',
            children: [
              SettingsSwitchTile(
                title: 'Resume After Call',
                subtitle: 'Automatically resume playback when phone calls end',
                icon: Icons.phone_in_talk_rounded,
                iconColor: Colors.greenAccent,
                value: control.resumeAfterCall,
                onChanged: (val) =>
                    notifier.update(control.copyWith(resumeAfterCall: val)),
              ),
              SettingsSelectorTile<String>(
                title: 'Audio Focus Policy',
                subtitle: 'Response to third-party alerts and notifications',
                icon: Icons.record_voice_over_rounded,
                iconColor: Colors.cyanAccent,
                selectedValue: control.audioFocusPolicy,
                options: const {
                  'pause_short_stop_long': 'Pause Short, Stop Long Loss',
                  'ignore': 'Ignore Concurrent Notifications',
                  'pause_always': 'Always Pause on Focus Loss',
                },
                onSelected: (val) =>
                    notifier.update(control.copyWith(audioFocusPolicy: val)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Headset & Bluetooth
          SettingsGroupCard(
            title: 'Headset & Bluetooth Automations',
            children: [
              SettingsSelectorTile<String>(
                title: 'Headset Unplugged',
                subtitle: 'Action when wired headphones or AUX is removed',
                icon: Icons.headphones_outlined,
                iconColor: Colors.amberAccent,
                selectedValue: control.headsetUnpluggedAction,
                options: const {
                  'pause': 'Pause Playback',
                  'stop': 'Stop and Clear Queue',
                  'nothing': 'Do Nothing (Continue on Speaker)',
                },
                onSelected: (val) => notifier.update(
                  control.copyWith(headsetUnpluggedAction: val),
                ),
              ),
              SettingsSelectorTile<String>(
                title: 'On Headset Plugged',
                subtitle: 'Action when wired headphones are connected',
                icon: Icons.headphones_rounded,
                iconColor: Colors.amberAccent,
                selectedValue: control.headsetPluggedAction,
                options: const {
                  'play': 'Start Playing Next Track',
                  'resume': 'Resume Last Position',
                  'nothing': 'Do Nothing',
                },
                onSelected: (val) => notifier.update(
                  control.copyWith(headsetPluggedAction: val),
                ),
              ),
              SettingsSelectorTile<String>(
                title: 'On Bluetooth Connected',
                subtitle: 'Action when paired Bluetooth audio device connects',
                icon: Icons.bluetooth_connected_rounded,
                iconColor: Colors.blueAccent,
                selectedValue: control.bluetoothConnectedAction,
                options: const {
                  'play': 'Start Playing Next Track',
                  'resume': 'Resume Last Position',
                  'nothing': 'Do Nothing',
                },
                onSelected: (val) => notifier.update(
                  control.copyWith(bluetoothConnectedAction: val),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Hardware Buttons & Gestures
          SettingsGroupCard(
            title: 'Hardware Buttons & Gestures',
            children: [
              SettingsSelectorTile<String>(
                title: 'Volume Buttons Behavior',
                subtitle: 'Primary action mapped to hardware rocker keys',
                icon: Icons.volume_up_rounded,
                iconColor: Colors.orangeAccent,
                selectedValue: control.volumeButtonsAction,
                options: const {
                  'volume': 'Standard Volume Steps',
                  'track_skip': 'Track Skip on Long Press',
                  'fast_forward': 'Fast Forward / Rewind',
                },
                onSelected: (val) => notifier.update(
                  control.copyWith(volumeButtonsAction: val),
                ),
              ),
              SettingsSwitchTile(
                title: 'Pause on Zero Volume',
                subtitle: 'Auto-pause playback when hardware volume reaches 0',
                icon: Icons.volume_off_rounded,
                iconColor: Colors.redAccent,
                value: control.pauseOnZeroVolume,
                onChanged: (val) =>
                    notifier.update(control.copyWith(pauseOnZeroVolume: val)),
              ),
              SettingsSwitchTile(
                title: 'Shake For Next Track',
                subtitle: 'Advance to the next track on physical phone shake',
                icon: Icons.vibration_rounded,
                iconColor: Colors.purpleAccent,
                value: control.shakeForNextTrack,
                onChanged: (val) =>
                    notifier.update(control.copyWith(shakeForNextTrack: val)),
              ),
              if (control.shakeForNextTrack)
                SettingsSelectorTile<String>(
                  title: 'Shake Sensitivity',
                  subtitle: 'Threshold force required to trigger advance',
                  icon: Icons.speed_rounded,
                  iconColor: Colors.purpleAccent,
                  selectedValue: control.shakeSensitivity,
                  options: const {
                    'low': 'Low (Firm Shake Required)',
                    'medium': 'Medium (Standard)',
                    'high': 'High (Light Motion)',
                  },
                  onSelected: (val) => notifier.update(
                    control.copyWith(shakeSensitivity: val),
                  ),
                ),
              SettingsSelectorTile<String>(
                title: 'Long Press Play / Pause',
                subtitle: 'Secondary action when holding the center button',
                icon: Icons.touch_app_rounded,
                iconColor: Colors.tealAccent,
                selectedValue: control.longPressPlayAction,
                options: const {
                  'stop': 'Full Stop & Rewind',
                  'sleep_timer': 'Toggle Quick Sleep Timer',
                  'nothing': 'Do Nothing',
                },
                onSelected: (val) => notifier.update(
                  control.copyWith(longPressPlayAction: val),
                ),
              ),
              SettingsSelectorTile<String>(
                title: 'Double Tap Album Art',
                subtitle: 'Quick gesture when double-tapping album cover',
                icon: Icons.double_arrow_rounded,
                iconColor: Colors.pinkAccent,
                selectedValue: control.doubleTapAction,
                options: const {
                  'next': 'Skip to Next Track',
                  'restart': 'Restart Current Track',
                  'mute': 'Toggle Mute Instant',
                },
                onSelected: (val) => notifier.update(
                  control.copyWith(doubleTapAction: val),
                ),
              ),
              SettingsSelectorTile<String>(
                title: 'Notification Swipe Action',
                subtitle: 'Interactive swipe behavior on media notification',
                icon: Icons.swipe_rounded,
                iconColor: Colors.lightBlueAccent,
                selectedValue: control.swipeNotificationAction,
                options: const {
                  'seek': 'Seek ±10 Seconds',
                  'skip': 'Skip Track',
                },
                onSelected: (val) => notifier.update(
                  control.copyWith(swipeNotificationAction: val),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Car Mode & Sleep Timer
          SettingsGroupCard(
            title: 'Driving & Night Mode',
            children: [
              SettingsSwitchTile(
                title: 'Car Mode',
                subtitle: 'Oversized touch targets and high-visibility typography',
                icon: Icons.directions_car_rounded,
                iconColor: Colors.yellowAccent,
                value: control.carMode,
                onChanged: (val) =>
                    notifier.update(control.copyWith(carMode: val)),
              ),
              SettingsSelectorTile<int>(
                title: 'Default Sleep Timer Duration',
                subtitle: 'Initial timer duration for bedtime listening',
                icon: Icons.bedtime_rounded,
                iconColor: Colors.indigoAccent,
                selectedValue: control.defaultSleepTimerMinutes,
                options: const {
                  15: '15 Minutes',
                  30: '30 Minutes',
                  45: '45 Minutes',
                  60: '1 Hour',
                  90: '1.5 Hours',
                  120: '2 Hours',
                },
                onSelected: (val) => notifier.update(
                  control.copyWith(defaultSleepTimerMinutes: val),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
