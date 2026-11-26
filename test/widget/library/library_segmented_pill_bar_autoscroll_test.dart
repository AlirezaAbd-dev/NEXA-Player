import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/constants/phase2_keys.dart';
import 'package:nexa_player/features/library/presentation/widgets/library_segmented_pill_bar.dart';
import 'package:nexa_player/l10n/generated/app_localizations.dart';

void main() {
  for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
    testWidgets(
      'LibrarySegmentedPillBar auto-scrolls selected Folders pill into view (${direction.name})',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(280, 120));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Directionality(
              textDirection: direction,
              child: const Scaffold(
                body: Center(
                  child: LibrarySegmentedPillBar(
                    selectedTab: LibrarySubTab.folders,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final foldersFinder = find.byKey(Phase2Keys.tabFolders);
        expect(foldersFinder, findsOneWidget);
        final rect = tester.getRect(foldersFinder);
        expect(rect.left, greaterThanOrEqualTo(0.0));
        expect(rect.right, lessThanOrEqualTo(280.0));
      },
    );
  }
}
