import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixvia/core/session.dart';
import 'package:fixvia/features/auth/auth_api.dart';
import 'package:fixvia/features/auth/auth_screen.dart';
import 'package:fixvia/l10n/app_localizations.dart';

import '../../helpers/test_helpers.dart';

AppLocalizations l10nOf(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(AuthScreen)));

Future<void> pumpAuth(
  WidgetTester tester,
  FakeAuthApi api, {
  void Function(AuthResult)? onAuth,
  bool compact = false,
}) async {
  // Desktop layout needs desktop height (brand pane + full form);
  // the compact layout has its own dedicated test.
  if (compact) {
    compactSize(tester);
  } else {
    desktopSize(tester);
  }
  await tester.pumpWidget(
    materialHarness(
      AuthScreen(api: api, onAuthenticated: onAuth ?? (_) {}),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> enterMobile(WidgetTester tester, String value) async {
  await tester.enterText(
    find.descendant(
      of: find.byKey(const Key('auth_login_mobile')),
      matching: find.byType(TextField),
    ),
    value,
  );
  await tester.pump();
}

Future<void> enterOtp(WidgetTester tester, String value) async {
  await tester.enterText(
    find.descendant(
      of: find.byKey(const Key('auth_login_otp_input')),
      matching: find.byType(TextField),
    ),
    value,
  );
  await tester.pump();
}

class _SlowAuthApi extends FakeAuthApi {
  _SlowAuthApi(this.gate);

  final Completer<void> gate;

  @override
  Future<void> requestOtp({
    required String mobile,
    required String purpose,
  }) {
    requested.add({'mobile': mobile, 'purpose': purpose});
    return gate.future;
  }
}

void main() {
  group('AuthScreen modes', () {
    testWidgets('register mode is default with role pills and name field',
        (tester) async {
      await pumpAuth(tester, FakeAuthApi());
      final l10n = l10nOf(tester);
      expect(find.text(l10n.authRegisterTitle), findsOneWidget);
      expect(find.text('I am joining as'), findsOneWidget);
      expect(find.byKey(const Key('auth_register_role_customer')), findsOneWidget);
      expect(find.byKey(const Key('auth_register_role_sp')), findsOneWidget);
      expect(find.byKey(const Key('auth_register_name')), findsOneWidget);
      expect(find.byKey(const Key('auth_login_otp_input')), findsNothing);
    });

    testWidgets('login mode hides register-only fields', (tester) async {
      await pumpAuth(tester, FakeAuthApi());
      await tester.tap(find.byKey(const Key('auth_mode_login')));
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);
      // Title and primary button share the label.
      expect(find.text(l10n.authLoginTitle), findsNWidgets(2));
      expect(find.text('I am joining as'), findsNothing);
      expect(find.byKey(const Key('auth_register_name')), findsNothing);
    });

    testWidgets('mode switch resets sent otp and error', (tester) async {
      final api = FakeAuthApi();
      await pumpAuth(tester, api);
      await enterMobile(tester, '9876543210');
      await tester.tap(find.byKey(const Key('auth_login_send_otp')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('auth_login_otp_input')), findsOneWidget);

      await tester.tap(find.byKey(const Key('auth_mode_login')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('auth_login_otp_input')), findsNothing);

      await tester.tap(find.byKey(const Key('auth_mode_register')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('auth_login_otp_input')), findsNothing);
    });
  });

  group('AuthScreen send OTP', () {
    testWidgets('invalid mobile shows the raw code, no request', (tester) async {
      final api = FakeAuthApi();
      await pumpAuth(tester, api);
      await enterMobile(tester, '123');
      await tester.tap(find.byKey(const Key('auth_login_send_otp')));
      await tester.pumpAndSettle();
      expect(find.text('invalid_mobile'), findsOneWidget);
      expect(api.requested, isEmpty);
    });

    testWidgets('register purpose on send, login purpose in login mode',
        (tester) async {
      final api = FakeAuthApi();
      await pumpAuth(tester, api);
      await enterMobile(tester, '9876543210');
      await tester.tap(find.byKey(const Key('auth_login_send_otp')));
      await tester.pumpAndSettle();
      expect(
        api.requested,
        equals([
          {'mobile': '9876543210', 'purpose': 'register'},
        ]),
      );
      expect(find.byKey(const Key('auth_login_otp_input')), findsOneWidget);
      expect(find.byKey(const Key('auth_login_verify')), findsOneWidget);

      await tester.tap(find.byKey(const Key('auth_mode_login')));
      await tester.pumpAndSettle();
      await enterMobile(tester, '9876543210');
      await tester.tap(find.byKey(const Key('auth_login_send_otp')));
      await tester.pumpAndSettle();
      expect(api.requested.last['purpose'], 'login');
    });

    testWidgets('busy blocks double submit until the request lands',
        (tester) async {
      final gate = Completer<void>();
      final api = _SlowAuthApi(gate);
      await pumpAuth(tester, api);
      await enterMobile(tester, '9876543210');
      await tester.tap(find.byKey(const Key('auth_login_send_otp')));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byKey(const Key('auth_login_send_otp')));
      await tester.pump();
      expect(api.requested, hasLength(1));
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('auth_login_otp_input')), findsOneWidget);
    });

    testWidgets('unmount disposes controllers without errors', (tester) async {
      await pumpAuth(tester, FakeAuthApi());
      await tester.pumpWidget(materialHarness(const SizedBox()));
      await tester.pumpAndSettle();
    });

    testWidgets('request failure shows the localized error', (tester) async {
      final api = FakeAuthApi()..requestError = Exception('down');
      await pumpAuth(tester, api);
      await enterMobile(tester, '9876543210');
      await tester.tap(find.byKey(const Key('auth_login_send_otp')));
      await tester.pumpAndSettle();
      expect(find.text(l10nOf(tester).authOtpFailed), findsOneWidget);
      expect(find.byKey(const Key('auth_login_otp_input')), findsNothing);
    });
  });

  group('AuthScreen verify OTP', () {
    testWidgets('bad code shows the raw code, verify untouched', (tester) async {
      final api = FakeAuthApi();
      await pumpAuth(tester, api);
      await enterMobile(tester, '9876543210');
      await tester.tap(find.byKey(const Key('auth_login_send_otp')));
      await tester.pumpAndSettle();
      await enterOtp(tester, '12');
      await tester.tap(find.byKey(const Key('auth_login_verify')));
      await tester.pumpAndSettle();
      expect(find.text('invalid_otp'), findsOneWidget);
      expect(api.verified, isEmpty);
    });

    testWidgets('happy path authenticates with trimmed fields', (tester) async {
      final api = FakeAuthApi();
      AuthResult? authed;
      await pumpAuth(tester, api, onAuth: (r) => authed = r);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('auth_register_name')),
          matching: find.byType(TextField),
        ),
        '  Ada  ',
      );
      await tester.pump();
      await enterMobile(tester, '9876543210');
      await tester.tap(find.byKey(const Key('auth_login_send_otp')));
      await tester.pumpAndSettle();
      await enterOtp(tester, '123456');
      await tester.tap(find.byKey(const Key('auth_login_verify')));
      await tester.pumpAndSettle();
      expect(
        api.verified.single,
        equals({
          'mobile': '9876543210',
          'purpose': 'register',
          'code': '123456',
          'fullName': 'Ada',
          'role': 'customer',
          'partnerId': null,
        }),
      );
      expect(authed, isNotNull);
      expect(authed!.user.role, UserRole.customer);
    });

    testWidgets('blank name sends null, login omits the role', (tester) async {
      final api = FakeAuthApi();
      await pumpAuth(tester, api);
      await enterMobile(tester, '9876543210');
      await tester.tap(find.byKey(const Key('auth_login_send_otp')));
      await tester.pumpAndSettle();
      await enterOtp(tester, '123456');
      await tester.tap(find.byKey(const Key('auth_login_verify')));
      await tester.pumpAndSettle();
      expect(api.verified.single['fullName'], isNull);

      await tester.tap(find.byKey(const Key('auth_mode_login')));
      await tester.pumpAndSettle();
      await enterMobile(tester, '9876543210');
      await tester.tap(find.byKey(const Key('auth_login_send_otp')));
      await tester.pumpAndSettle();
      await enterOtp(tester, '123456');
      await tester.tap(find.byKey(const Key('auth_login_verify')));
      await tester.pumpAndSettle();
      expect(api.verified.last['role'], isNull);
    });

    testWidgets('verify failure shows the localized error', (tester) async {
      final api = FakeAuthApi()..verifyError = Exception('bad code');
      await pumpAuth(tester, api);
      await enterMobile(tester, '9876543210');
      await tester.tap(find.byKey(const Key('auth_login_send_otp')));
      await tester.pumpAndSettle();
      await enterOtp(tester, '123456');
      await tester.tap(find.byKey(const Key('auth_login_verify')));
      await tester.pumpAndSettle();
      expect(find.text(l10nOf(tester).authVerifyFailed), findsOneWidget);
    });
  });

  group('AuthScreen service-partner role', () {
    testWidgets('sp loads partners and verify carries the partner id',
        (tester) async {
      final api = FakeAuthApi()
        ..partners = [
          {'id': 'p1', 'trade_name': 'Acme'},
          {'id': 'p2', 'trade_name': 'Fixers'},
        ];
      await pumpAuth(tester, api);
      await tester.tap(find.byKey(const Key('auth_register_role_sp')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('auth_register_partner')), findsOneWidget);
      await enterMobile(tester, '9876543210');
      await tester.tap(find.byKey(const Key('auth_login_send_otp')));
      await tester.pumpAndSettle();
      await enterOtp(tester, '123456');
      await tester.tap(find.byKey(const Key('auth_login_verify')));
      await tester.pumpAndSettle();
      // Defaults to the first partner when untouched.
      expect(api.verified.single['partnerId'], 'p1');
      expect(api.verified.single['role'], 'service_partner');
    });

    testWidgets('choosing the second partner sticks', (tester) async {
      final api = FakeAuthApi()
        ..partners = [
          {'id': 'p1', 'trade_name': 'Acme'},
          {'id': 'p2', 'trade_name': 'Fixers'},
        ];
      await pumpAuth(tester, api);
      await tester.tap(find.byKey(const Key('auth_register_role_sp')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('auth_register_partner')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fixers').last);
      await tester.pumpAndSettle();
      await enterMobile(tester, '9876543210');
      await tester.tap(find.byKey(const Key('auth_login_send_otp')));
      await tester.pumpAndSettle();
      await enterOtp(tester, '123456');
      await tester.tap(find.byKey(const Key('auth_login_verify')));
      await tester.pumpAndSettle();
      expect(api.verified.single['partnerId'], 'p2');
    });

    testWidgets('empty partner list hides the select', (tester) async {
      await pumpAuth(tester, FakeAuthApi());
      await tester.tap(find.byKey(const Key('auth_register_role_sp')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('auth_register_partner')), findsNothing);
    });

    testWidgets('customer pill switches back', (tester) async {
      final api = FakeAuthApi()
        ..partners = [
          {'id': 'p1', 'trade_name': 'Acme'},
        ];
      await pumpAuth(tester, api);
      await tester.tap(find.byKey(const Key('auth_register_role_sp')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('auth_register_partner')), findsOneWidget);
      await tester.tap(find.byKey(const Key('auth_register_role_customer')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('auth_register_partner')), findsNothing);
    });
  });

  group('AuthScreen layouts', () {
    testWidgets('desktop brand pane shows tagline, points, and stats',
        (tester) async {
      desktopSize(tester);
      await pumpAuth(tester, FakeAuthApi());
      final l10n = l10nOf(tester);
      expect(find.text(l10n.tagline), findsOneWidget);
      expect(find.text(l10n.authBrandPoint1), findsOneWidget);
      expect(find.text(l10n.authBrandPoint2), findsOneWidget);
      expect(find.text(l10n.authBrandPoint3), findsOneWidget);
      expect(find.text('slots / day'), findsOneWidget);
      expect(find.text('OTP'), findsOneWidget);
    });

    testWidgets('compact layout keeps the full flow working', (tester) async {
      final api = FakeAuthApi();
      await pumpAuth(tester, api, compact: true);
      final l10n = l10nOf(tester);
      expect(find.text(l10n.appTitle), findsOneWidget);
      expect(find.text(l10n.authRegisterTitle), findsOneWidget);
      await enterMobile(tester, '9876543210');
      await tester.tap(find.byKey(const Key('auth_login_send_otp')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('auth_login_otp_input')), findsOneWidget);
    });
  });
}
