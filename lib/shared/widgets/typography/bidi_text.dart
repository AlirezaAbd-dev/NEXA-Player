import 'package:flutter/material.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/core/utils/tag_encoding_decoder.dart';

/// Text widget with automatic Unicode Bidi first-strong direction detection
/// and Persian/Arabic font fallback so mixed RTL Persian and LTR English titles
/// (e.g. `"شادمهر عقیلی - Starboy"`) render without glyph tofu or alignment flips.
class BidiText extends StatelessWidget {
  const BidiText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.textDirection,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    final displayData = TagEncodingDecoder.repairMojibake(data);
    final effectiveDirection =
        textDirection ?? TagEncodingDecoder.detectBidiDirection(displayData);
    final effectiveStyle = (style ?? const TextStyle()).copyWith(
      fontFamilyFallback:
          style?.fontFamilyFallback ?? AppTypography.persianFontFallback,
    );

    return Text(
      displayData,
      style: effectiveStyle,
      textDirection: effectiveDirection,
      textAlign: textAlign ??
          (effectiveDirection == TextDirection.rtl
              ? TextAlign.start
              : null),
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}
