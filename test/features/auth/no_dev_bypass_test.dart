// Tripwire: the dev-chip login bypass must never come back.
//
// Covers the removal in two independent ways:
//  1. Behavioral: the auth screen renders no dev section in either mode.
//  2. Static: auth sources contain none of the bypass identifiers.
import 'dart:io';

import 'package:fixvia/features/auth/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

Future<void> _pump(WidgetTester tester) async {
  desktopSize(tester);
  await tester.pumpWidget(
    materialHarness(AuthScreen(api: FakeAuthApi(), onAuthenticated: (_) {})),
  );
  await tester.pumpAndSettle();
}

/// Any widget keyed `auth_dev_login_*` (the role suffix is dynamic).
Finder _devLoginKeys() => find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key as ValueKey<String>).value.startsWith('auth_dev_login_'),
    );

void main() {
  group('no dev-login bypass', () {
    testWidgets('register mode shows no dev section', (tester) async {
      await _pump(tester);
      expect(find.text('Dev only — enter as'), findsNothing);
      expect(_devLoginKeys(), findsNothing);
    });

    testWidgets('login mode shows no dev section', (tester) async {
      await _pump(tester);
      await tester.tap(find.byKey(const Key('auth_mode_login')));
      await tester.pumpAndSettle();
      expect(find.text('Dev only — enter as'), findsNothing);
      expect(_devLoginKeys(), findsNothing);
    });

    test('auth sources contain no bypass identifiers', () {
      const forbidden = [
        'injectDevUsers',
        'auth_dev_login',
        'onDevLogin',
        'devAccounts',
        '_devRoleLabel',
        'Dev only',
      ];
      final dir = Directory('lib/features/auth');
      expect(dir.existsSync(), isTrue, reason: 'run from package root');
      for (final ent in dir.listSync(recursive: true)) {
        if (ent is! File || !ent.path.endsWith('.dart')) continue;
        final src = ent.readAsStringSync();
        for (final id in forbidden) {
          expect(src.contains(id), isFalse,
              reason: '${ent.path} must not contain $id');
        }
      }
    });
  });
}
