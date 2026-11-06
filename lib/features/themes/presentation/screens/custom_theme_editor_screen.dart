import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/custom_theme_data.dart';
import '../../../../core/theme/theme_controller.dart';
import '../widgets/hsl_color_slider.dart';

/// Semantic Keys matching test/e2e/e2e_test_helpers.dart E2EKeys.
abstract final class _Keys {
  static const Key hslHueSlider = ValueKey('hsl_hue_slider');
  static const Key hslSaturationSlider = ValueKey('hsl_saturation_slider');
  static const Key hslLightnessSlider = ValueKey('hsl_lightness_slider');
  static const Key hslSaveButton = ValueKey('hsl_save_button');
}

/// Screen providing live HSL color sliders, contrast verification, and live preview.
class CustomThemeEditorScreen extends ConsumerStatefulWidget {
  const CustomThemeEditorScreen({super.key});

  static const String routePath = '/settings/theme/custom';

  @override
  ConsumerState<CustomThemeEditorScreen> createState() =>
      _CustomThemeEditorScreenState();
}

class _CustomThemeEditorScreenState
    extends ConsumerState<CustomThemeEditorScreen> {
  late CustomThemeData _themeDraft;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final themeState = ref.read(themeControllerProvider);
      _themeDraft = themeState.customTheme ?? CustomThemeData.defaultDark;
      _initialized = true;
    }
  }

  void _onHueChanged(double value) {
    setState(() {
      _themeDraft = _themeDraft.copyWith(primaryHue: value);
    });
  }

  void _onSaturationChanged(double value) {
    setState(() {
      _themeDraft = _themeDraft.copyWith(primarySaturation: value);
    });
  }

  void _onLightnessChanged(double value) {
    setState(() {
      _themeDraft = _themeDraft.copyWith(primaryLightness: value);
    });
  }

  void _onModeToggled(bool isDark) {
    setState(() {
      _themeDraft = _themeDraft.copyWith(isDark: isDark);
    });
  }

  Future<void> _saveCustomTheme() async {
    await ref.read(themeControllerProvider.notifier).setCustomTheme(_themeDraft);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Custom theme saved!')),
      );
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewScheme = _themeDraft.toColorScheme();
    final contrastRatio = _themeDraft.accentContrastRatio;
    final isWcagPass = contrastRatio >= 4.5;

    return Theme(
      data: ThemeData(
        useMaterial3: true,
        brightness: previewScheme.brightness,
        colorScheme: previewScheme,
        scaffoldBackgroundColor: _themeDraft.scaffoldBackgroundColor,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Custom HSL Theme Editor'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Live Interactive Preview Card
              _buildLivePreviewCard(previewScheme),
              const SizedBox(height: 20),

              // 2. Contrast & Safety Indicator
              _buildContrastBadge(contrastRatio, isWcagPass),
              const SizedBox(height: 20),

              // 3. Dark/Light Mode Authoring Toggle
              _buildModeToggle(),
              const SizedBox(height: 16),

              // 4. HSL Sliders
              _buildSliderSection(),
              const SizedBox(height: 24),

              // 5. Save Button
              ElevatedButton(
                key: _Keys.hslSaveButton,
                onPressed: _saveCustomTheme,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _themeDraft.primaryColor,
                  foregroundColor: _themeDraft.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Save Custom Theme',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLivePreviewCard(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.primary.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.music_note, color: scheme.primary, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Palette Preview',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Hue: ${_themeDraft.normalizedHue.round()}° • '
                      'Sat: ${(_themeDraft.normalizedSaturation * 100).round()}% • '
                      'Light: ${(_themeDraft.clampedPrimaryLightness * 100).round()}%',
                      style: TextStyle(
                        color: scheme.onSurface.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Accent',
                  style: TextStyle(
                    color: _themeDraft.onPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: _themeDraft.onPrimary,
                ),
                child: const Text('Play Button'),
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.primary,
                  side: BorderSide(color: scheme.primary),
                ),
                child: const Text('Queue Track'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContrastBadge(double ratio, bool isPass) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isPass ? const Color(0x2200E676) : const Color(0x22FF3D00),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPass ? const Color(0xFF00E676) : const Color(0xFFFF3D00),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPass ? Icons.verified : Icons.warning_amber_rounded,
            color: isPass ? const Color(0xFF00E676) : const Color(0xFFFF3D00),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'WCAG 2.1 AA Contrast: ${ratio.toStringAsFixed(1)}:1 '
              '(${isPass ? "Passed" : "Clamped for Legibility"})',
              style: TextStyle(
                color: isPass ? const Color(0xFF00E676) : const Color(0xFFFF3D00),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Text(
            'Target Dark Surface',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Switch(
          value: _themeDraft.isDark,
          onChanged: _onModeToggled,
        ),
      ],
    );
  }

  Widget _buildSliderSection() {
    final isCompact = MediaQuery.sizeOf(context).width <= 320;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HslColorSlider(
          sliderKey: _Keys.hslHueSlider,
          label: isCompact ? 'Hue' : 'Primary Hue',
          displayValue: '${_themeDraft.normalizedHue.round()}°',
          value: _themeDraft.normalizedHue,
          min: 0.0,
          max: 360.0,
          activeColor: _themeDraft.primaryColor,
          onChanged: _onHueChanged,
        ),
        const SizedBox(height: 12),
        HslColorSlider(
          sliderKey: _Keys.hslSaturationSlider,
          label: isCompact ? 'Saturation' : 'Primary Saturation',
          displayValue:
              '${(_themeDraft.normalizedSaturation * 100).round()}%',
          value: _themeDraft.normalizedSaturation,
          min: 0.0,
          max: 1.0,
          activeColor: _themeDraft.primaryColor,
          onChanged: _onSaturationChanged,
        ),
        const SizedBox(height: 12),
        HslColorSlider(
          sliderKey: _Keys.hslLightnessSlider,
          label: isCompact ? 'Lightness' : 'Primary Lightness',
          displayValue:
              '${(_themeDraft.clampedPrimaryLightness * 100).round()}%',
          value: _themeDraft.primaryLightness.clamp(0.0, 1.0),
          min: 0.0,
          max: 1.0,
          activeColor: _themeDraft.primaryColor,
          onChanged: _onLightnessChanged,
        ),
      ],
    );
  }
}
