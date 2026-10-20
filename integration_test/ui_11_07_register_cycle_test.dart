import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:fixvia/main.dart' as app;

import 'helpers/ui_steps.dart';

/// UI-11-07: a new customer registers with name + mobile + OTP, lands on
/// home, sees their name in the account menu, logs out, and logs back in
/// with the same mobile. No seeding: registration IS the setup.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('UI-11-07 register then login', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // 1. register mode, customer pill, name + mobile.
    await openLogin(tester);
    step('landing login opened');
    await tester.tap(find.byKey(const Key('auth_mode_register')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('auth_register_role_customer')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('auth_register_name')), 'Phase One');
    await tester.enterText(
        find.byKey(const Key('auth_login_mobile')), '9876543210');
    step("register form filled ('Phase One', 9876543210)");

    // 2. send OTP, verify with the dev-hook code.
    await tester.tap(find.byKey(const Key('auth_login_send_otp')));
    await tester.pumpAndSettle();
    final regCode =
        await pollFreshOtpCode('9876543210', purpose: 'register');
    await tester.enterText(
        find.byKey(const Key('auth_login_otp_input')), regCode);
    await tester.tap(find.byKey(const Key('auth_login_verify')));
    await tester.pumpAndSettle();
    await waitVisible(tester, find.byKey(const Key('customer_home')),
      'home after register');
    step('registered customer lands on home');

    // 3. the account menu shows the registered name, then logs out
    // through the open menu (no dismiss round-trip: the menu flips above
    // the rail-bottom trigger and would swallow a second trigger tap).
    await tester.tap(find.byKey(const Key('shell_account_name')));
    await tester.pumpAndSettle();
    await waitVisible(tester, find.text('Phase One'), 'registered name');
    step("account menu shows 'Phase One'");
    await tester.tap(find.byKey(const Key('shell_logout')));
    await tester.pumpAndSettle();
    await waitVisible(
        tester, find.byKey(const Key('landing_login')), 'landing page');
    step('logged out');

    // 4. login mode with the same mobile closes the cycle.
    await openLogin(tester);
    step('landing login opened');
    await tester.tap(find.byKey(const Key('auth_mode_login')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('auth_login_mobile')), '9876543210');
    await tester.tap(find.byKey(const Key('auth_login_send_otp')));
    await tester.pumpAndSettle();
    final loginCode = await pollFreshOtpCode('9876543210');
    await tester.enterText(
        find.byKey(const Key('auth_login_otp_input')), loginCode);
    await tester.tap(find.byKey(const Key('auth_login_verify')));
    await tester.pumpAndSettle();
    await waitVisible(tester, find.byKey(const Key('customer_home')),
      'home after login');
    step('same mobile logs in (register-login cycle closes)');
    await logout(tester);
  });
}
