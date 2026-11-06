import 'package:flutter/material.dart';

/// Centralized 8-step spacing scale tokens for consistent margins, paddings, and gaps.
///
/// Follows the standard 4, 8, 12, 16, 24, 32, 48, 64 dp hierarchy.
abstract final class AppSpacing {
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // Semantic t-shirt size aliases
  static const double xxxs = space2;
  static const double xxs = space4;
  static const double xs = space8;
  static const double sm = space12;
  static const double md = space16;
  static const double lg = space24;
  static const double xl = space32;
  static const double xxl = space48;
  static const double xxxl = space64;

  // Square Gap Widgets (zero magic number layout spacing)
  static const SizedBox gap2 = SizedBox.square(dimension: space2);
  static const SizedBox gap4 = SizedBox.square(dimension: space4);
  static const SizedBox gap8 = SizedBox.square(dimension: space8);
  static const SizedBox gap12 = SizedBox.square(dimension: space12);
  static const SizedBox gap16 = SizedBox.square(dimension: space16);
  static const SizedBox gap24 = SizedBox.square(dimension: space24);
  static const SizedBox gap32 = SizedBox.square(dimension: space32);
  static const SizedBox gap48 = SizedBox.square(dimension: space48);
  static const SizedBox gap64 = SizedBox.square(dimension: space64);

  // Directional Gap Builders
  static SizedBox horizontal(double width) => SizedBox(width: width);
  static SizedBox vertical(double height) => SizedBox(height: height);

  // Screen & Container Standard Insets
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets screenPaddingWithNav = EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPaddingDense = EdgeInsets.all(12.0);
  static const EdgeInsets dialogPadding = EdgeInsets.all(24.0);
  static const EdgeInsets bottomSheetPadding = EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0);
}
