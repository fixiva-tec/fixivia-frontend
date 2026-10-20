import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixvia/core/theme/components/app_select.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  const items = [
    AppSelectItem<String>(value: 'a', label: 'Alpha'),
    AppSelectItem<String>(value: 'b', label: 'Beta'),
  ];

  Widget select({ValueChanged<String?>? onChanged, String? initialValue}) {
    return AppSelect<String>(
      testId: 'sel-1',
      label: 'Pick one',
      placeholder: 'Choose…',
      items: items,
      initialValue: initialValue,
      onChanged: onChanged,
      selectedOptionBuilder: (context, value) => Text('picked:$value'),
    );
  }

  group('AppSelect display', () {
    testWidgets('label, placeholder, and initial value render', (tester) async {
      await tester.pumpWidget(themeHarness(select(initialValue: 'a')));
      expect(find.text('Pick one'), findsOneWidget);
      expect(find.text('picked:a'), findsOneWidget);
    });

    testWidgets('selectedOptionBuilder runs per item', (tester) async {
      var built = 0;
      await tester.pumpWidget(
        themeHarness(
          AppSelect<String>(
            testId: 'sel-2',
            items: items,
            onChanged: (_) {},
            selectedOptionBuilder: (context, value) {
              built++;
              return Text(value);
            },
          ),
        ),
      );
      expect(built, items.length);
    });
  });

  group('AppSelect interaction', () {
    testWidgets('choosing an item fires onChanged with its value',
        (tester) async {
      String? picked;
      await tester.pumpWidget(
        themeHarness(select(onChanged: (v) => picked = v)),
      );
      await tester.tap(find.byKey(const Key('sel-1')));
      await tester.pumpAndSettle();
      expect(find.text('Alpha'), findsOneWidget);
      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();
      expect(picked, 'b');
    });

    testWidgets('null onChanged disables the dropdown', (tester) async {
      await tester.pumpWidget(themeHarness(select()));
      await tester.tap(find.byKey(const Key('sel-1')));
      await tester.pumpAndSettle();
      // Menu never opens: only the closed field exists.
      expect(find.text('Beta'), findsNothing);
    });
  });

  group('AppSelect dark mode', () {
    testWidgets('builds under dark', (tester) async {
      await tester.pumpWidget(
        themeHarness(select(initialValue: 'b'), dark: true),
      );
      expect(find.text('picked:b'), findsOneWidget);
    });
  });
}
