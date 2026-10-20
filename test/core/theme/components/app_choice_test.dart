import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixvia/core/theme/components/app_choice.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('AppChoice states', () {
    testWidgets('tap fires and label shows', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        themeHarness(
          AppChoice(
            label: 'AC Repair',
            selected: false,
            onTap: () => tapped++,
            testId: 'choice-ac',
          ),
        ),
      );
      expect(find.text('AC Repair'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      await tester.tap(find.byKey(const Key('choice-ac')));
      await tester.pump();
      expect(tapped, 1);
    });

    testWidgets('selected grows a check and keeps the tap', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        themeHarness(
          AppChoice(
            label: 'AC Repair',
            selected: true,
            onTap: () => tapped++,
            testId: 'choice-ac',
          ),
        ),
      );
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      await tester.tap(find.byKey(const Key('choice-ac')));
      await tester.pump();
      expect(tapped, 1);
    });

    testWidgets('optional icon renders', (tester) async {
      await tester.pumpWidget(
        themeHarness(
          AppChoice(
            label: 'Labeled',
            selected: false,
            onTap: () {},
            testId: 'choice-icon',
            icon: Icons.star,
          ),
        ),
      );
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });

  group('AppChoice hover', () {
    testWidgets('hover enter and exit do not break taps', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        themeHarness(
          AppChoice(
            label: 'Hov',
            selected: false,
            onTap: () => tapped++,
            testId: 'choice-hov',
          ),
        ),
      );
      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(
        tester.getCenter(find.byKey(const Key('choice-hov'))),
      );
      await tester.pump();
      await gesture.moveTo(Offset.zero);
      await tester.pump();
      await tester.tap(find.byKey(const Key('choice-hov')));
      await tester.pump();
      expect(tapped, 1);
    });
  });

  group('AppChoice dark mode', () {
    testWidgets('selected and plain build under dark', (tester) async {
      await tester.pumpWidget(
        themeHarness(
          Column(
            children: [
              AppChoice(
                label: 'A',
                selected: true,
                onTap: () {},
                testId: 'choice-a',
              ),
              AppChoice(
                label: 'B',
                selected: false,
                onTap: () {},
                testId: 'choice-b',
              ),
            ],
          ),
          dark: true,
        ),
      );
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });
  });
}
