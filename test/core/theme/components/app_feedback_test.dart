import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixvia/core/theme/components/app_feedback.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('EmptyState', () {
    testWidgets('full variant renders tile, title, hint, and action',
        (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        shadHarness(
          EmptyState(
            title: 'Nothing here',
            hint: 'Try again later',
            action: TextButton(
              onPressed: () => tapped++,
              child: const Text('Retry'),
            ),
          ),
        ),
      );
      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('Try again later'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(tapped, 1);
    });

    testWidgets('minimal variant omits hint and action', (tester) async {
      await tester.pumpWidget(
        shadHarness(
          const EmptyState(title: 'Empty', icon: Icons.star),
        ),
      );
      expect(find.text('Empty'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
    });
  });

  group('LoadingSkeleton', () {
    testWidgets('default renders three rows of bars', (tester) async {
      await tester.pumpWidget(shadHarness(const LoadingSkeleton()));
      await tester.pump(const Duration(milliseconds: 100));
      // Two bars per row.
      expect(find.byType(FractionallySizedBox), findsNWidgets(6));
    });

    testWidgets('row count scales, zero renders empty', (tester) async {
      await tester.pumpWidget(shadHarness(const LoadingSkeleton(rows: 2)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(FractionallySizedBox), findsNWidgets(4));

      await tester.pumpWidget(shadHarness(const LoadingSkeleton(rows: 0)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(FractionallySizedBox), findsNothing);
    });

    testWidgets('animation ticks without errors, dark builds', (tester) async {
      await tester.pumpWidget(shadHarness(const LoadingSkeleton()));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(FractionallySizedBox), findsNWidgets(6));

      await tester.pumpWidget(
        shadHarness(const LoadingSkeleton(rows: 1), dark: true),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(FractionallySizedBox), findsNWidgets(2));
    });
  });

  group('SectionHeader', () {
    testWidgets('title alone shows no action', (tester) async {
      await tester.pumpWidget(
        shadHarness(const SectionHeader(title: 'Jobs')),
      );
      expect(find.text('Jobs'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    });

    testWidgets('action needs both label and handler', (tester) async {
      await tester.pumpWidget(
        shadHarness(
          SectionHeader(title: 'A', actionLabel: 'More', onAction: () {}),
        ),
      );
      expect(find.text('More'), findsOneWidget);

      await tester.pumpWidget(
        shadHarness(
          const SectionHeader(title: 'B', actionLabel: 'More'),
        ),
      );
      expect(find.text('More'), findsNothing);

      await tester.pumpWidget(
        shadHarness(SectionHeader(title: 'C', onAction: () {})),
      );
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    });

    testWidgets('action tap fires and honors its test id', (tester) async {
      var fired = 0;
      await tester.pumpWidget(
        shadHarness(
          SectionHeader(
            title: 'Jobs',
            actionLabel: 'View all',
            actionTestId: 'jobs-all',
            onAction: () => fired++,
          ),
        ),
      );
      expect(find.byKey(const Key('jobs-all')), findsOneWidget);
      await tester.tap(find.text('View all'));
      await tester.pump();
      expect(fired, 1);
    });
  });
}
