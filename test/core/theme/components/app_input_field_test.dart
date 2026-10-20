import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixvia/core/theme/app_theme.dart';
import 'package:fixvia/core/theme/components/app_input_field.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('AppInputField content', () {
    testWidgets('label, placeholder, adornments render', (tester) async {
      await tester.pumpWidget(
        themeHarness(
          const AppInputField(
            testId: 'f-1',
            label: 'Mobile',
            placeholder: '10-digit number',
            leading: Icon(Icons.phone),
            trailing: Icon(Icons.check),
          ),
        ),
      );
      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('10-digit number'), findsOneWidget);
      expect(find.byIcon(Icons.phone), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('typing reaches onChanged and the controller', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var seen = '';
      await tester.pumpWidget(
        themeHarness(
          AppInputField(
            testId: 'f-2',
            controller: controller,
            onChanged: (v) => seen = v,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump();
      expect(seen, 'hello');
      expect(controller.text, 'hello');
    });

    testWidgets('obscure, disabled, length, and formatters pass through',
        (tester) async {
      await tester.pumpWidget(
        themeHarness(
          AppInputField(
            testId: 'f-3',
            obscureText: true,
            enabled: false,
            maxLength: 6,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isTrue);
      expect(field.enabled, isFalse);
      expect(field.maxLength, 6);
      expect(field.keyboardType, TextInputType.number);
      expect(field.inputFormatters, hasLength(1));
    });
  });

  group('AppInputField focus ring', () {
    testWidgets('focus swaps the border color and width', (tester) async {
      await tester.pumpWidget(
        themeHarness(
          const AppInputField(testId: 'f-4', label: 'Name'),
        ),
      );
      BoxDecoration deco() {
        final box = tester.widgetList<AnimatedContainer>(
          find.descendant(
            of: find.byKey(const Key('f-4')),
            matching: find.byType(AnimatedContainer),
          ),
        );
        return box.first.decoration! as BoxDecoration;
      }

      expect(
        (deco().border! as Border).top.color,
        AppColors.lineOf(tester.element(find.byType(TextField))),
      );
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(
        (deco().border! as Border).top.color,
        AppColors.primaryBright,
      );
      expect((deco().border! as Border).top.width, 1.6);
    });
  });

  group('AppInputField dark mode', () {
    testWidgets('builds under dark', (tester) async {
      await tester.pumpWidget(
        themeHarness(
          const AppInputField(testId: 'f-5', label: 'Name'),
          dark: true,
        ),
      );
      expect(find.text('Name'), findsOneWidget);
    });
  });
}
