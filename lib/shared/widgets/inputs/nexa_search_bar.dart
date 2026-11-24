import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/core/utils/tag_encoding_decoder.dart';
import 'package:nexa_player/shared/widgets/surfaces/nexa_surface.dart';

/// Shared borderless tonal search pill that adapts cleanly to live theme
/// switches without Material `InputDecorationTheme` inner-rectangle bleed.
class NexaSearchBar extends StatefulWidget {
  const NexaSearchBar({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.autofocus = false,
    this.borderRadius = 24.0,
    this.trailingActions = const [],
    this.showClearButton = true,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool autofocus;
  final double borderRadius;
  final List<Widget> trailingActions;
  final bool showClearButton;

  @override
  State<NexaSearchBar> createState() => _NexaSearchBarState();
}

class _NexaSearchBarState extends State<NexaSearchBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _hasText = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _hasText = _controller.text.isNotEmpty;
    _isFocused = _focusNode.hasFocus;
    _controller.addListener(_handleTextChanged);
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(NexaSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) {
        _controller.dispose();
      } else {
        oldWidget.controller!.removeListener(_handleTextChanged);
      }
      _controller = widget.controller ?? TextEditingController();
      _hasText = _controller.text.isNotEmpty;
      _controller.addListener(_handleTextChanged);
    }
    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      } else {
        oldWidget.focusNode!.removeListener(_handleFocusChanged);
      }
      _focusNode = widget.focusNode ?? FocusNode();
      _isFocused = _focusNode.hasFocus;
      _focusNode.addListener(_handleFocusChanged);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_handleTextChanged);
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_handleFocusChanged);
    }
    super.dispose();
  }

  void _handleTextChanged() {
    final nextHasText = _controller.text.isNotEmpty;
    if (nextHasText != _hasText && mounted) {
      setState(() => _hasText = nextHasText);
    } else if (mounted) {
      setState(() {});
    }
  }

  void _handleFocusChanged() {
    if (_focusNode.hasFocus != _isFocused && mounted) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  void _handleClear() {
    HapticFeedback.selectionClick();
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceTokens = NexaSurfaceTokens.of(context);
    final radius = BorderRadius.circular(widget.borderRadius);
    final textDirection =
        TagEncodingDecoder.detectBidiDirection(_controller.text);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    final iconColor =
        _isFocused ? colorScheme.primary : colorScheme.onSurfaceVariant;
    final hintColor = colorScheme.onSurfaceVariant.withOpacity(0.75);

    return ClipRRect(
      borderRadius: radius,
      child: NexaSurface(
        level: NexaSurfaceLevel.l1,
        borderRadius: radius,
        child: AnimatedContainer(
          duration: disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _isFocused
                ? Color.alphaBlend(
                    colorScheme.primary.withOpacity(0.06),
                    surfaceTokens.level1,
                  )
                : surfaceTokens.level1,
            borderRadius: radius,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md - 2,
            vertical: 2.0,
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: 20,
                color: iconColor,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: widget.autofocus,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  onTap: widget.onTap,
                  textDirection: textDirection,
                  cursorColor: colorScheme.primary,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontFamilyFallback: AppTypography.persianFontFallback,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    hintText: widget.hintText,
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: hintColor,
                      fontFamilyFallback: AppTypography.persianFontFallback,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                ),
              ),
              if (widget.showClearButton && _hasText)
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18.0,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  tooltip: 'Clear text',
                  onPressed: _handleClear,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 34,
                    minHeight: 34,
                  ),
                ),
              ...widget.trailingActions,
            ],
          ),
        ),
      ),
    );
  }
}
