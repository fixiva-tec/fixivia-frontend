// UI-01-04: manual OTP login happy path.
//
// Enters a seeded customer mobile, taps Send, reads the live code from the
// dev-only GET /v1/dev/otp-code hook (404 outside the dev flavor), verifies,
// and lands on the customer home. The code is polled until it differs from
// any pre-existing one, so an earlier request can never leak in as stale.
import 'dart:convert';

import 'package:fixvia/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

const _mobile = '9000000004';
const _apiBase = String.fromEnvironment('API_BASE',
    defaultValue: 'http://127.0.0.1:8080');

/// Report a step: parsed from drive output into the run log + HTML report.
void step(String text) => print('UI_STEP: $text');

/// Poll for [finder] with real delays (network-backed UI); fail on timeout.
Future<void> _waitVisible(
  WidgetTester tester,
  Finder finder,
  String what,
) async {
  for (var i = 0; i < 60; i++) {
    await tester.pump();
    if (finder.evaluate().isNotEmpty) return;
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  fail('$what not visible after 30s');
}

Future<String?> _readOtpCode() async {
  final uri = Uri.parse(
      '$_apiBase/v1/dev/otp-code?mobile=$_mobile&purpose=login');
  try {
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as Map<String, dynamic>)['code'] as String;
    }
  } catch (_) {
    // Backend not up yet; the poll loop retries.
  }
  return null;
}

Future<String> _pollFreshOtpCode({String? differentFrom}) async {
  for (var i = 0; i < 60; i++) {
    final code = await _readOtpCode();
    if (code != null && code != differentFrom) return code;
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  fail('fresh OTP code not available after 30s');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'UI-01-04 manual OTP login lands on home',
    (tester) async {
      app.main();
      await tester.pumpAndSettle();
      step('app launched, landing shown');

      final baseline = await _readOtpCode();

      final landingLogin = find.byKey(const Key('landing_login'));
      await _waitVisible(tester, landingLogin, 'landing login button');
      await tester.tap(landingLogin);
      await tester.pumpAndSettle();
      step('landing login opened');

      final loginMode = find.byKey(const Key('auth_mode_login'));
      await _waitVisible(tester, loginMode, 'login mode switch');
      await tester.tap(loginMode);
      await tester.pumpAndSettle();
      step('switched to login mode');

      final mobileField = find.byKey(const Key('auth_login_mobile'));
      await _waitVisible(tester, mobileField, 'mobile input');
      await tester.enterText(mobileField, _mobile);
      await tester.pumpAndSettle();
      step("phone number provided '$_mobile'");

      final send = find.byKey(const Key('auth_login_send_otp'));
      await _waitVisible(tester, send, 'send OTP button');
      await tester.ensureVisible(send);
      await tester.tap(send);
      await tester.pumpAndSettle();
      step('tapped send OTP');

      final code = await _pollFreshOtpCode(differentFrom: baseline);
      step("OTP received '$code'");

      final otpField = find.byKey(const Key('auth_login_otp_input'));
      await _waitVisible(tester, otpField, 'otp input');
      await tester.enterText(otpField, code);
      await tester.pumpAndSettle();
      step("OTP provided '$code'");

      final verify = find.byKey(const Key('auth_login_verify'));
      await _waitVisible(tester, verify, 'login button');
      await tester.ensureVisible(verify);
      await tester.tap(verify);
      await tester.pumpAndSettle();
      step('tapped login button');

      // The desktop rail is icon-only: tabs resolve to nav_<label> keys.
      for (final tab in ['home', 'bookings', 'addresses']) {
        expect(
          find.byKey(Key('nav_$tab')).evaluate().isNotEmpty,
          isTrue,
          reason: 'tab "nav_$tab"',
        );
      }
      step('home page is visible');
    },
  );
}
