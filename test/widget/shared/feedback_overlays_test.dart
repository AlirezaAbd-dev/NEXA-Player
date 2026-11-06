import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/shared/widgets/feedback/app_bottom_sheet.dart';
import 'package:nexa_player/shared/widgets/feedback/app_dialog.dart';
import 'package:nexa_player/shared/widgets/feedback/app_snackbar.dart';

void main() {
  group('AppSnackbar Widget Tests', () {
    testWidgets('AppSnackbar.show displays floating snackbar and triggers action callback', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      AppSnackbar.show(
                        context,
                        message: 'Track added to playlist',
                        actionLabel: 'Undo',
                        onAction: () => actionTriggered = true,
                      );
                    },
                    child: const Text('Show Snackbar'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Snackbar'));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 300)); // Finish slide-in

      expect(find.text('Track added to playlist'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pump();
      expect(actionTriggered, isTrue);
    });

    testWidgets('AppSnackbarContent renders semantic variants (success, warning, error, info)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppSnackbarContent(
                  message: 'Success Message',
                  variant: AppSnackbarVariant.success,
                ),
                AppSnackbarContent(
                  message: 'Warning Message',
                  variant: AppSnackbarVariant.warning,
                ),
                AppSnackbarContent(
                  message: 'Error Message',
                  variant: AppSnackbarVariant.error,
                ),
                AppSnackbarContent(
                  message: 'Info Message',
                  variant: AppSnackbarVariant.info,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Success Message'), findsOneWidget);
      expect(find.text('Warning Message'), findsOneWidget);
      expect(find.text('Error Message'), findsOneWidget);
      expect(find.text('Info Message'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNWidgets(4));
    });
  });

  group('AppDialog Widget Tests', () {
    testWidgets('AppDialog.show displays frosted dialog, renders title, message, and buttons', (tester) async {
      bool primaryClicked = false;
      bool secondaryClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      AppDialog.show(
                        context: context,
                        title: 'Delete Playlist?',
                        message: 'This action cannot be undone.',
                        icon: Icons.delete_outline_rounded,
                        primaryActionText: 'Delete',
                        onPrimaryAction: () {
                          primaryClicked = true;
                          Navigator.of(context).pop();
                        },
                        secondaryActionText: 'Cancel',
                        onSecondaryAction: () {
                          secondaryClicked = true;
                          Navigator.of(context).pop();
                        },
                      );
                    },
                    child: const Text('Open Dialog'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Playlist?'), findsOneWidget);
      expect(find.text('This action cannot be undone.'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Verify BackdropFilter is present in dialog route
      expect(find.byType(BackdropFilter), findsWidgets);

      // Tap Cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(secondaryClicked, isTrue);
      expect(find.text('Delete Playlist?'), findsNothing);

      // Re-open and test primary button
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(primaryClicked, isTrue);
      expect(find.text('Delete Playlist?'), findsNothing);
    });
  });

  group('AppBottomSheet Widget Tests', () {
    testWidgets('AppBottomSheet.show displays modal sheet with drag handle and title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      AppBottomSheet.show(
                        context: context,
                        title: 'Equalizer Presets',
                        child: const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Custom Preset List'),
                        ),
                      );
                    },
                    child: const Text('Open Bottom Sheet'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Bottom Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Equalizer Presets'), findsOneWidget);
      expect(find.text('Custom Preset List'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsWidgets);
    });
  });
}
