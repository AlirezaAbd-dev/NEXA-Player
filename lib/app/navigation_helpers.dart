import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pushes a full-screen detail route using [GoRouter] when available in the
/// widget tree, falling back to the root [Navigator] in isolated widget tests.
Future<T?> pushDetailScreen<T>(
  BuildContext context, {
  required String route,
  required Object extra,
  required WidgetBuilder fallbackBuilder,
}) {
  if (GoRouter.maybeOf(context) != null) {
    return context.push<T>(route, extra: extra);
  }
  return Navigator.of(context, rootNavigator: true).push<T>(
    MaterialPageRoute<T>(builder: fallbackBuilder),
  );
}
