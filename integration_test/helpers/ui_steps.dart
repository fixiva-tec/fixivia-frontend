// Shared UI-step helpers for integration tests.
//
// Every new `integration_test/ui_*_test.dart` target imports this instead of
// redefining the login/OTP/logout mechanics:
//
//   import 'helpers/ui_steps.dart';
//
// Conventions: `step()` prints UI_STEP markers (parsed into the run log +
// report Journey); `waitVisible` polls network-backed UI with real delays;
// OTP helpers talk to the dev-only GET /v1/dev/otp-code hook (404 outside
// the dev flavor); `otpLogin`/`apiToken`/`logout` compose them.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Backend under test. Arrives via --dart-define=API_BASE=... from drive.
String get apiBase => const String.fromEnvironment('API_BASE',
    defaultValue: 'http://127.0.0.1:8080');

/// Report a step: parsed from drive output into the run log + HTML report.
void step(String text) => print('UI_STEP: $text');

/// Sequence for waitVisible calls; each wait prints UI_WAIT (unparsed,
/// drive-log forensics) and stamps timeouts, so duplicate executions of
/// the same wait are distinguishable.
int _waitSeq = 0;

/// Poll for [finder] with real delays (network-backed UI); fail on timeout.
Future<void> waitVisible(
  WidgetTester tester,
  Finder finder,
  String what,
) async {
  final seq = ++_waitSeq;
  print('UI_WAIT: #$seq $what');
  for (var i = 0; i < 60; i++) {
    await tester.pump();
    if (finder.evaluate().isNotEmpty) return;
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  fail('#$seq $what not visible after 30s');
}

/// Latest dev-sent OTP code, or null when none exists / backend is down.
Future<String?> readOtpCode(
  String mobile, {
  String purpose = 'login',
  String? base,
}) async {
  final uri = Uri.parse(
      '${base ?? apiBase}/v1/dev/otp-code?mobile=$mobile&purpose=$purpose');
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

/// Poll until a code exists that differs from [differentFrom] (so an
/// earlier request can never leak in as stale). Fails after 30s.
Future<String> pollFreshOtpCode(
  String mobile, {
  String? differentFrom,
  String purpose = 'login',
  String? base,
}) async {
  for (var i = 0; i < 60; i++) {
    final code = await readOtpCode(mobile, purpose: purpose, base: base);
    if (code != null && code != differentFrom) return code;
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  fail('fresh OTP code not available after 30s');
}

/// Landing page -> login button -> auth screen gate.
Future<void> openLogin(WidgetTester tester) async {
  final login = find.byKey(const Key('landing_login'));
  await waitVisible(tester, login, 'landing login button');
  await tester.tap(login);
  await tester.pumpAndSettle();
}

/// Full mobile + OTP login through the landing page and auth screen.
/// Ends after the verify tap; the caller asserts its own shell marker
/// (role-specific).
Future<void> otpLogin(
  WidgetTester tester,
  String mobile, {
  String label = '',
  String? base,
}) async {
  final who = label.isEmpty ? mobile : '$label ($mobile)';
  final baseline = await readOtpCode(mobile, base: base);
  await openLogin(tester);
  step('landing login opened');
  final loginMode = find.byKey(const Key('auth_mode_login'));
  await waitVisible(tester, loginMode, 'login mode switch');
  await tester.tap(loginMode);
  await tester.pumpAndSettle();

  final mobileField = find.byKey(const Key('auth_login_mobile'));
  await waitVisible(tester, mobileField, 'mobile input');
  await tester.enterText(mobileField, mobile);
  await tester.pumpAndSettle();
  step("phone number provided '$mobile'");

  final send = find.byKey(const Key('auth_login_send_otp'));
  await waitVisible(tester, send, 'send OTP button');
  await tester.ensureVisible(send);
  await tester.tap(send);
  await tester.pumpAndSettle();
  step('tapped send OTP');

  final code =
      await pollFreshOtpCode(mobile, differentFrom: baseline, base: base);
  step("OTP received '$code'");
  final otpField = find.byKey(const Key('auth_login_otp_input'));
  await waitVisible(tester, otpField, 'otp input');
  await tester.enterText(otpField, code);
  await tester.pumpAndSettle();
  step("OTP provided '$code'");

  final verify = find.byKey(const Key('auth_login_verify'));
  await waitVisible(tester, verify, 'login button');
  await tester.ensureVisible(verify);
  await tester.tap(verify);
  await tester.pumpAndSettle();
  step('tapped login button');
  step("OTP login as $who");
}

/// Move a customer's non-final bookings to today (dev-only hook).
///
/// Pure-UI journeys create bookings inside the run, so the Python seeder
/// cannot move them due: start is rejected before the service date
/// arrives, so the journey moves its own bookings due first.
Future<void> makeCustomerBookingsDue(String mobile, {String? base}) async {
  final res = await http.post(
    Uri.parse('${base ?? apiBase}/v1/dev/bookings/make-due'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'customer_mobile': mobile}),
  );
  if (res.statusCode != 200) fail('make-due failed: ${res.statusCode}');
  final moved =
      (jsonDecode(res.body) as Map<String, dynamic>)['moved'] as List;
  if (moved.isEmpty) fail('make-due moved nothing for $mobile');
}

/// Mint this mobile's token over plain HTTP (for directly-pushed pages).
Future<String> apiToken(String mobile, {String? base}) async {
  final root = base ?? apiBase;
  final baseline = await readOtpCode(mobile, base: root);
  final req = await http.post(
    Uri.parse('$root/v1/otp/request'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'mobile': mobile, 'purpose': 'login'}),
  );
  if (req.statusCode != 200) fail('OTP request failed: ${req.statusCode}');
  final code =
      await pollFreshOtpCode(mobile, differentFrom: baseline, base: root);
  final res = await http.post(
    Uri.parse('$root/v1/otp/verify'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'mobile': mobile, 'purpose': 'login', 'code': code}),
  );
  if (res.statusCode != 200) fail('OTP verify failed: ${res.statusCode}');
  return (jsonDecode(res.body) as Map<String, dynamic>)['token'] as String;
}

