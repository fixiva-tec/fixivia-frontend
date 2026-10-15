import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixvia/core/theme/app_theme.dart';
import 'package:fixvia/core/theme/components/app_card.dart';

import '../../../helpers/test_helpers.dart';

BoxDecoration cardDeco(WidgetTester tester) {
  final containers = tester.widgetList<AnimatedContainer>(
    find.byType(AnimatedContainer),
  );
  return containers.first.decoration! as BoxDecoration;
}

void main() {
  group('AppCard content', () {
    testWidgets('title, description, child, footer render', (tester) async {
      await tester.pumpWidget(
        shadHarness(
          const AppCard(
            title: 'Title',
            description: 'Desc',
            footer: Text('Foot'),
            child: Text('Body'),
          ),
        ),
      );
      for (final s in ['Title', 'Desc', 'Body', 'Foot']) {
        expect(find.text(s), findsOneWidget);
      }
    });

    testWidgets('leading and trailing render, header hidden when all absent',
        (tester) async {
      await tester.pumpWidget(
        shadHarness(
          const AppCard(
            leading: Icon(Icons.star),
            trailing: Icon(Icons.flag),
            child: Text('Only body'),
          ),
        ),
      );
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.flag), findsOneWidget);

      await tester.pumpWidget(
        shadHarness(const AppCard(testId: 'bare', child: Text('Bare'))),
      );
      expect(find.text('Bare'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('bare')),
          matching: find.byType(Row),
        ),
        findsNothing,
      );
    });

    testWidgets('tint, gradient, and border overrides apply', (tester) async {
      await tester.pumpWidget(
        shadHarness(
          const AppCard(tint: Colors.red, child: Text('T')),
        ),
      );
      expect(cardDeco(tester).color, Colors.red);

      const grad = LinearGradient(colors: [Colors.red, Colors.blue]);
      await tester.pumpWidget(
        shadHarness(
          const AppCard(
            title: 'G',
            description: 'D',
            gradient: grad,
            borderColor: Colors.green,
          ),
        ),
      );
      final deco = cardDeco(tester);
      expect(deco.gradient, grad);
      expect(deco.color, isNull);
      expect(deco.border, isNull); // gradient drops the border
    });
  });

  group('AppCard padding', () {
    testWidgets('compact uses 16, desktop 20, override wins', (tester) async {
      compactSize(tester);
      await tester.pumpWidget(shadHarness(const AppCard(child: Text('C'))));
      expect(
        tester
            .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
            .first
            .padding,
        const EdgeInsets.all(16),
      );

      desktopSize(tester);
      await tester.pumpWidget(shadHarness(const AppCard(child: Text('C'))));
      expect(
        tester
            .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
            .first
            .padding,
        const EdgeInsets.all(20),
      );

      await tester.pumpWidget(
        shadHarness(
          const AppCard(
            padding: EdgeInsets.all(4),
            child: Text('C'),
          ),
        ),
      );
      expect(
        tester
            .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
            .first
            .padding,
        const EdgeInsets.all(4),
      );
    });
  });

  group('AppCard tap', () {
    testWidgets('onTap fires, testId keys the subtree', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        shadHarness(
          AppCard(
            testId: 'card-1',
            onTap: () => tapped++,
            child: const Text('Tap me'),
          ),
        ),
      );
      expect(find.byKey(const Key('card-1')), findsOneWidget);
      await tester.tap(find.text('Tap me'));
      await tester.pump();
      expect(tapped, 1);
    });
  });

  group('AppCard dark mode', () {
    testWidgets('builds with and without gradient', (tester) async {
      await tester.pumpWidget(
        shadHarness(
          const Column(
            children: [
              AppCard(title: 'Plain'),
              AppCard(
                title: 'Grad',
                gradient: AppColors.primaryGradient,
              ),
            ],
          ),
          dark: true,
        ),
      );
      expect(find.text('Plain'), findsOneWidget);
      expect(find.text('Grad'), findsOneWidget);
    });
  });
}
