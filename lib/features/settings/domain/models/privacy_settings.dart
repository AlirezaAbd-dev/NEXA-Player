/// Immutable model representing privacy, crash logs, and diagnostics settings.
class PrivacySettings {
  const PrivacySettings({
    this.crashReporting = false,
    this.analytics = false,
  });

  final bool crashReporting;
  final bool analytics;

  PrivacySettings copyWith({
    bool? crashReporting,
    bool? analytics,
  }) {
    return PrivacySettings(
      crashReporting: crashReporting ?? this.crashReporting,
      analytics: analytics ?? this.analytics,
    );
  }

  Map<String, dynamic> toJson() => {
        'crashReporting': crashReporting,
        'analytics': analytics,
      };

  factory PrivacySettings.fromJson(Map<String, dynamic> json) =>
      PrivacySettings(
        crashReporting: json['crashReporting'] as bool? ?? false,
        analytics: json['analytics'] as bool? ?? false,
      );
}