/// Account menu -> logout. Ends back on the landing page.
Future<void> logout(WidgetTester tester) async {
  final account = find.byKey(const Key('shell_account_name'));
  await waitVisible(tester, account, 'account menu');
  await tester.tap(account);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('shell_logout')));
  await tester.pumpAndSettle();
  await waitVisible(
      tester, find.byKey(const Key('landing_login')), 'landing page');
}

/// Tap a shell nav destination by label. The desktop rail is icon-only,
/// so tabs resolve to their `nav_<label>` testIds.
Future<void> tapNav(WidgetTester tester, String label) async {
  final dest = find.byKey(Key('nav_${label.toLowerCase()}'));
  await waitVisible(tester, dest, 'nav $label');
  await tester.tap(dest);
  await tester.pumpAndSettle();
}

/// First widget whose ValueKey starts with [prefix] (ids are dynamic).
Finder _keyPrefix(String prefix) => find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key as ValueKey<String>).value.startsWith(prefix),
    );

/// Tap the inbox offer row showing [category] (order-independent across
/// multi-case runs: each journey uses its own category). Rows carry no
/// per-row key, so the row's open button is found by vertical alignment
/// with the category cell.
Future<void> tapOfferFor(WidgetTester tester, String category) async {
  final cell = find.text(category);
  await waitVisible(tester, cell, "'$category' offer cell");
  await tester.ensureVisible(cell.first);
  await tester.pumpAndSettle();
  final opens = _keyPrefix('sp_offer_open_');
  await waitVisible(tester, opens, 'offer open button');
  final targetDy = tester.getCenter(cell.first).dy;
  for (final el in opens.evaluate()) {
    final button = find.byWidget(el.widget);
    await tester.ensureVisible(button);
    final dy = tester.getCenter(button).dy;
    if ((dy - targetDy).abs() < 24) {
      await tester.tap(button);
      await tester.pumpAndSettle();
      return;
    }
  }
  fail("no open button aligned with '$category' offer row");
}

/// Wait until [finder] matches nothing (post-refetch absence).
/// Pair with a tab round-trip, which forces FetchBody to refetch.
Future<void> waitGone(
    WidgetTester tester, Finder finder, String label) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (finder.evaluate().isEmpty) return;
  }
  fail('timed out waiting for $label to disappear');
}

/// Tap the bookings-list row showing [category]. The row renders the
/// category name bare (exact-text match); the row's opaque tap area
/// catches a tap on the cell itself.
Future<void> tapBookingRowFor(WidgetTester tester, String category) async {
  final cell = find.text(category);
  await waitVisible(tester, cell, "'$category' booking row");
  await tester.ensureVisible(cell.first);
  await tester.tap(cell.first);
  await tester.pumpAndSettle();
}

/// Dismiss the booking-celebration dialog via Done.
Future<void> dismissConfirmed(WidgetTester tester) async {
  final dialog = find.byKey(const Key('booking_confirmed_dialog'));
  await waitVisible(tester, dialog, 'booking confirmed dialog');
  await tester.tap(find.byKey(const Key('booking_confirmed_done')));
  await tester.pumpAndSettle();
}

/// Pop the current subpage via its header back control.
/// (tester.pageBack needs a Material/Cupertino back button, which these
/// pages lack, so it always fails here.)
Future<void> popBack(WidgetTester tester) async {
  final back = find.byKey(const Key('app_subpage_back'));
  await waitVisible(tester, back, 'subpage back');
  await tester.tap(back);
  await tester.pumpAndSettle();
}

/// Tap an in-page action button by testId. Scrolls it into view first:
/// detail pages scroll, and an off-viewport tap silently misses (warning
/// only), leaving a stale 'ok' to satisfy the next wait. Centers the
/// button: a refetch between scroll and tap can shift edge-aligned
/// content back out of view.
Future<void> tapAction(WidgetTester tester, String testId) async {
  final button = find.byKey(Key(testId));
  await waitVisible(tester, button, testId);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(
    button.evaluate().single,
    alignment: 0.5,
    duration: const Duration(milliseconds: 300),
  );
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}
