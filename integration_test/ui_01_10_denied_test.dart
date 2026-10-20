// UI-01-10: forbidden pages deny by role.
//
// Negative access test. Per role: real OTP login, forbidden nav testIds
// absent from the shell (text matching would misfire on page content
// that repeats a tab word), then each restricted page opened DIRECTLY via
// Navigator (the app has no URL routes, so this is the deep-link
// equivalent) with that role's own token. Every page must land in the
// load-failure state ("Could not load this page") — privileged data must
// never render just because the link was hidden, not missing.
import 'dart:convert';

import 'package:fixvia/api/client.dart';
import 'package:fixvia/core/theme/components/app_workspace.dart';
import 'package:fixvia/features/shells/pages/resource_pages.dart';
import 'package:fixvia/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

const _apiBase = String.fromEnvironment('API_BASE',
    defaultValue: 'http://127.0.0.1:8080');
const _deniedTitle = 'Could not load this page';

class _PageSpec {
  const _PageSpec(this.name, this.rootId, this.retry, this.build);
  final String name;
  final String rootId;
  final bool retry;
  final Widget Function(ApiClient api) build;
}

class _DenySpec {
  const _DenySpec(this.role, this.mobile, this.tabs, this.pages);
  final String role;
  final String mobile;
  final List<String> tabs;
  final List<_PageSpec> pages;
}

Widget _partners(ApiClient api) => PartnersPage(api: api);
Widget _admins(ApiClient api) => AdminRequestsPage(api: api);
Widget _invoices(ApiClient api) => InvoicesPage(api: api);
Widget _pricing(ApiClient api) => PricingPage(api: api);

final _denials = [
  _DenySpec('customer', '9000000004', ['Home', 'Bookings', 'Addresses'], [
    _PageSpec('Partners', 'master_partners', true, _partners),
    _PageSpec('Admins', 'master_admin_reqs', true, _admins),
    _PageSpec('Invoices', 'master_invoices', false, _invoices),
    _PageSpec('Pricing', 'partner_pricing', false, _pricing),
  ]),
  _DenySpec('servicePartner', '9000000003',
      ['Inbox', 'Schedule', 'Earnings', 'Profile', 'Reports'], [
    _PageSpec('Partners', 'master_partners', true, _partners),
    _PageSpec('Invoices', 'master_invoices', false, _invoices),
  ]),
  _DenySpec('partnerOwner', '9000000002',
      ['Open', 'Upcoming', 'Roster', 'Pricing', 'Analytics'], [
    _PageSpec('Partners', 'master_partners', true, _partners),
  ]),
  _DenySpec('partnerAdmin', '9000000005',
      ['Open', 'Upcoming', 'Roster', 'Pricing', 'Analytics'], [
    _PageSpec('Admins', 'master_admin_reqs', true, _admins),
    _PageSpec('Invoices', 'master_invoices', false, _invoices),
  ]),
];

const _allTabs = [
  'Home',
  'Bookings',
  'Addresses',
  'Inbox',
  'Schedule',
  'Earnings',
  'Profile',
  'Reports',
  'Open',
  'Upcoming',
  'Roster',
  'Pricing',
  'Analytics',
  'Partners',
  'Categories',
  'Admins',
  'Invoices',
];

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

