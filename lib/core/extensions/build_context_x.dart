import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Extension on [BuildContext] providing streamlined access to theme tokens,
/// responsive layout breakpoints, MediaQuery aspects, and navigation helpers.
extension BuildContextX on BuildContext {
  // Theme & Color Accessors
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // MediaQuery Aspect Accessors (optimized against redundant widget rebuilds)
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  EdgeInsets get padding => MediaQuery.paddingOf(this);
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);
  Orientation get orientation => MediaQuery.orientationOf(this);
  bool get isLandscape => MediaQuery.orientationOf(this) == Orientation.landscape;
  bool get isPortrait => MediaQuery.orientationOf(this) == Orientation.portrait;

  // Responsive Breakpoints (matching R2 & F1.16)
  bool get isPhone => screenWidth < AppConstants.phoneBreakpoint;
  bool get isTablet =>
      screenWidth >= AppConstants.phoneBreakpoint &&
      screenWidth <= AppConstants.tabletBreakpoint;
  bool get isDesktop => screenWidth > AppConstants.tabletBreakpoint;
  bool get isWideScreen => screenWidth >= AppConstants.phoneBreakpoint;

  // Scaffold & Feedback Helpers
  ScaffoldMessengerState get scaffoldMessenger => ScaffoldMessenger.of(this);

  void showSnackBar(SnackBar snackBar) {
    ScaffoldMessenger.of(this).showSnackBar(snackBar);
  }

  void hideCurrentSnackBar() {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
  }

  // Focus Management
  FocusScopeNode get focusScope => FocusScope.of(this);

  void unfocus() {
    final currentScope = FocusScope.of(this);
    if (!currentScope.hasPrimaryFocus && currentScope.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }
}
