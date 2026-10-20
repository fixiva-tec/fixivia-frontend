// UI-01-11: auth screen has no dev-login bypass.
//
// Tripwire for the removed dev chips: neither register nor login mode may
// render the dev section or any `auth_dev_login_*` key, in the real app.
import 'package:fixvia/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/ui_steps.dart';

/// Any widget keyed `auth_dev_login_*` (the role suffix is dynamic).
Finder _devLoginKeys() => find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key as ValueKey<String>).value.startsWith('auth_dev_login_'),
    );

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'UI-01-11 no dev-login bypass on auth screen',
    (tester) async {
      app.main();
      await tester.pumpAndSettle();
      step('app launched, landing shown');

      await openLogin(tester);
      step('landing login opened');
      await waitVisible(
          tester, find.byKey(const Key('auth_form_card')), 'auth card');
      expect(find.text('Dev only — enter as'), findsNothing);
      expect(_devLoginKeys(), findsNothing);
      step('register mode: no dev section');

      final loginMode = find.byKey(const Key('auth_mode_login'));
      await waitVisible(tester, loginMode, 'login mode switch');
      await tester.tap(loginMode);
      await tester.pumpAndSettle();
      expect(find.text('Dev only — enter as'), findsNothing);
      expect(_devLoginKeys(), findsNothing);
      step('login mode: no dev section');
    },
  );
}
