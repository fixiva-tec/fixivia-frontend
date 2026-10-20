import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixvia/core/theme/components/app_account_menu.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('AppAccountMenu pill', () {
    testWidgets('name pill shows the name', (tester) async {
      await tester.pumpWidget(
        themeHarness(
          AppAccountMenu(name: 'Meera Nair', onLogout: () {}),
        ),
      );
      expect(find.byKey(const Key('shell_account_menu')), findsOneWidget);
      expect(find.text('Meera Nair'), findsOneWidget);
    });

    testWidgets('compact shows avatar only, menu still opens', (tester) async {
      var out = 0;
      await tester.pumpWidget(
        themeHarness(
          AppAccountMenu(
            name: 'Meera Nair',
            onLogout: () => out++,
            compact: true,
          ),
        ),
      );
      expect(find.text('Meera Nair'), findsNothing);
      await tester.tap(find.byKey(const Key('shell_account_name')));
      await tester.pumpAndSettle();
      expect(find.text('Meera Nair'), findsOneWidget);
      await tester.tap(find.byKey(const Key('shell_logout')));
      await tester.pumpAndSettle();
      expect(out, 1);
    });
  });

  group('AppAccountMenu menu', () {
    testWidgets('opens with subtitle and custom logout label', (tester) async {
      var out = 0;
      await tester.pumpWidget(
        themeHarness(
          AppAccountMenu(
            name: 'Arjun',
            subtitle: 'Partner owner',
            logoutLabel: 'Sign out',
            onLogout: () => out++,
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('shell_account_name')));
      await tester.pumpAndSettle();
      expect(find.text('Partner owner'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(out, 1);
    });

    testWidgets('no subtitle row when subtitle is null', (tester) async {
      await tester.pumpWidget(
        themeHarness(
          AppAccountMenu(name: 'Solo', onLogout: () {}),
        ),
      );
      await tester.tap(find.byKey(const Key('shell_account_name')));
      await tester.pumpAndSettle();
      expect(find.text('Solo'), findsNWidgets(2)); // pill + popover header
      expect(find.byKey(const Key('shell_logout')), findsOneWidget);
    });
  });
}
