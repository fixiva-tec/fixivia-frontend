import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:fixvia/api/client.dart';
import 'package:fixvia/core/session.dart';
import 'package:fixvia/features/customer/booking_flow.dart';
import 'package:fixvia/features/shells/workspace_shell.dart';

import '../../helpers/test_helpers.dart';

ApiClient _stub(Map<String, Object> gets, FakeHttp fake) {
  for (final e in gets.entries) {
    fake.routes[e.key] = (_) => FakeHttp.json(e.value);
  }
  return testApi(fake);
}

Widget _shell(ApiClient api, SessionUser user, {VoidCallback? onLogout}) =>
    shellHarness(WorkspaceShell(api: api, user: user, onLogout: onLogout));

Map<String, dynamic> _detail({
  String status = 'open',
  String? tech,
  bool ready = false,
}) => {
  'id': 'b1',
  'status': status,
  'category_name': 'AC Repair',
  'category_slug': 'ac-repair',
  'service_date': '2026-10-22',
  'slot': 'morning',
  'pincode': '682001',
  'quoted_amount': 500,
  'payment_mode': 'cash',
  'start_work_otp_hint': 'ends 42',
  if (tech != null) ...{
    'technician_name': tech,
    'technician_mobile_masked': 'XXXXXX2100',
  },
  if (ready) 'force_assign_ready': true,
};

http.Request _lastWrite(FakeHttp fake) => fake.requests.lastWhere(
  (r) => r.method == 'POST' || r.method == 'PUT',
) as http.Request;

Map<String, dynamic> _posted(FakeHttp fake) =>
    jsonDecode(_lastWrite(fake).body) as Map<String, dynamic>;

Future<void> _tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).first);
  await tester.pumpAndSettle();
}

