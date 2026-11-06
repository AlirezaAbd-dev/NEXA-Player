import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/glass_tokens.dart';

/// Frosted glass search and input text field with prefix/suffix icons,
/// automatic clear button, error state presentation, and focus glow styling.
class GlassTextField extends StatefulWidget {
  const GlassTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.labelText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.showClearButton = true,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.blur = GlassTokens.blurDefault,
    this.opacity = GlassTokens.opacityDefault,
    this.borderRadius,
    this.enableBlur = true,
    this.onTap,
    this.maxLines = 1,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? labelText;
  final String? errorText;

  /// Accepts either a [Widget] or an [IconData].
  final dynamic prefixIcon;

  /// Accepts either a [Widget] or an [IconData].
  final dynamic suffixIcon;

  final bool showClearButton;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final bool enableBlur;
  final VoidCallback? onTap;
  final int? maxLines;

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  late TextEditingController _effectiveController;
  late FocusNode _effectiveFocusNode;
  bool _hasText = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _effectiveController = widget.controller ?? TextEditingController();
    _effectiveFocusNode = widget.focusNode ?? FocusNode();

    _hasText = _effectiveController.text.isNotEmpty;
    _effectiveController.addListener(_onTextChanged);
    _effectiveFocusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(GlassTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) {
        _effectiveController.dispose();
      } else {
        oldWidget.controller!.removeListener(_onTextChanged);
      }
      _effectiveController = widget.controller ?? TextEditingController();
      _effectiveController.addListener(_onTextChanged);
      _hasText = _effectiveController.text.isNotEmpty;
    }

    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) {
        _effectiveFocusNode.dispose();
      } else {
        oldWidget.focusNode!.removeListener(_onFocusChanged);
      }
      _effectiveFocusNode = widget.focusNode ?? FocusNode();
      _effectiveFocusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_onTextChanged);
    _effectiveFocusNode.removeListener(_onFocusChanged);
    if (widget.controller == null) {
      _effectiveController.dispose();
    }
    if (widget.focusNode == null) {
      _effectiveFocusNode.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _effectiveController.text.isNotEmpty;
    if (_hasText != hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _onFocusChanged() {
    if (_isFocused != _effectiveFocusNode.hasFocus) {
      setState(() => _isFocused = _effectiveFocusNode.hasFocus);
    }
  }

  void _handleClear() {
    _effectiveController.clear();
    widget.onChanged?.call('');
  }

  Widget? _resolveIcon(dynamic iconDataOrWidget, Color color) {
    if (iconDataOrWidget == null) return null;
    if (iconDataOrWidget is IconData) {
      return Icon(iconDataOrWidget, size: 20.0, color: color);
    }
    if (iconDataOrWidget is Widget) {
      return IconTheme(
        data: IconThemeData(size: 20.0, color: color),
        child: iconDataOrWidget,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final errorColor = theme.colorScheme.error;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    final resolvedRadius = widget.borderRadius ??
        BorderRadius.circular(GlassTokens.radiusMedium);

    Color borderColor;
    List<BoxShadow> shadows = const [];

    if (hasError) {
      borderColor = errorColor;
      shadows = [
        BoxShadow(
          color: errorColor.withOpacity(0.20),
          blurRadius: 12.0,
          spreadRadius: 1.0,
        ),
      ];
    } else if (_isFocused) {
      borderColor = primary;
      shadows = [
        BoxShadow(
          color: primary.withOpacity(0.20),
          blurRadius: 12.0,
          spreadRadius: 1.0,
        ),
      ];
    } else {
      borderColor = isDark ? GlassTokens.borderColorLight : GlassTokens.borderColorDark;
      shadows = GlassTokens.elevationLow;
    }

    final double surfaceAlpha = _isFocused
        ? (widget.opacity + 0.05).clamp(0.0, 1.0)
        : widget.opacity;

    final iconColor = _isFocused
        ? primary
        : theme.colorScheme.onSurfaceVariant.withOpacity(0.7);

    final resolvedPrefix = _resolveIcon(widget.prefixIcon, iconColor);
    final resolvedSuffix = _resolveIcon(widget.suffixIcon, iconColor);

    Widget suffixWidget;
    if (widget.showClearButton && _hasText && widget.enabled && !widget.readOnly) {
      suffixWidget = IconButton(
        icon: const Icon(Icons.close_rounded, size: 18.0),
        onPressed: _handleClear,
        splashRadius: 20.0,
        tooltip: 'Clear text',
      );
    } else if (resolvedSuffix != null) {
      suffixWidget = resolvedSuffix;
    } else {
      suffixWidget = const SizedBox.shrink();
    }

    Widget inputContainer = Container(
      decoration: BoxDecoration(
        color: surface.withOpacity(surfaceAlpha),
        borderRadius: resolvedRadius,
        border: Border.all(
          color: borderColor,
          width: _isFocused || hasError ? GlassTokens.borderThick : GlassTokens.borderWidth,
        ),
        boxShadow: shadows,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          if (resolvedPrefix != null) ...[
            resolvedPrefix,
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(
            child: TextField(
              controller: _effectiveController,
              focusNode: _effectiveFocusNode,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              enabled: widget.enabled,
              readOnly: widget.readOnly,
              autofocus: widget.autofocus,
              onTap: widget.onTap,
              maxLines: widget.maxLines,
              style: AppTypography.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: widget.hintText,
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14.0,
                ),
              ),
            ),
          ),
          suffixWidget,
        ],
      ),
    );

    if (widget.enableBlur) {
      inputContainer = ClipRRect(
        borderRadius: resolvedRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.blur,
            sigmaY: widget.blur,
          ),
          child: inputContainer,
        ),
      );
    } else {
      inputContainer = ClipRRect(
        borderRadius: resolvedRadius,
        child: inputContainer,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
            child: Text(
              widget.labelText!,
              style: AppTypography.labelMedium.copyWith(
                color: hasError
                    ? errorColor
                    : (_isFocused ? primary : theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        ],
        inputContainer,
        if (hasError) ...[
          Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 4.0),
            child: Text(
              widget.errorText!,
              style: AppTypography.bodySmall.copyWith(color: errorColor),
            ),
          ),
        ],
      ],
    );
  }
}
