// UI-01-09: role side-nav access matrix.
//
// Real OTP login per role (seeded mobiles, live code from the dev-only
// GET /v1/dev/otp-code hook), then per role: exact nav set visible with
// forbidden tabs absent, and every tab tapped to prove its page opens
// plus a follow-up content check. Nav assertions and taps use the nav
// testIds (`nav_<label>`): page content may legitimately repeat a tab
// word (e.g. the inbox table's "Open" column), so text matching the nav
// would misfire. Each tap is self-verifying since the page root must
// appear afterwards.
import 'dart:convert';

import 'package:fixvia/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

const _apiBase = String.fromEnvironment('API_BASE',
    defaultValue: 'http://127.0.0.1:8080');
const _retryKey = 'app_fetch_retry';

class _RoleSpec {
  const _RoleSpec(this.key, this.mobile, this.tabs);
  final String key;
  final String mobile;
  final List<String> tabs;
}

const _roles = [
  _RoleSpec('customer', '9000000004', ['Home', 'Bookings', 'Addresses']),
  _RoleSpec('servicePartner', '9000000003',
      ['Inbox', 'Schedule', 'Earnings', 'Profile', 'Reports']),
  _RoleSpec('partnerOwner', '9000000002',
      ['Open', 'Upcoming', 'Roster', 'Pricing', 'Analytics']),
  _RoleSpec('partnerAdmin', '9000000005',
      ['Open', 'Upcoming', 'Roster', 'Pricing', 'Analytics']),
  _RoleSpec('masterAdmin', '9000000001',
      ['Partners', 'Categories', 'Admins', 'Invoices', 'Analytics']),
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

/// Tab label -> page root testId (Analytics resolved per role below).
const _pageRoots = {
  'Home': 'customer_home',
  'Bookings': 'customer_bookings',
  'Addresses': 'customer_addresses',
  'Inbox': 'sp_inbox',
  'Schedule': 'sp_schedule',
  'Earnings': 'sp_earnings',
  'Profile': 'sp_profile',
  'Reports': 'sp_reports',
  'Open': 'partner_open',
  'Upcoming': 'partner_upcoming',
  'Roster': 'partner_roster',
  'Pricing': 'partner_pricing',
  'Partners': 'master_partners',
  'Categories': 'master_categories',
  'Admins': 'master_admin_reqs',
  'Invoices': 'master_invoices',
};

/// Tab label -> nav destination testId (`nav_<lowercase label>`).
String _navKey(String label) => 'nav_${label.toLowerCase()}';

String _pageRoot(String role, String label) {
  if (label == 'Analytics') {
    if (role == 'servicePartner') return 'sp_reports';
    if (role == 'masterAdmin') return 'master_analytics';
    return 'partner_analytics';
  }
  return _pageRoots[label]!;
}

/// Tab label -> page title text (only tabs that render one).
const _pageTitles = {
  'Bookings': 'Your bookings',
  'Open': 'Open requests',
  'Upcoming': 'Bookings',
};

/// Tab label -> follow-up marker testId (only tabs that carry one).
const _pageMarkers = {
  'Addresses': 'customer_address_save',
  'Profile': 'sp_kyc_submit',
};

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

Future<void> _loginAs(WidgetTester tester, _RoleSpec spec) async {
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
  step("phone number provided '${spec.mobile}' (${spec.key})");

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
      tester, find.byKey(Key(_navKey(spec.tabs.first))), 'shell nav');
  step("OTP login as ${spec.key}");
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
    'UI-01-09 role side-nav access matrix',
    (tester) async {
      app.main();
      await tester.pumpAndSettle();
      step('app launched, landing shown');

      for (final spec in _roles) {
        await _loginAs(tester, spec);

        for (final tab in spec.tabs) {
          expect(find.byKey(Key(_navKey(tab))), findsOneWidget,
              reason: 'nav shows $tab');
        }
        for (final tab in _allTabs.where((t) => !spec.tabs.contains(t))) {
          expect(find.byKey(Key(_navKey(tab))), findsNothing,
              reason: 'nav hides $tab for ${spec.key}');
        }
        step("nav shows exactly: ${spec.tabs.join(', ')}");

        for (final tab in spec.tabs) {
          await tester.tap(find.byKey(Key(_navKey(tab))));
          await tester.pumpAndSettle();
          step("tapped '$tab'");

          final root = find.byKey(Key(_pageRoot(spec.key, tab)));
          await _waitVisible(tester, root, '$tab page');
          step("'$tab' page opened");

          final title = _pageTitles[tab];
          if (title != null) {
            expect(find.text(title), findsWidgets, reason: '$tab title');
          }
          if (tab == 'Home') {
            final book = find
                .byKey(const Key('customer_home_book'))
                .evaluate()
                .isNotEmpty;
            final empty = find
                .byKey(const Key('customer_home_book_empty'))
                .evaluate()
                .isNotEmpty;
            expect(book || empty, isTrue, reason: 'home book action');
          }
          final marker = _pageMarkers[tab];
          if (marker != null) {
            expect(find.byKey(Key(marker)), findsWidgets,
                reason: '$tab marker');
          }
          expect(find.byKey(const Key(_retryKey)), findsNothing,
              reason: '$tab loaded clean');
          step("'$tab' content verified");
        }

        await _logout(tester);
        step('logged out (${spec.key})');
      }
    },
  );
}
