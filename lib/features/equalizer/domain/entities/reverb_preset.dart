/// Supported psychoacoustic reverb simulation environments.
enum ReverbPreset {
  none('None', 'Direct signal with no acoustic reflection'),
  room('Small Room', 'Subtle reflections typical of an intimate listening space'),
  hall('Concert Hall', 'Lush, expansive reverberation for orchestral and live tracks'),
  plate('Plate Reverb', 'Classic bright, smooth metallic reflections'),
  studio('Studio', 'Controlled, warm damping suited for modern pop and rock'),
  liveArena('Live Arena', 'Deep, dramatic multi-echo space for stadium sound');

  const ReverbPreset(this.label, this.description);

  final String label;
  final String description;

  /// Serialization helper.
  String toJson() => name;

  /// Deserialization helper with fallback to [none].
  static ReverbPreset fromJson(String? name) {
    if (name == null) return ReverbPreset.none;
    return ReverbPreset.values.firstWhere(
      (element) => element.name.toLowerCase() == name.toLowerCase(),
      orElse: () => ReverbPreset.none,
    );
  }
}
