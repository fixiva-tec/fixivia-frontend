import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixvia/shared/widgets/fx_choice_button.dart';
import 'package:fixvia/shared/widgets/fx_primary_button.dart';
import 'package:fixvia/shared/widgets/fx_secondary_button.dart';
import 'package:fixvia/shared/widgets/fx_text_field.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('Fx legacy aliases', () {
    testWidgets('primary button taps with its arrow', (tester) async {
      var fired = 0;
      await tester.pumpWidget(
        shadHarness(
          FxPrimaryButton(
            label: 'Go',
            testId: 'fxp-1',
            onPressed: () => fired++,
          ),
        ),
      );
      expect(find.text('Go'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
      await tester.tap(find.byKey(const Key('fxp-1')));
      await tester.pump();
      expect(fired, 1);
    });

    testWidgets('secondary button taps', (tester) async {
      var fired = 0;
      await tester.pumpWidget(
        shadHarness(
          FxSecondaryButton(
            label: 'Back',
            testId: 'fxs-1',
            onPressed: () => fired++,
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('fxs-1')));
      await tester.pump();
      expect(fired, 1);
    });

    testWidgets('choice button taps and shows selection', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        shadHarness(
          FxChoiceButton(
            label: 'Pick',
            selected: true,
            onTap: () => tapped++,
            testId: 'fxc-1',
          ),
        ),
      );
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      await tester.tap(find.byKey(const Key('fxc-1')));
      await tester.pump();
      expect(tapped, 1);
    });

    testWidgets('text field maps label to placeholder', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        shadHarness(
          FxTextField(
            testId: 'fxt-1',
            label: 'Name',
            controller: controller,
          ),
        ),
      );
      expect(find.text('Name'), findsNWidgets(2)); // label + hint
      await tester.enterText(find.byType(TextField), 'Ada');
      await tester.pump();
      expect(controller.text, 'Ada');
    });
  });
}
