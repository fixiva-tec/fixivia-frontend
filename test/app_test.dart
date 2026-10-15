import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixvia/app.dart';
import 'package:fixvia/features/auth/auth_screen.dart';
import 'package:fixvia/features/shells/workspace_shell.dart';

import 'helpers/test_helpers.dart';

Future<void> _login(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('auth_mode_login')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.descendant(
      of: find.byKey(const Key('auth_login_mobile')),
      matching: find.byType(TextField),
    ),
    '9000000001',
  );
  await tester.pump();
  await tester.tap(find.byKey(const Key('auth_login_send_otp')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.descendant(
      of: find.byKey(const Key('auth_login_otp_input')),
      matching: find.byType(TextField),
    ),
    '123456',
  );
  await tester.pump();
  await tester.tap(find.byKey(const Key('auth_login_verify')));
  await tester.pumpAndSettle();
}

void main() {
  group('FixviaApp auth gate', () {
    testWidgets('logged out shows the auth screen', (tester) async {
      desktopSize(tester);
      await tester.pumpWidget(
        FixviaApp(authApi: FakeAuthApi(), api: testApi(FakeHttp())),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(WorkspaceShell), findsNothing);
    });

    testWidgets('login opens the shell and sets the token', (tester) async {
      desktopSize(tester);
      final api = testApi(FakeHttp());
      await tester.pumpWidget(FixviaApp(authApi: FakeAuthApi(), api: api));
      await tester.pumpAndSettle();
      await _login(tester);
      expect(find.byType(WorkspaceShell), findsOneWidget);
      expect(find.byType(AuthScreen), findsNothing);
      expect(api.token, 'tok-9000000001');
    });

    testWidgets('logout returns to auth and clears the token',
        (tester) async {
      desktopSize(tester);
      final api = testApi(FakeHttp());
      await tester.pumpWidget(FixviaApp(authApi: FakeAuthApi(), api: api));
      await tester.pumpAndSettle();
      await _login(tester);
      expect(api.token, isNotNull);
      await tester.tap(find.byKey(const Key('shell_account_name')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shell_logout')));
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(api.token, isNull);
    });

    testWidgets('locale and theme mode pass through', (tester) async {
      desktopSize(tester);
      await tester.pumpWidget(
        FixviaApp(
          authApi: FakeAuthApi(),
          api: testApi(FakeHttp()),
          locale: const Locale('ml'),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        Localizations.localeOf(tester.element(find.byType(AuthScreen))),
        const Locale('ml'),
      );
      expect(find.byType(AuthScreen), findsOneWidget);
    });
  });
}