void main() {
  group('role tabs', () {
    testWidgets('customer: home, bookings, addresses', (tester) async {
      final fake = FakeHttp();
      final api = _stub({
        '/v1/categories': [],
        '/v1/bookings': [],
        '/v1/addresses': [],
      }, fake);
      await tester.pumpWidget(
        _shell(api, testUser(UserRole.customer, fullName: 'Ravi Kumar')),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Ravi'), findsWidgets);
      expect(find.text('READY WHEN YOU ARE'), findsOneWidget);
      expect(find.byKey(const Key('nav_home')), findsOneWidget);

      await _tapTab(tester, 'Bookings');
      expect(find.text('Your bookings'), findsOneWidget);
      await _tapTab(tester, 'Addresses');
      expect(find.text('Saved places for home visits.'), findsOneWidget);
    });

    testWidgets('sp: inbox, schedule, earnings, profile, reports',
        (tester) async {
      final fake = FakeHttp();
      final api = _stub({
        '/v1/offers': [],
        '/v1/sp/schedule': {'morning': [], 'evening': []},
        '/v1/sp/earnings': {},
        '/v1/sp/profile': {},
        '/v1/analytics': {},
      }, fake);
      await tester.pumpWidget(_shell(api, testUser(UserRole.servicePartner)));
      await tester.pumpAndSettle();
      expect(find.text('Open offers'), findsOneWidget);
      await _tapTab(tester, 'Schedule');
      expect(find.text('Tomorrow’s schedule'), findsOneWidget);
      await _tapTab(tester, 'Earnings');
      expect(find.text('Partner-defined payouts for completed jobs.'),
          findsOneWidget);
      await _tapTab(tester, 'Profile');
      expect(find.text('KYC unlocks the offer inbox.'), findsOneWidget);
      await _tapTab(tester, 'Reports');
      expect(find.textContaining('Last 30 days'), findsOneWidget);
    });

    testWidgets('partner owner and admin share tabs', (tester) async {
      for (final role in [UserRole.partnerOwner, UserRole.partnerAdmin]) {
        final fake = FakeHttp();
        final api = _stub({
          '/v1/bookings': [],
          '/v1/sp/roster': [],
          '/v1/partner/pricing': [],
          '/v1/categories': [],
          '/v1/analytics': {},
        }, fake);
        await tester.pumpWidget(_shell(api, testUser(role)));
        await tester.pumpAndSettle();
        // Same-type re-pumps reuse shell state (selected tab included),
        // so later iterations start where the last one left off.
        await _tapTab(tester, 'Open');
        expect(find.text('Open requests'), findsOneWidget);
        expect(
          fake.requests.any(
            (r) => r.url.toString().contains('status=open'),
          ),
          isTrue,
        );
        await _tapTab(tester, 'Upcoming');
        expect(find.text('Bookings').first, findsOneWidget);
        await _tapTab(tester, 'Roster');
        expect(find.text('Service partners on your team.'), findsOneWidget);
        await _tapTab(tester, 'Pricing');
        expect(find.text('Visit pricing'), findsOneWidget);
        await _tapTab(tester, 'Analytics');
        expect(find.textContaining('Last 30 days'), findsOneWidget);
      }
    });

    testWidgets('master: partners, categories, admins, invoices, analytics',
        (tester) async {
      final fake = FakeHttp();
      final api = _stub({
        '/v1/partners': [],
        '/v1/categories': [],
        '/v1/partner-admin-requests': [],
        '/v1/invoices': [],
        '/v1/analytics': {},
      }, fake);
      await tester.pumpWidget(_shell(api, testUser(UserRole.masterAdmin)));
      await tester.pumpAndSettle();
      expect(find.text('Operation partners'), findsOneWidget);
      await _tapTab(tester, 'Categories');
      expect(find.text('Service categories'), findsOneWidget);
      await _tapTab(tester, 'Admins');
      expect(find.text('Partner admin requests'), findsOneWidget);
      await _tapTab(tester, 'Invoices');
      expect(find.text('SaaS invoices'), findsOneWidget);
      await _tapTab(tester, 'Analytics');
      expect(find.textContaining('Last 30 days'), findsOneWidget);
    });

    testWidgets('compact header shows the role label', (tester) async {
      // Wide-compact: narrow phones drop the badge (see app_workspace).
      tester.view.physicalSize = const Size(560, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const labels = {
        UserRole.customer: 'Customer',
        UserRole.servicePartner: 'Service partner',
        UserRole.partnerOwner: 'Partner owner',
        UserRole.partnerAdmin: 'Partner admin',
        UserRole.masterAdmin: 'Master admin',
      };
      for (final e in labels.entries) {
        final fake = FakeHttp();
        await tester.pumpWidget(_shell(testApi(fake), testUser(e.key)));
        await tester.pumpAndSettle();
        expect(find.text(e.value), findsWidgets);
      }
    });

    testWidgets('account menu logs out; default is a noop', (tester) async {
      final fake = FakeHttp();
      var loggedOut = 0;
      await tester.pumpWidget(
        _shell(
          _stub({'/v1/categories': [], '/v1/bookings': []}, fake),
          testUser(UserRole.customer, fullName: 'Ravi Kumar'),
          onLogout: () => loggedOut++,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shell_account_name')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shell_logout')));
      await tester.pump();
      expect(loggedOut, 1);

      // No callback: menu still opens and the tap is a noop.
      await tester.pumpWidget(
        _shell(
          _stub({'/v1/categories': [], '/v1/bookings': []}, FakeHttp()),
          testUser(UserRole.customer),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shell_account_name')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shell_logout')));
      await tester.pump();
    });
  });

  group('customer home', () {
    testWidgets('hero book button opens the flow', (tester) async {
      final fake = FakeHttp();
      final api = _stub({'/v1/categories': [], '/v1/bookings': []}, fake);
      await tester.pumpWidget(_shell(api, testUser(UserRole.customer)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('customer_home_book')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('customer_home_book')));
      await tester.pumpAndSettle();
      expect(find.byType(BookingFlow), findsOneWidget);
    });

    testWidgets('book-all action opens the flow', (tester) async {
      final fake = FakeHttp();
      final api = _stub({'/v1/categories': [], '/v1/bookings': []}, fake);
      await tester.pumpWidget(_shell(api, testUser(UserRole.customer)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('customer_home_book_all')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('customer_home_book_all')));
      await tester.pumpAndSettle();
      expect(find.byType(BookingFlow), findsOneWidget);
    });

    testWidgets('featured services filter the grid', (tester) async {
      final fake = FakeHttp();
      final api = _stub({
        '/v1/categories': [
          {'id': 'c1', 'name_en': 'Plumbing', 'slug': 'plumbing'},
          {
            'id': 'c2',
            'name_en': 'AC Repair',
            'slug': 'ac',
            'featured_rank': 1,
          },
        ],
        '/v1/bookings': [],
      }, fake);
      await tester.pumpWidget(_shell(api, testUser(UserRole.customer)));
      await tester.pumpAndSettle();
      expect(find.text('AC Repair'), findsOneWidget);
      expect(find.text('Plumbing'), findsNothing);

      await tester.ensureVisible(find.text('AC Repair'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('AC Repair'));
      await tester.pumpAndSettle();
      final flow =
          tester.widget<BookingFlow>(find.byType(BookingFlow));
      expect(flow.initialCategoryId, 'c2');
    });

    testWidgets('no featured ranks shows all; empty shows hint',
        (tester) async {
      final fake = FakeHttp();
      final api = _stub({
        '/v1/categories': [
          {'id': 'c1', 'name_en': 'Plumbing', 'slug': 'plumbing'},
        ],
        '/v1/bookings': [],
      }, fake);
      await tester.pumpWidget(_shell(api, testUser(UserRole.customer)));
      await tester.pumpAndSettle();
      expect(find.text('Plumbing'), findsOneWidget);

      fake.routes['/v1/categories'] = (_) => FakeHttp.json([]);
      await tester.pumpWidget(_shell(api, testUser(UserRole.customer)));
      await tester.pumpAndSettle();
      expect(find.text('No services yet.'), findsOneWidget);
    });

    testWidgets('compact grid uses two columns', (tester) async {
      compactSize(tester);
      final fake = FakeHttp();
      final api = _stub({
        '/v1/categories': [
          {'id': 'c1', 'name_en': 'Plumbing', 'slug': 'plumbing'},
        ],
        '/v1/bookings': [],
      }, fake);
      await tester.pumpWidget(_shell(api, testUser(UserRole.customer)));
      await tester.pumpAndSettle();
      expect(find.text('Plumbing'), findsOneWidget);
    });

    testWidgets('upcoming visits open the detail', (tester) async {
      final fake = FakeHttp();
      final api = _stub({
        '/v1/categories': [],
        '/v1/bookings': [
          {
            'id': 'b1',
            'category_name': 'AC Repair',
            'status': 'accepted',
            'service_date': '2026-10-22',
            'slot': 'morning',
            'pincode': '682001',
            'quoted_amount': 500,
          },
        ],
        '/v1/bookings/b1': _detail(status: 'accepted', tech: 'Ravi'),
      }, fake);
      await tester.pumpWidget(_shell(api, testUser(UserRole.customer)));
      await tester.pumpAndSettle();
      expect(find.text('Upcoming visits'), findsOneWidget);
      await tester.ensureVisible(find.text('AC Repair').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('AC Repair').first);
      await tester.pumpAndSettle();
      expect(find.text('Progress'), findsOneWidget);
    });

    testWidgets('view-all jumps to bookings; empty books', (tester) async {
      final fake = FakeHttp();
      final api = _stub({'/v1/categories': [], '/v1/bookings': []}, fake);
      await tester.pumpWidget(_shell(api, testUser(UserRole.customer)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('customer_home_view_bookings')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('customer_home_view_bookings')));
      await tester.pumpAndSettle();
      expect(find.text('Your bookings'), findsOneWidget);

      await _tapTab(tester, 'Home');
      await tester.ensureVisible(
        find.byKey(const Key('customer_home_book_empty')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('customer_home_book_empty')));
      await tester.pumpAndSettle();
      expect(find.byType(BookingFlow), findsOneWidget);
    });
  });

  group('booking detail', () {
    // Routes for one customer shell with a single booking. Callers
    // register these BEFORE openDetail; each test pumps exactly once
    // (re-pumps reuse shell state, including the selected tab).
    void detailRoutes(FakeHttp fake, Map<String, dynamic> body) {
      fake.routes['/v1/bookings'] = (_) => FakeHttp.json([
        {'id': 'b1', 'category_name': 'AC Repair', 'status': 'open'},
      ]);
      fake.routes['/v1/bookings/b1'] = (_) => FakeHttp.json(body);
      fake.routes['/v1/categories'] = (_) => FakeHttp.json([]);
    }

    Future<void> openDetail(WidgetTester tester, FakeHttp fake) async {
      await tester.pumpWidget(
        _shell(testApi(fake), testUser(UserRole.customer)),
      );
      await tester.pumpAndSettle();
      await _tapTab(tester, 'Bookings');
      await tester.ensureVisible(find.text('AC Repair'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('AC Repair'));
      await tester.pumpAndSettle();
      expect(find.text('Progress'), findsOneWidget);
    }

    // Any offer action reloads the detail page.
    Future<void> reloadDetail(
      WidgetTester tester, [
      String key = 'sp_offer_decline',
    ]) async {
      await tester.ensureVisible(find.byKey(Key(key)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
    }

    testWidgets('header, quote, otp hint, waiting tech', (tester) async {
      final fake = FakeHttp();
      detailRoutes(fake, _detail());
      await openDetail(tester, fake);
      expect(find.text('AC Repair'), findsOneWidget);
      expect(find.text('2026-10-22 · Morning · 682001'), findsOneWidget);
      expect(find.text('₹500'), findsOneWidget);
      expect(find.text('ends 42'), findsOneWidget);
      expect(find.text('Waiting for a technician'), findsOneWidget);
      expect(find.text('First accept wins the job'), findsOneWidget);
    });

    testWidgets('assigned tech row; literal null waits', (tester) async {
      final fake = FakeHttp();
      detailRoutes(fake, _detail(tech: 'Ravi'));
      // Keyed off the reload counter (?r=N), not fetch count, so
      // extra rebuilds can't shift the sequence.
      fake.routes['/v1/bookings/b1'] = (req) {
        final reloaded = req.url.queryParameters.containsKey('r');
        return FakeHttp.json(
          reloaded ? _detail(tech: 'null') : _detail(tech: 'Ravi'),
        );
      };
      await openDetail(tester, fake);
      expect(find.text('Ravi'), findsOneWidget);
      expect(find.text('XXXXXX2100'), findsOneWidget);
      expect(find.text('Assigned'), findsOneWidget);

      await reloadDetail(tester);
      expect(find.text('Waiting for a technician'), findsOneWidget);
    });

    testWidgets('progress steps across statuses', (tester) async {
      final bodies = [
        _detail(status: 'open'),
        _detail(status: 'accepted'),
        _detail(status: 'in_progress'),
        _detail(status: 'completed'),
        _detail(status: 'cancelled'),
        _detail(status: 'dropped'),
        _detail(status: 'declined'),
      ];
      // NB: fresh pump per status. This test covers step *rendering* only;
      // reload plumbing is covered by 'assigned tech row; literal null waits'.
      // The placeholder pump disposes the previous tree: pumpWidget reuses
      // State for the same root type, which would leave the old detail
      // route on the navigator (and a stale _reload behind).
      for (var i = 0; i < bodies.length; i++) {
        final fake = FakeHttp();
        detailRoutes(fake, bodies[i]);
        await tester.pumpWidget(Container());
        await tester.pumpAndSettle();
        await openDetail(tester, fake);
        switch (i) {
          case 4:
            expect(find.text('Booking Cancelled'), findsOneWidget);
          case 5:
            expect(find.text('Booking Dropped'), findsOneWidget);
          case 6:
            expect(find.text('Booking Declined'), findsOneWidget);
          default:
            expect(find.text('Done'), findsOneWidget);
        }
      }
    });

    testWidgets('offer actions post and reload', (tester) async {
      final fake = FakeHttp();
      detailRoutes(fake, _detail(tech: 'Ravi'));
      await openDetail(tester, fake);
      int gets() => fake.requests.where((r) => r.method == 'GET').length;

      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('sp_start_otp')),
          matching: find.byType(TextField),
        ),
        '123456',
      );
      await tester.ensureVisible(find.byKey(const Key('sp_start_work')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sp_start_work')));
      await tester.pumpAndSettle();
      expect(_lastWrite(fake).url.path, '/v1/bookings/b1/start');
      expect(_posted(fake), {'code': '123456'});

      final before = gets();
      for (final key in [
        'sp_offer_accept',
        'sp_offer_decline',
        'sp_complete',
        'sp_drop',
        'customer_booking_cancel',
      ]) {
        await tester.ensureVisible(find.byKey(Key(key)));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key(key)));
        await tester.pumpAndSettle();
      }
      expect(_posted(fake), isEmpty);
      expect(gets(), greaterThan(before));
      expect(
        fake.requests.lastWhere((r) => r.method == 'GET').url.query,
        contains('r='),
      );
      // Complete posts its own body; re-tap to assert it.
      await tester.ensureVisible(find.byKey(const Key('sp_complete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sp_complete')));
      await tester.pumpAndSettle();
      expect(_posted(fake), {'payment_mode': 'cash'});
    });

    testWidgets('action failure shows the error', (tester) async {
      final fake = FakeHttp();
      detailRoutes(fake, _detail());
      fake.routes['/v1/bookings/b1/accept'] =
          (_) => FakeHttp.json({'detail': 'too late'}, 409);
      await openDetail(tester, fake);
      await tester.ensureVisible(find.byKey(const Key('sp_offer_accept')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sp_offer_accept')));
      await tester.pumpAndSettle();
      expect(find.text('too late'), findsOneWidget);
    });

    testWidgets('detail fetch error shows an alert', (tester) async {
      final fake = FakeHttp();
      detailRoutes(fake, _detail());
      fake.routes['/v1/bookings/b1'] =
          (_) => FakeHttp.json({'detail': 'gone'}, 500);
      await tester.pumpWidget(
        _shell(testApi(fake), testUser(UserRole.customer)),
      );
      await tester.pumpAndSettle();
      await _tapTab(tester, 'Bookings');
      await tester.ensureVisible(find.text('AC Repair'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('AC Repair'));
      await tester.pumpAndSettle();
      expect(find.text('gone'), findsOneWidget);
    });
  });

  group('force assign', () {
    // Routes for one partner shell with a ready booking. Callers
    // register these BEFORE openReady; each test pumps exactly once.
    void readyRoutes(
      FakeHttp fake, {
      Object? assignable,
      int assignStatus = 200,
      bool ready = true,
    }) {
      fake.routes['/v1/bookings'] = (_) => FakeHttp.json([
        {'id': 'b1', 'category_name': 'AC Repair', 'status': 'open'},
      ]);
      fake.routes['/v1/bookings/b1'] =
          (_) => FakeHttp.json(_detail(ready: ready));
      fake.routes['/v1/categories'] = (_) => FakeHttp.json([]);
      fake.routes['/v1/bookings/b1/assignable'] =
          (_) => FakeHttp.json(assignable ?? {}, assignStatus);
    }

    Future<void> openReady(WidgetTester tester, FakeHttp fake) async {
      await tester.pumpWidget(
        _shell(testApi(fake), testUser(UserRole.partnerOwner)),
      );
      await tester.pumpAndSettle();
      await _tapTab(tester, 'Upcoming');
      await tester.ensureVisible(find.text('AC Repair'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('AC Repair'));
      await tester.pumpAndSettle();
    }

    // Reloading the detail also refetches the assignable list, since
    // the card builds its future inline.
    Future<void> refetchAssignable(WidgetTester tester) async {
      await tester.ensureVisible(
        find.byKey(const Key('sp_offer_decline')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sp_offer_decline')));
      await tester.pumpAndSettle();
    }

    testWidgets('hidden until the cycle fails', (tester) async {
      final fake = FakeHttp();
      readyRoutes(fake, ready: false);
      await openReady(tester, fake);
      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('Assign technician'), findsNothing);
    });

    testWidgets('pick and assign posts the selection', (tester) async {
      final fake = FakeHttp();
      readyRoutes(
        fake,
        assignable: {
          'ready': true,
          'technicians': [
            {'id': 't1', 'name': 'Ravi', 'jobs_in_slot': 1, 'slot_cap': 5},
            {'id': 't2', 'name': 'Anu', 'jobs_in_slot': 5, 'slot_cap': 5},
          ],
        },
      );
      await openReady(tester, fake);
      expect(find.text('Assign technician'), findsOneWidget);
      expect(find.text('Ravi · 1/5 this slot'), findsOneWidget);
      // Disabled until a technician is picked.
      await tester.ensureVisible(
        find.byKey(const Key('partner_assign_confirm')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('partner_assign_confirm')));
      await tester.pump();
      expect(
        fake.requests.any((r) => r.url.path.endsWith('force-assign')),
        isFalse,
      );
      await tester.ensureVisible(
        find.byKey(const Key('partner_assign_pick_t2')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('partner_assign_pick_t2')));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const Key('partner_assign_confirm')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('partner_assign_confirm')));
      await tester.pumpAndSettle();
      expect(_lastWrite(fake).url.path, '/v1/bookings/b1/force-assign');
      expect(_posted(fake), {'service_partner_id': 't2'});
    });

    testWidgets('assign failure shows the error', (tester) async {
      final fake = FakeHttp();
      readyRoutes(
        fake,
        assignable: {
          'ready': true,
          'technicians': [
            {'id': 't1', 'name': 'Ravi', 'jobs_in_slot': 1, 'slot_cap': 5},
          ],
        },
      );
      fake.routes['/v1/bookings/b1/force-assign'] =
          (_) => FakeHttp.json({'detail': 'slot full'}, 409);
      await openReady(tester, fake);
      await tester.ensureVisible(
        find.byKey(const Key('partner_assign_pick_t1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('partner_assign_pick_t1')));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const Key('partner_assign_confirm')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('partner_assign_confirm')));
      await tester.pumpAndSettle();
      expect(find.text('slot full'), findsOneWidget);
    });

    testWidgets('forbidden hides the card; errors alert', (tester) async {
      final fake = FakeHttp();
      readyRoutes(
        fake,
        assignable: {'detail': 'forbidden for role'},
        assignStatus: 403,
      );
      await openReady(tester, fake);
      expect(find.text('Progress'), findsOneWidget);
      // The card body collapses: no picker, no confirm, no hint.
      expect(
        find.byKey(const Key('partner_assign_confirm')),
        findsNothing,
      );
      expect(
        find.text('No eligible technicians right now.'),
        findsNothing,
      );

      fake.routes['/v1/bookings/b1/assignable'] =
          (_) => FakeHttp.json({'detail': 'boom'}, 500);
      await refetchAssignable(tester);
      expect(find.text('boom'), findsOneWidget);
    });

    testWidgets('not ready or empty shows the hint', (tester) async {
      final fake = FakeHttp();
      readyRoutes(fake, assignable: {'ready': false});
      await openReady(tester, fake);
      expect(
        find.text('No eligible technicians right now.'),
        findsOneWidget,
      );
      fake.routes['/v1/bookings/b1/assignable'] =
          (_) => FakeHttp.json({'ready': true, 'technicians': []});
      await refetchAssignable(tester);
      expect(
        find.text('No eligible technicians right now.'),
        findsOneWidget,
      );
    });
  });

  group('sp inbox', () {
    testWidgets('empty inbox', (tester) async {
      final fake = FakeHttp();
      await tester.pumpWidget(
        _shell(
          _stub({'/v1/offers': []}, fake),
          testUser(UserRole.servicePartner),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No open offers'), findsOneWidget);
    });

    testWidgets('offer rows, load math, and open', (tester) async {
      final fake = FakeHttp();
      fake.routes['/v1/offers'] = (_) => FakeHttp.json([
        {
          'id': 'o1',
          'category_name': 'AC Repair',
          'category_slug': 'ac',
          'pincode': '682001',
          'service_date': '2026-10-22',
          'slot': 'morning',
          'status': 'open',
          'slot_load': 2,
          'slot_cap': 5,
        },
        {
          'id': 'o2',
          'category_name': 'Paint',
          'pincode': '682002',
          'service_date': '2026-10-22',
          'slot': 'evening',
          'slot_load': 9,
          'slot_cap': 5,
        },
        {
          'id': 'o3',
          'category_name': 'Wire',
          'pincode': '682003',
          'service_date': '2026-10-22',
          'slot': 'evening',
          'slot_load': 1,
          'slot_cap': 0,
        },
      ]);
      fake.routes['/v1/bookings/o1'] =
          (_) => FakeHttp.json(_detail(tech: 'Ravi'));
      await tester.pumpWidget(
        _shell(testApi(fake), testUser(UserRole.servicePartner)),
      );
      await tester.pumpAndSettle();
      expect(find.text('AC Repair · 682001'), findsOneWidget);
      expect(find.text('Slot load 2 of 5'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
      expect(find.text('Slot load 9 of 5'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Slot load 1 of 0'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('sp_offer_open_o1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sp_offer_open_o1')));
      await tester.pumpAndSettle();
      expect(find.text('Progress'), findsOneWidget);
    });
  });

  group('addresses', () {
    testWidgets('empty state', (tester) async {
      final fake = FakeHttp();
      final api = _stub({'/v1/addresses': []}, fake);
      await tester.pumpWidget(_shell(api, testUser(UserRole.customer)));
      await tester.pumpAndSettle();
      await _tapTab(tester, 'Addresses');
      expect(find.text('No saved addresses'), findsOneWidget);
    });

    testWidgets('list marks the default; save posts', (tester) async {
      final fake = FakeHttp();
      final api = _stub({
        '/v1/categories': [],
        '/v1/bookings': [],
        '/v1/addresses': [
          {'line1': 'Home', 'pincode': '682001', 'is_default': true},
          {'line1': 'Office', 'pincode': '682002', 'is_default': false},
        ],
      }, fake);
      await tester.pumpWidget(_shell(api, testUser(UserRole.customer)));
      await tester.pumpAndSettle();
      await _tapTab(tester, 'Addresses');
      expect(find.text('Default'), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('customer_address_line1')),
          matching: find.byType(TextField),
        ),
        'MG Road',
      );
      await tester.tap(find.byKey(const Key('customer_address_save')));
      await tester.pumpAndSettle();
      expect(_lastWrite(fake).url.path, '/v1/addresses');
      expect(
        _posted(fake),
        {
          'label': 'home',
          'line1': 'MG Road',
          'pincode': '682001',
          'is_default': true,
        },
      );
    });
  });

  group('roster', () {
    testWidgets('empty state', (tester) async {
      final fake = FakeHttp();
      final api = _stub({'/v1/sp/roster': []}, fake);
      await tester.pumpWidget(_shell(api, testUser(UserRole.partnerOwner)));
      await tester.pumpAndSettle();
      await _tapTab(tester, 'Roster');
      expect(find.text('No technicians yet'), findsOneWidget);
    });

    testWidgets('kyc approve and reject post', (tester) async {
      final fake = FakeHttp();
      final api = _stub({
        '/v1/bookings': [],
        '/v1/sp/roster': [
          {
            'id': 's1',
            'full_name': 'Ravi',
            'mobile': '9000000001',
            'kyc_status': 'pending',
          },
          {
            'id': 's2',
            'full_name': 'Anu',
            'email': 'anu@x.c',
            'kyc_status': 'pending',
          },
        ],
      }, fake);
      await tester.pumpWidget(_shell(api, testUser(UserRole.partnerOwner)));
      await tester.pumpAndSettle();
      await _tapTab(tester, 'Roster');
      expect(find.text('anu@x.c'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('roster_approve_s1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('roster_approve_s1')));
      await tester.pumpAndSettle();
      expect(_posted(fake), {'status': 'approved'});
      await tester.ensureVisible(find.byKey(const Key('roster_reject_s2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('roster_reject_s2')));
      await tester.pumpAndSettle();
      expect(_posted(fake), {'status': 'rejected'});
    });
  });

  group('sp profile', () {
    testWidgets('pins render; kyc submit posts territory', (tester) async {
      final fake = FakeHttp();
      final api = _stub({
        '/v1/offers': [],
        '/v1/sp/schedule': {'morning': [], 'evening': []},
        '/v1/sp/earnings': {},
        '/v1/sp/profile': {
          'full_name': 'Ravi',
          'kyc_status': 'pending',
          'pincodes': ['682001', '682002'],
          'category_ids': ['c1'],
        },
      }, fake);
      await tester.pumpWidget(_shell(api, testUser(UserRole.servicePartner)));
      await tester.pumpAndSettle();
      await _tapTab(tester, 'Profile');
      expect(find.text('682001'), findsOneWidget);
      expect(find.text('682002'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('sp_kyc_submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sp_kyc_submit')));
      await tester.pumpAndSettle();
      expect(
        _posted(fake),
        {
          'pincodes': ['682001', '682002'],
          'category_ids': ['c1'],
          'aadhaar_path': 'local://masked-aadhaar',
          'police_path': 'local://police',
        },
      );
      expect(find.text('submitted'), findsOneWidget);
    });

    testWidgets('missing territory falls back; errors alert', (tester) async {
      final fake = FakeHttp();
      fake.routes['/v1/sp/profile'] = (_) => FakeHttp.json({
        'kyc_status': 'pending',
        'pincodes': [],
      });
      fake.routes['/v1/sp/profile_put'] =
          (_) => FakeHttp.json({'detail': 'no'}, 400);
      final api = testApi(fake);
      await tester.pumpWidget(_shell(api, testUser(UserRole.servicePartner)));
      await tester.pumpAndSettle();
      await _tapTab(tester, 'Profile');
      expect(find.text('Service partner'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);

      // Fail the PUT once, then let it succeed.
      var fails = 1;
      final orig = fake.routes['/v1/sp/profile']!;
      fake.routes['/v1/sp/profile'] = (req) {
        if (req.method == 'PUT' && fails > 0) {
          fails--;
          return FakeHttp.json({'detail': 'bad docs'}, 400);
        }
        return orig(req);
      };
      await tester.tap(find.byKey(const Key('sp_kyc_submit')));
      await tester.pumpAndSettle();
      expect(find.text('bad docs'), findsOneWidget);
      await tester.tap(find.byKey(const Key('sp_kyc_submit')));
      await tester.pumpAndSettle();
      expect(_posted(fake)['pincodes'], ['682001']);
      expect(_posted(fake)['category_ids'], []);
      expect(find.text('submitted'), findsOneWidget);
    });
  });
}