Future<String?> _readOtpCode(String mobile) async {
  final uri =
      Uri.parse('$_apiBase/v1/dev/otp-code?mobile=$mobile&purpose=login');
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

Future<String> _pollFreshOtpCode(String mobile, {String? differentFrom}) async {
  for (var i = 0; i < 60; i++) {
    final code = await _readOtpCode(mobile);
    if (code != null && code != differentFrom) return code;
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  fail('fresh OTP code not available after 30s');
}

Future<void> _loginAs(WidgetTester tester, _DenySpec spec) async {
  final baseline = await _readOtpCode(spec.mobile);
  final landingLogin = find.byKey(const Key('landing_login'));
  await _waitVisible(tester, landingLogin, 'landing login button');
  await tester.tap(landingLogin);
  await tester.pumpAndSettle();
  step('landing login opened');
  final loginMode = find.byKey(const Key('auth_mode_login'));
  await _waitVisible(tester, loginMode, 'login mode switch');
  await tester.tap(loginMode);
  await tester.pumpAndSettle();

  final mobileField = find.byKey(const Key('auth_login_mobile'));
  await _waitVisible(tester, mobileField, 'mobile input');
  await tester.enterText(mobileField, spec.mobile);
  await tester.pumpAndSettle();

  final send = find.byKey(const Key('auth_login_send_otp'));
  await _waitVisible(tester, send, 'send OTP button');
  await tester.ensureVisible(send);
  await tester.tap(send);
  await tester.pumpAndSettle();

  final code = await _pollFreshOtpCode(spec.mobile, differentFrom: baseline);
  final otpField = find.byKey(const Key('auth_login_otp_input'));
  await _waitVisible(tester, otpField, 'otp input');
  await tester.enterText(otpField, code);
  await tester.pumpAndSettle();

  final verify = find.byKey(const Key('auth_login_verify'));
  await _waitVisible(tester, verify, 'login button');
  await tester.ensureVisible(verify);
  await tester.tap(verify);
  await tester.pumpAndSettle();

  await _waitVisible(
      tester,
      find.byKey(Key('nav_${spec.tabs.first.toLowerCase()}')),
      'shell nav');
  step("OTP login as ${spec.role}");
}

/// Mint this role's token over plain HTTP (for directly-pushed pages).
Future<String> _apiToken(String mobile) async {
  final baseline = await _readOtpCode(mobile);
  final req = await http.post(
    Uri.parse('$_apiBase/v1/otp/request'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'mobile': mobile, 'purpose': 'login'}),
  );
  if (req.statusCode != 200) fail('OTP request failed: ${req.statusCode}');
  final code = await _pollFreshOtpCode(mobile, differentFrom: baseline);
  final res = await http.post(
    Uri.parse('$_apiBase/v1/otp/verify'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'mobile': mobile, 'purpose': 'login', 'code': code}),
  );
  if (res.statusCode != 200) fail('OTP verify failed: ${res.statusCode}');
  return (jsonDecode(res.body) as Map<String, dynamic>)['token'] as String;
}

Future<void> _logout(WidgetTester tester) async {
  final account = find.byKey(const Key('shell_account_name'));
  await _waitVisible(tester, account, 'account menu');
  await tester.tap(account);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('shell_logout')));
  await tester.pumpAndSettle();
  await _waitVisible(
      tester, find.byKey(const Key('landing_login')), 'landing page');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'UI-01-10 forbidden pages deny by role',
    (tester) async {
      app.main();
      await tester.pumpAndSettle();
      step('app launched, landing shown');

      for (final spec in _denials) {
        await _loginAs(tester, spec);

        final hidden =
            _allTabs.where((t) => !spec.tabs.contains(t)).toList();
        for (final tab in hidden) {
          expect(find.byKey(Key('nav_${tab.toLowerCase()}')), findsNothing,
              reason: 'nav hides $tab for ${spec.role}');
        }
        step("forbidden tabs hidden: ${hidden.join(', ')}");

        final token = await _apiToken(spec.mobile);
        final client = ApiClient(baseUrl: _apiBase, token: token);
        final nav = Navigator.of(
            tester.element(find.byType(AppWorkspaceFrame).first));

        for (final page in spec.pages) {
          step("direct-open ${page.name} page as ${spec.role}");
          nav.push(MaterialPageRoute(builder: (_) => page.build(client)));
          await tester.pumpAndSettle();

          final root = find.byKey(Key(page.rootId));
          await _waitVisible(tester, root, '${page.name} page');
          expect(find.text(_deniedTitle), findsWidgets,
              reason: '${page.name} denied for ${spec.role}');
          expect(find.byKey(const Key('app_fetch_retry')),
              page.retry ? findsWidgets : findsNothing,
              reason: '${page.name} retry wiring');
          step("${page.name} denied: '$_deniedTitle'");

          nav.pop();
          await tester.pumpAndSettle();
        }

        await _logout(tester);
        step('logged out (${spec.role})');
      }
    },
  );
}
