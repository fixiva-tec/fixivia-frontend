import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:fixvia/features/auth/auth_api.dart';
import 'package:fixvia/features/auth/auth_screen.dart';
import 'package:fixvia/features/customer/booking_flow.dart';
import 'package:fixvia/features/landing/landing_page.dart';

import '../../helpers/test_helpers.dart';

List<Map<String, dynamic>> landingCats() => [
  {
    'id': 'c-ac',
    'name_en': 'AC Repair',
    'slug': 'ac-repair',
    'featured_rank': 1,
    'problems': [
      {'id': 'p1', 'text_en': 'Not cooling', 'featured_rank': 1},
    ],
  },
  {
    'id': 'c-pl',
    'name_en': 'Plumbing',
    'slug': 'plumbing',
    'featured_rank': null,
    'problems': [],
  },
];

List<Map<String, dynamic>> servedPins() => [
  {'pincode': '682001', 'district': 'Ernakulam', 'locality': 'Kochi', 'state': 'Kerala'},
];

FakeHttp landingHttp({Object? bookings}) {
  return FakeHttp({
    '/v1/categories': (_) => FakeHttp.json(landingCats()),
    '/v1/pincodes': (_) => FakeHttp.json(servedPins()),
    '/v1/addresses': (_) => FakeHttp.json({'id': 'a9'}),
    '/v1/bookings': (_) => FakeHttp.json(bookings ?? {'id': 'b9'}),
  });
}

