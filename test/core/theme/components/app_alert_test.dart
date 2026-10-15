import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixvia/core/theme/components/app_alert.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('AppAlert variants', () {
    testWidgets('destructive shows error icon and title', (tester) async {
      await tester.pumpWidget(
        shadHarness(
          const AppAlert(title: 'Failed', destructive: true),
        ),
      );
      expect(find.text('Failed'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('success shows check icon', (tester) async {
      await tester.pumpWidget(
        shadHarness(
          const AppAlert(title: 'Done', success: true),
        ),
      );
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    });

    testWidgets('neutral shows info icon', (tester) async {
      await tester.pumpWidget(
        shadHarness(const AppAlert(title: 'Note')),
      );
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    });

    testWidgets('destructive wins when both flags set', (tester) async {
      await tester.pumpWidget(
        shadHarness(
          const AppAlert(title: 'X', destructive: true, success: true),
        ),
      );
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsNothing);
    });
  });

  group('AppAlert description', () {
    testWidgets('shown when provided, hidden when absent', (tester) async {
      await tester.pumpWidget(
        shadHarness(
          const AppAlert(title: 'T', description: 'Details here'),
        ),
      );
      expect(find.text('Details here'), findsOneWidget);

      await tester.pumpWidget(shadHarness(const AppAlert(title: 'T')));
      expect(find.text('T'), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
    });
  });

  group('AppAlert dark mode', () {
    testWidgets('all three variants build under dark', (tester) async {
      await tester.pumpWidget(
        shadHarness(
          const Column(
            children: [
              AppAlert(title: 'A', destructive: true),
              AppAlert(title: 'B', success: true),
              AppAlert(title: 'C'),
            ],
          ),
          dark: true,
        ),
      );
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });
  });
}
