/// Immutable model representing battery saving and service lifecycle policies.
class PowerSavingSettings {
  const PowerSavingSettings({
    this.powerSavingMode = 'auto', // auto, on, off
    this.reduceAnimations = false,
    this.pauseOnLowBattery = true,
    this.lowBatteryThresholdPercent = 15, // 5 to 25%
    this.stopServiceWhenMinimized = false,
    this.wakeLock = true,
  });

  final String powerSavingMode;
  final bool reduceAnimations;
  final bool pauseOnLowBattery;
  final int lowBatteryThresholdPercent;
  final bool stopServiceWhenMinimized;
  final bool wakeLock;

  PowerSavingSettings copyWith({
    String? powerSavingMode,
    bool? reduceAnimations,
    bool? pauseOnLowBattery,
    int? lowBatteryThresholdPercent,
    bool? stopServiceWhenMinimized,
    bool? wakeLock,
  }) {
    return PowerSavingSettings(
      powerSavingMode: powerSavingMode ?? this.powerSavingMode,
      reduceAnimations: reduceAnimations ?? this.reduceAnimations,
      pauseOnLowBattery: pauseOnLowBattery ?? this.pauseOnLowBattery,
      lowBatteryThresholdPercent:
          lowBatteryThresholdPercent ?? this.lowBatteryThresholdPercent,
      stopServiceWhenMinimized:
          stopServiceWhenMinimized ?? this.stopServiceWhenMinimized,
      wakeLock: wakeLock ?? this.wakeLock,
    );
  }

  Map<String, dynamic> toJson() => {
        'powerSavingMode': powerSavingMode,
        'reduceAnimations': reduceAnimations,
        'pauseOnLowBattery': pauseOnLowBattery,
        'lowBatteryThresholdPercent': lowBatteryThresholdPercent,
        'stopServiceWhenMinimized': stopServiceWhenMinimized,
        'wakeLock': wakeLock,
      };

  factory PowerSavingSettings.fromJson(Map<String, dynamic> json) =>
      PowerSavingSettings(
        powerSavingMode: json['powerSavingMode'] as String? ?? 'auto',
        reduceAnimations: json['reduceAnimations'] as bool? ?? false,
        pauseOnLowBattery: json['pauseOnLowBattery'] as bool? ?? true,
        lowBatteryThresholdPercent:
            (json['lowBatteryThresholdPercent'] as num?)?.toInt() ?? 15,
        stopServiceWhenMinimized:
            json['stopServiceWhenMinimized'] as bool? ?? false,
        wakeLock: json['wakeLock'] as bool? ?? true,
      );
}