Future<void> pumpLanding(
  WidgetTester tester,
  FakeHttp fake, {
  FakeAuthApi? auth,
  void Function(AuthResult result)? onAuthenticated,
}) async {
  desktopSize(tester);
  await tester.pumpWidget(
    shellHarness(
      LandingPage(
        api: testApi(fake),
        authApi: auth ?? FakeAuthApi(),
        onAuthenticated: onAuthenticated ?? (_) {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> loginThroughUi(WidgetTester tester, [String mobile = '9000000004']) async {
  await tester.tap(find.byKey(const Key('auth_mode_login')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.descendant(
      of: find.byKey(const Key('auth_login_mobile')),
      matching: find.byType(TextField),
    ),
    mobile,
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

Future<void> walkGuestFlow(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('landing_book')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const Key('customer_booking_category_ac-repair')),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('customer_booking_next')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('customer_booking_problem_p1')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('customer_booking_next')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('customer_booking_next')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.descendant(
      of: find.byKey(const Key('customer_booking_guest_line')),
      matching: find.byType(TextField),
    ),
    '12 Palm St',
  );
  await tester.enterText(
    find.descendant(
      of: find.byKey(const Key('customer_booking_guest_pin')),
      matching: find.byType(TextField),
    ),
    '682001',
  );
  await tester.pumpAndSettle();
}

void main() {
  group('LandingPage content', () {
    testWidgets('header, hero, services, and served pincodes', (tester) async {
      await pumpLanding(tester, landingHttp());
      expect(find.byKey(const Key('landing_login')), findsOneWidget);
      expect(find.text('Home services at your doorstep'), findsOneWidget);
      expect(find.text('AC Repair'), findsOneWidget);
      expect(find.text('Plumbing'), findsOneWidget);
      expect(find.text('Not cooling'), findsOneWidget);
      expect(find.text('682001'), findsWidgets);
      expect(find.text('Why Fixiva'), findsOneWidget);
      expect(find.text('How it works'), findsOneWidget);
    });

    testWidgets('load failure shows the error', (tester) async {
      final fake = FakeHttp({
        '/v1/categories': (_) => FakeHttp.json({'detail': 'boom'}, 500),
        '/v1/pincodes': (_) => FakeHttp.json([]),
      });
      await pumpLanding(tester, fake);
      expect(find.text('boom'), findsOneWidget);
    });
  });

  group('LandingPage pincode checker', () {
    testWidgets('served pincode cheers', (tester) async {
      await pumpLanding(tester, landingHttp());
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('landing_pin_input')),
          matching: find.byType(TextField),
        ),
        '682001',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('landing_pin_check')));
      await tester.pumpAndSettle();
      expect(find.text('Yes — we serve 682001. Book below.'), findsOneWidget);
    });

    testWidgets('unserved pincode warns', (tester) async {
      await pumpLanding(tester, landingHttp());
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('landing_pin_input')),
          matching: find.byType(TextField),
        ),
        '695001',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('landing_pin_check')));
      await tester.pumpAndSettle();
      expect(
        find.text('Not in 695001 yet — we are expanding soon.'),
        findsOneWidget,
      );
    });

    testWidgets('short input asks for six digits', (tester) async {
      await pumpLanding(tester, landingHttp());
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('landing_pin_input')),
          matching: find.byType(TextField),
        ),
        '682',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('landing_pin_check')));
      await tester.pumpAndSettle();
      expect(find.text('Enter a 6-digit pincode'), findsOneWidget);
    });
  });

  group('LandingPage auth entry', () {
    testWidgets('login button opens auth and returns the result', (tester) async {
      AuthResult? authed;
      await pumpLanding(
        tester,
        landingHttp(),
        onAuthenticated: (r) => authed = r,
      );
      await tester.tap(find.byKey(const Key('landing_login')));
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
      await loginThroughUi(tester);
      expect(authed, isNotNull);
      expect(authed!.token, 'tok-9000000004');
      expect(find.byType(AuthScreen), findsNothing);
    });

    testWidgets('service row opens the flow preselected', (tester) async {
      await pumpLanding(tester, landingHttp());
      await tester.ensureVisible(find.text('Plumbing'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('landing_service_plumbing')));
      await tester.pumpAndSettle();
      expect(find.byType(BookingFlow), findsOneWidget);
      // Preselected: Next moves straight to problems.
      await tester.tap(find.byKey(const Key('customer_booking_next')));
      await tester.pumpAndSettle();
      expect(
        find.text('Step 2 of 4 · Describe the problem'),
        findsOneWidget,
      );
    });
  });

  group('LandingPage guest gate', () {
    testWidgets('confirm routes to login then submits the draft', (tester) async {
      AuthResult? authed;
      final fake = landingHttp();
      final api = testApi(fake);
      desktopSize(tester);
      await tester.pumpWidget(
        shellHarness(
          LandingPage(
            api: api,
            authApi: FakeAuthApi(),
            onAuthenticated: (r) => authed = r,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await walkGuestFlow(tester);
      await tester.tap(find.byKey(const Key('customer_booking_next')));
      await tester.pumpAndSettle();
      // Gate: auth pushed, nothing submitted yet.
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(
        fake.requests.any(
          (r) => r.method == 'POST' && r.url.path == '/v1/bookings',
        ),
        isFalse,
      );
      await loginThroughUi(tester);
      // Submitted after login: address first, then the booking.
      http.Request lastWrite(String path) => fake.requests.lastWhere(
        (r) => r.method == 'POST' && r.url.path == path,
      ) as http.Request;
      final addrBody =
          jsonDecode(lastWrite('/v1/addresses').body) as Map<String, dynamic>;
      expect(addrBody['line1'], '12 Palm St');
      expect(addrBody['pincode'], '682001');
      final bookBody =
          jsonDecode(lastWrite('/v1/bookings').body) as Map<String, dynamic>;
      expect(bookBody['address_id'], 'a9');
      expect(bookBody['category_id'], 'c-ac');
      expect(bookBody['issue_template_ids'], equals(['p1']));
      expect(bookBody['slot'], 'morning');
      expect(authed, isNotNull);
      expect(api.token, 'tok-9000000004');
      expect(find.byType(BookingFlow), findsNothing);
    });

    testWidgets('backing out of auth keeps the draft', (tester) async {
      var authed = false;
      await pumpLanding(
        tester,
        landingHttp(),
        onAuthenticated: (_) => authed = true,
      );
      await walkGuestFlow(tester);
      await tester.tap(find.byKey(const Key('customer_booking_next')));
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
      Navigator.of(tester.element(find.byType(AuthScreen))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsNothing);
      expect(find.byType(BookingFlow), findsOneWidget);
      expect(authed, isFalse);
    });

    testWidgets('unserved pincode never reaches auth', (tester) async {
      await pumpLanding(tester, landingHttp());
      await tester.tap(find.byKey(const Key('landing_book')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('customer_booking_category_ac-repair')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('customer_booking_next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('customer_booking_problem_p1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('customer_booking_next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('customer_booking_next')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('customer_booking_guest_line')),
          matching: find.byType(TextField),
        ),
        '12 Palm St',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('customer_booking_guest_pin')),
          matching: find.byType(TextField),
        ),
        '695001',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('customer_booking_next')));
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsNothing);
      expect(find.text("We don't serve 695001 yet"), findsOneWidget);
    });

    testWidgets('submit failure restores the guest', (tester) async {
      AuthResult? authed;
      final fake = FakeHttp({
        '/v1/categories': (_) => FakeHttp.json(landingCats()),
        '/v1/pincodes': (_) => FakeHttp.json(servedPins()),
        '/v1/addresses': (_) => FakeHttp.json({'id': 'a9'}),
        '/v1/bookings': (_) =>
            FakeHttp.json({'detail': 'no_partner_for_pincode'}, 400),
      });
      final api = testApi(fake);
      desktopSize(tester);
      await tester.pumpWidget(
        shellHarness(
          LandingPage(
            api: api,
            authApi: FakeAuthApi(),
            onAuthenticated: (r) => authed = r,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await walkGuestFlow(tester);
      await tester.tap(find.byKey(const Key('customer_booking_next')));
      await tester.pumpAndSettle();
      await loginThroughUi(tester);
      expect(find.text('no_partner_for_pincode'), findsOneWidget);
      expect(find.byType(BookingFlow), findsOneWidget);
      expect(authed, isNull);
      expect(api.token, isNull);
    });
  });
}
