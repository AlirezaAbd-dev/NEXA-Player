import 'package:equatable/equatable.dart';

/// Configuration settings for in-vehicle driving dashboard and wearable devices.
class AutoSettings extends Equatable {
  const AutoSettings({
    this.keepScreenAwake = true,
    this.largeButtons = true,
    this.bluetoothAutoLaunch = false,
    this.androidAutoEnabled = true,
    this.wearCompanionEnabled = true,
    this.seekJumpSeconds = 15,
  });

  /// Keeps the device screen continuously illuminated when Car Mode is active.
  final bool keepScreenAwake;

  /// Expands car dashboard tap targets to >= 72 dp for driving safety.
  final bool largeButtons;

  /// Automatically prompts or launches Car Mode when paired with an automotive Bluetooth device.
  final bool bluetoothAutoLaunch;

  /// Enables MediaBrowserService exposure for Android Auto and Automotive OS head units.
  final bool androidAutoEnabled;

  /// Enables smartwatch remote control synchronization.
  final bool wearCompanionEnabled;

  /// Number of seconds jumped by car rewind/forward buttons (e.g. 10s, 15s, 30s).
  final int seekJumpSeconds;

  AutoSettings copyWith({
    bool? keepScreenAwake,
    bool? largeButtons,
    bool? bluetoothAutoLaunch,
    bool? androidAutoEnabled,
    bool? wearCompanionEnabled,
    int? seekJumpSeconds,
  }) {
    return AutoSettings(
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      largeButtons: largeButtons ?? this.largeButtons,
      bluetoothAutoLaunch: bluetoothAutoLaunch ?? this.bluetoothAutoLaunch,
      androidAutoEnabled: androidAutoEnabled ?? this.androidAutoEnabled,
      wearCompanionEnabled: wearCompanionEnabled ?? this.wearCompanionEnabled,
      seekJumpSeconds: seekJumpSeconds ?? this.seekJumpSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'keepScreenAwake': keepScreenAwake,
        'largeButtons': largeButtons,
        'bluetoothAutoLaunch': bluetoothAutoLaunch,
        'androidAutoEnabled': androidAutoEnabled,
        'wearCompanionEnabled': wearCompanionEnabled,
        'seekJumpSeconds': seekJumpSeconds,
      };

  factory AutoSettings.fromJson(Map<String, dynamic> json) => AutoSettings(
        keepScreenAwake: json['keepScreenAwake'] as bool? ?? true,
        largeButtons: json['largeButtons'] as bool? ?? true,
        bluetoothAutoLaunch: json['bluetoothAutoLaunch'] as bool? ?? false,
        androidAutoEnabled: json['androidAutoEnabled'] as bool? ?? true,
        wearCompanionEnabled: json['wearCompanionEnabled'] as bool? ?? true,
        seekJumpSeconds: json['seekJumpSeconds'] as int? ?? 15,
      );

  @override
  List<Object?> get props => [
        keepScreenAwake,
        largeButtons,
        bluetoothAutoLaunch,
        androidAutoEnabled,
        wearCompanionEnabled,
        seekJumpSeconds,
      ];
}
