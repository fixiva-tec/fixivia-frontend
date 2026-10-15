import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixvia/shared/widgets/fx_otp_input.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('FxOtpInput', () {
    testWidgets('renders wired to the controller', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        shadHarness(
          FxOtpInput(controller: controller, testId: 'otp-x'),
        ),
      );
      expect(find.text('OTP'), findsOneWidget);
      expect(find.text('6-digit code'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '12ab34');
      await tester.pump();
      expect(controller.text, '1234');
    });

    testWidgets('caps length at six digits', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        shadHarness(
          FxOtpInput(controller: controller, testId: 'otp-x'),
        ),
      );
      await tester.enterText(find.byType(TextField), '123456789');
      await tester.pump();
      expect(controller.text, '123456');
    });
  });
}
