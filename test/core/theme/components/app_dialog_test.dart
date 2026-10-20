import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixvia/core/theme/components/app_dialog.dart';

import '../../../helpers/test_helpers.dart';

Future<void> openDialog(
  WidgetTester tester, {
  bool alert = false,
  bool barrierDismissible = true,
  VoidCallback? onAction,
}) async {
  late BuildContext ctx;
  await tester.pumpWidget(
    themeHarness(
      Builder(
        builder: (context) {
          ctx = context;
          return const SizedBox();
        },
      ),
    ),
  );
  AppDialog.show<void>(
    context: ctx,
    title: 'Confirm?',
    description: 'Are you sure',
    actions: [
      TextButton(onPressed: onAction ?? () {}, child: const Text('OK')),
    ],
    barrierDismissible: barrierDismissible,
    alert: alert,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AppDialog.show', () {
    testWidgets('plain mode renders title, description, and actions',
        (tester) async {
      var fired = 0;
      await openDialog(tester, onAction: () => fired++);
      expect(find.text('Confirm?'), findsOneWidget);
      expect(find.text('Are you sure'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pump();
      expect(fired, 1);
    });

    testWidgets('alert mode renders', (tester) async {
      await openDialog(tester, alert: true);
      expect(find.text('Confirm?'), findsOneWidget);
      expect(find.text('Are you sure'), findsOneWidget);
    });

    testWidgets('child renders, description optional', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        themeHarness(
          Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      );
      AppDialog.show<void>(
        context: ctx,
        title: 'Bare',
        child: const Text('Inner body'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bare'), findsOneWidget);
      expect(find.text('Inner body'), findsOneWidget);
    });

    testWidgets('barrier tap dismisses when allowed, ignored when not',
        (tester) async {
      await openDialog(tester);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Confirm?'), findsNothing);

      await openDialog(tester, barrierDismissible: false);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Confirm?'), findsOneWidget);
    });
  });
}
