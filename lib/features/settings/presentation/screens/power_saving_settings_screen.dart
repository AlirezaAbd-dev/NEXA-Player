import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/shared/widgets/glass/glass_app_bar.dart';
import '../providers/settings_providers.dart';
import '../widgets/settings_tiles.dart';

/// Battery preservation, wake locks, and service background lifetime screen.
class PowerSavingSettingsScreen extends ConsumerWidget {
  const PowerSavingSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final power = ref.watch(powerSavingSettingsProvider);
    final notifier = ref.read(powerSavingSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        titleText: 'Power Saving',
      ),
      body: ListView(
        padding: nexaScrollPadding(context, horizontal: 16.0, top: 100.0),
        children: [
          // Battery Profiles
          SettingsGroupCard(
            title: 'Battery Profiles & Performance',
            children: [
              SettingsSelectorTile<String>(
                title: 'Power Saving Mode',
                subtitle: 'Throttle high-framerate visuals when battery drops',
                icon: Icons.battery_charging_full_rounded,
                iconColor: Colors.lightGreenAccent,
                selectedValue: power.powerSavingMode,
                options: const {
                  'auto': 'Automatic (Trigger on Low Battery)',
                  'on': 'Always Active (Maximum Efficiency)',
                  'off': 'Disabled (Uncapped 120Hz Animations)',
                },
                onSelected: (val) =>
                    notifier.update(power.copyWith(powerSavingMode: val)),
              ),
              SettingsSwitchTile(
                title: 'Reduce Animations in Power Save',
                subtitle: 'Pause live spectrum analyzer and glow shaders during battery save',
                icon: Icons.motion_photos_off_rounded,
                iconColor: Colors.amberAccent,
                value: power.reduceAnimations,
                onChanged: (val) =>
                    notifier.update(power.copyWith(reduceAnimations: val)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Thresholds & Automations
          SettingsGroupCard(
            title: 'Automated Protection',
            children: [
              SettingsSwitchTile(
                title: 'Pause on Low Battery',
                subtitle: 'Halt audio playback if device battery drops below threshold',
                icon: Icons.battery_alert_rounded,
                iconColor: Colors.redAccent,
                value: power.pauseOnLowBattery,
                onChanged: (val) =>
                    notifier.update(power.copyWith(pauseOnLowBattery: val)),
              ),
              if (power.pauseOnLowBattery)
                SettingsSliderTile(
                  title: 'Low Battery Cutoff Limit',
                  subtitle: 'Threshold percentage for automatic pause',
                  icon: Icons.power_rounded,
                  iconColor: Colors.redAccent,
                  value: power.lowBatteryThresholdPercent.toDouble(),
                  min: 5,
                  max: 25,
                  divisions: 4,
                  valueLabel: '${power.lowBatteryThresholdPercent}%',
                  onChanged: (val) => notifier.update(
                    power.copyWith(lowBatteryThresholdPercent: val.round()),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Process & Kernel Lifetime
          SettingsGroupCard(
            title: 'Kernel & Process Management',
            children: [
              SettingsSwitchTile(
                title: 'CPU Wake Lock',
                subtitle: 'Prevent Android CPU from entering deep sleep during playback',
                icon: Icons.lock_clock_rounded,
                iconColor: Colors.cyanAccent,
                value: power.wakeLock,
                onChanged: (val) =>
                    notifier.update(power.copyWith(wakeLock: val)),
              ),
              SettingsSwitchTile(
                title: 'Stop Service When Minimized',
                subtitle: 'Aggressively release background media session when app is closed',
                icon: Icons.power_settings_new_rounded,
                iconColor: Colors.purpleAccent,
                value: power.stopServiceWhenMinimized,
                onChanged: (val) => notifier.update(
                  power.copyWith(stopServiceWhenMinimized: val),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
