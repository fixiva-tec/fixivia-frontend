import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:fixvia/api/client.dart';
import 'package:fixvia/features/shells/pages/resource_pages.dart';

import '../../../helpers/test_helpers.dart';

ApiClient _api(Map<String, Object> gets, FakeHttp fake) {
  for (final e in gets.entries) {
    fake.routes[e.key] = (_) => FakeHttp.json(e.value);
  }
  return testApi(fake);
}

http.Request _lastWrite(FakeHttp fake) => fake.requests.lastWhere(
  (r) => r.method == 'POST' || r.method == 'PUT',
) as http.Request;

Map<String, dynamic> _posted(FakeHttp fake) =>
    jsonDecode(_lastWrite(fake).body) as Map<String, dynamic>;

/// ApiClient whose GETs fail like a 500. The failure is pre-ignored like the
/// FetchBody failure fixture: ignore() absorbs the unhandled-error report
/// while the page still receives the failure through its own subscription.
class _FailingGetApi extends ApiClient {
  _FailingGetApi() : super(baseUrl: 'http://test', httpClient: FakeHttp());

  @override
  Future<dynamic> get(String path) {
    final future = Future<dynamic>.error(ApiException('boom'));
    future.ignore();
    return future;
  }
}

void main() {
  group('BookingRowCard', () {
    Map<String, dynamic> booking({bool tech = true}) => {
      'id': 'b1',
      'service_date': '2026-10-20',
      'category_name': 'AC Repair',
      'slot': 'morning',
      'pincode': '682001',
      'quoted_amount': 500,
      'status': 'open',
      if (tech) 'technician_name': 'Ravi',
    };

    testWidgets('full row with technician and tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        shadHarness(
          BookingRowCard(
            booking: booking(),
            testId: 'row-1',
            onTap: () => tapped = true,
          ),
        ),
      );
      expect(find.text('AC Repair'), findsOneWidget);
      expect(find.text('Morning · 682001'), findsOneWidget);
      expect(find.text('₹500'), findsOneWidget);
      expect(find.text('Ravi'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('OCT'), findsOneWidget);
      expect(find.byKey(const Key('row-1')), findsOneWidget);
      await tester.tap(find.text('AC Repair'));
      expect(tapped, isTrue);
    });

    testWidgets('no technician, no tap, bad date', (tester) async {
      final b = booking(tech: false)..['service_date'] = 'junk';
      await tester.pumpWidget(shadHarness(BookingRowCard(booking: b)));
      expect(find.text('Ravi'), findsNothing);
      expect(find.text('—'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsNothing);
    });
  });

  group('PartnersPage', () {
    testWidgets('empty state', (tester) async {
      final fake = FakeHttp();
      await tester.pumpWidget(
        shadHarness(PartnersPage(api: _api({'/v1/partners': []}, fake))),
      );
      await tester.pumpAndSettle();
      expect(find.text('No partners yet'), findsOneWidget);
    });

    testWidgets('list, approve posts review and reloads', (tester) async {
      final fake = FakeHttp();
      final api = _api({
        '/v1/partners': [
          {
            'id': 'p1',
            'trade_name': 'FixCo',
            'legal_name': 'FixCo Pvt',
            'status': 'approved',
            'office_pincode': '682001',
            'personal_email': 'a@b.c',
            'license_fee_amount': 1000,
            'commission_percent': 20,
            'pincodes': ['682001', '682002'],
          },
          {
            'id': 'p2',
            'trade_name': 'NewCo',
            'org_type': 'LLP',
            'status': 'submitted',
            'office_pincode': '683101',
            'personal_email': 'n@n.c',
            'license_fee_amount': 500,
            'commission_percent': 15,
            'pincodes': [],
          },
        ],
      }, fake);
      await tester.pumpWidget(shadHarness(PartnersPage(api: api)));
      await tester.pumpAndSettle();
      expect(find.text('FixCo'), findsOneWidget);
      expect(find.text('682001, 682002'), findsOneWidget);
      expect(find.text('NewCo'), findsOneWidget);
      // Only the non-approved partner gets action buttons.
      expect(
        find.byKey(const Key('master_partner_approve_p2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('master_partner_approve_p1')),
        findsNothing,
      );
      final gets =
          fake.requests.where((r) => r.method == 'GET').length;
      await tester.ensureVisible(
        find.byKey(const Key('master_partner_approve_p2')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('master_partner_approve_p2')),
      );
      await tester.pumpAndSettle();
      expect(_lastWrite(fake).url.path, endsWith('/v1/partners/p2/review'));
      expect(_posted(fake)['status'], 'approved');
      expect(_posted(fake)['pincodes'], ['683101']);
      expect(
        fake.requests.where((r) => r.method == 'GET').length,
        greaterThan(gets),
      );
    });

    testWidgets('reject posts rejected; error shows retry', (tester) async {
      final fake = FakeHttp();
      final api = _api({
        '/v1/partners': [
          {
            'id': 'p9',
            'trade_name': 'Zed',
            'status': 'submitted',
            'office_pincode': null,
            'license_fee_amount': 0,
            'commission_percent': 10,
          },
        ],
      }, fake);
      await tester.pumpWidget(shadHarness(PartnersPage(api: api)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('master_partner_reject_p9')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('master_partner_reject_p9')));
      await tester.pumpAndSettle();
      expect(_posted(fake), {'status': 'rejected'});

      // Approve with null office pin sends an empty pincodes list.
      await tester.tap(
        find.byKey(const Key('master_partner_approve_p9')),
      );
      await tester.pumpAndSettle();
      expect(_posted(fake)['pincodes'], isEmpty);
    });

    testWidgets('load failure shows the error and retry', (tester) async {
      await tester.pumpWidget(
        shadHarness(PartnersPage(api: _FailingGetApi())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Could not load this page'), findsOneWidget);
      expect(find.textContaining('boom'), findsOneWidget);
      await tester.tap(find.byKey(const Key('app_fetch_retry')));
      await tester.pumpAndSettle();
      expect(find.text('Could not load this page'), findsOneWidget);
    });
  });

  group('CategoriesPage', () {
    testWidgets('empty state', (tester) async {
      final fake = FakeHttp();
      await tester.pumpWidget(
        shadHarness(CategoriesPage(api: _api({'/v1/categories': []}, fake))),
      );
      await tester.pumpAndSettle();
      expect(find.text('No categories yet'), findsOneWidget);
    });

    testWidgets('featured / active / inactive badges', (tester) async {
      final fake = FakeHttp();
      final api = _api({
        '/v1/categories': [
          {
            'name_en': 'Plumbing',
            'name_ml': 'പ്ലംബിംഗ്',
            'slug': 'plumbing',
            'featured_rank': 1,
            'estimated_minutes': 45,
            'problems': [1, 2],
          },
          {
            'name_en': 'Wiring',
            'description_en': 'desc',
            'slug': 'wiring',
            'is_active': false,
          },
          {'name_en': 'Paint', 'slug': 'paint'},
        ],
      }, fake);
      await tester.pumpWidget(shadHarness(CategoriesPage(api: api)));
      await tester.pumpAndSettle();
      expect(find.text('Plumbing'), findsOneWidget);
      expect(find.text('Featured #1'), findsOneWidget);
      expect(find.text('2 templates'), findsOneWidget);
      expect(find.text('45 min'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('60 min'), findsNWidgets(2));
    });
  });

  group('AdminRequestsPage', () {
    testWidgets('empty state', (tester) async {
      final fake = FakeHttp();
      await tester.pumpWidget(
        shadHarness(
          AdminRequestsPage(
            api: _api({'/v1/partner-admin-requests': []}, fake),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No partner-admin requests'), findsOneWidget);
    });

    testWidgets('submitted gets buttons, others do not', (tester) async {
      final fake = FakeHttp();
      final api = _api({
        '/v1/partner-admin-requests': [
          {
            'id': 'r1',
            'full_name': 'Anu',
            'email': 'anu@x.c',
            'mobile': '9000000001',
            'status': 'submitted',
          },
          {
            'id': 'r2',
            'full_name': 'Babu',
            'mobile': '9000000002',
            'status': 'approved',
          },
        ],
      }, fake);
      await tester.pumpWidget(shadHarness(AdminRequestsPage(api: api)));
      await tester.pumpAndSettle();
      expect(find.text('Anu'), findsOneWidget);
      expect(find.text('Babu'), findsOneWidget);
      expect(
        find.byKey(const Key('master_admin_approve_r1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('master_admin_approve_r2')),
        findsNothing,
      );
      await tester.ensureVisible(
        find.byKey(const Key('master_admin_approve_r1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('master_admin_approve_r1')));
      await tester.pumpAndSettle();
      expect(_posted(fake), {'status': 'approved'});

      await tester.tap(find.byKey(const Key('master_admin_reject_r1')));
      await tester.pumpAndSettle();
      expect(_posted(fake), {'status': 'rejected'});
    });
  });

  group('InvoicesPage', () {
    testWidgets('empty and filled', (tester) async {
      final fake = FakeHttp();
      final api = _api({'/v1/invoices': []}, fake);
      await tester.pumpWidget(shadHarness(InvoicesPage(api: api)));
      await tester.pumpAndSettle();
      expect(find.text('No invoices yet'), findsOneWidget);

      fake.routes['/v1/invoices'] = (_) => FakeHttp.json([
        {
          'amount': 1500,
          'period_start': '2026-10-01',
          'period_end': '2026-10-31',
          'status': 'overdue',
          'partner_id': 'p1',
        },
      ]);
      await tester.pumpWidget(shadHarness(InvoicesPage(api: api)));
      await tester.pumpAndSettle();
      expect(find.text('₹1500'), findsOneWidget);
      expect(find.text('2026-10-01 → 2026-10-31'), findsOneWidget);
      expect(find.text('p1'), findsOneWidget);
    });
  });

  group('AnalyticsPage', () {
    Map<String, dynamic> payload({bool median = true, bool partners = true}) => {
      'created': 10,
      'still_open': 2,
      'accepted': 5,
      'completed': 6,
      'cancelled': 1,
      'gmv_completed': 9000,
      'commission_completed': 900,
      if (median) 'median_accept_minutes': 12,
      'saas_license_fees': {
        'note': 'Q3',
        'invoiced': 3000,
        'collected': 2500,
        'overdue': 500,
      },
      if (partners)
        'by_partner': [
          {'trade_name': 'FixCo', 'created': 6, 'completed': 6},
          {'trade_name': 'NewCo', 'created': 0, 'completed': 0},
          {'trade_name': 'Bad', 'created': 'x', 'completed': 9},
        ],
    };

    testWidgets('metrics, medians, and partner bars', (tester) async {
      final fake = FakeHttp();
      final api = _api({'/v1/analytics': payload()}, fake);
      await tester.pumpWidget(
        shadHarness(AnalyticsPage(api: api, testId: 'm_analytics')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Created'), findsOneWidget);
      expect(find.text('₹9000'), findsOneWidget);
      expect(find.text('12 min'), findsOneWidget);
      expect(find.text('By partner'), findsOneWidget);
      expect(find.text('FixCo'), findsOneWidget);
      expect(find.text('6 / 6 done'), findsOneWidget);
      expect(find.text('0 / 0 done'), findsOneWidget);
      expect(find.byKey(const Key('m_analytics')), findsOneWidget);
    });

    testWidgets('narrow layout, no median, no partners', (tester) async {
      compactSize(tester);
      final fake = FakeHttp();
      final api = _api(
        {'/v1/analytics': payload(median: false, partners: false)},
        fake,
      );
      await tester.pumpWidget(
        shadHarness(AnalyticsPage(api: api, testId: 'm_analytics')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Median accept'), findsOneWidget);
      expect(find.text('By partner'), findsNothing);
    });
  });

  group('BookingsListPage', () {
    testWidgets('empty state', (tester) async {
      final fake = FakeHttp();
      await tester.pumpWidget(
        shadHarness(
          BookingsListPage(
            api: _api({'/v1/bookings': []}, fake),
            testId: 'mine',
            title: 'My bookings',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No bookings yet'), findsOneWidget);
    });

    testWidgets('rows open via onOpen; null id has no tap', (tester) async {
      final fake = FakeHttp();
      final api = _api({
        '/v1/sp/offers': [
          {
            'id': 'b1',
            'service_date': '2026-10-21',
            'category_name': 'Paint',
            'status': 'open',
          },
          {'category_name': 'NoId', 'status': 'open'},
        ],
      }, fake);
      String? opened;
      await tester.pumpWidget(
        shadHarness(
          BookingsListPage(
            api: api,
            testId: 'sp_offers',
            title: 'Offers',
            path: '/v1/sp/offers',
            onOpen: (id) => opened = id,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sp_offers_item_b1')), findsOneWidget);
      await tester.tap(find.text('Paint'));
      expect(opened, 'b1');
      expect(fake.requests.first.url.path, '/v1/sp/offers');
    });

    testWidgets('no onOpen renders rows without arrows', (tester) async {
      final fake = FakeHttp();
      final api = _api({
        '/v1/bookings': [
          {'id': 'b1', 'category_name': 'Paint', 'status': 'open'},
        ],
      }, fake);
      await tester.pumpWidget(
        shadHarness(
          BookingsListPage(api: api, testId: 'mine', title: 'Mine'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsNothing);
    });
  });

  group('PricingPage', () {
    testWidgets('empty state', (tester) async {
      final fake = FakeHttp();
      await tester.pumpWidget(
        shadHarness(
          PricingPage(
            api: _api({
              '/v1/partner/pricing': [],
              '/v1/categories': [],
            }, fake),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No pricing rows yet'), findsOneWidget);
    });

    testWidgets('known and unknown categories, enabled flags', (tester) async {
      final fake = FakeHttp();
      final api = _api({
        '/v1/partner/pricing': [
          {'category_id': 'c1', 'visit_charge': 499, 'enabled': true},
          {'category_id': 'c-missing', 'visit_charge': 199, 'enabled': false},
        ],
        '/v1/categories': [
          {'id': 'c1', 'name_en': 'Plumbing', 'slug': 'plumbing'},
        ],
      }, fake);
      await tester.pumpWidget(shadHarness(PricingPage(api: api)));
      await tester.pumpAndSettle();
      expect(find.text('Plumbing'), findsOneWidget);
      expect(find.text('₹499'), findsOneWidget);
      expect(find.text('Enabled'), findsOneWidget);
      expect(find.text('c-missing'), findsOneWidget);
      expect(find.text('Disabled'), findsOneWidget);
    });
  });

  group('SchedulePage', () {
    testWidgets('empty slots', (tester) async {
      final fake = FakeHttp();
      final api = _api({
        '/v1/sp/schedule': {
          'date': '2026-10-21',
          'morning': [],
          'evening': [],
        },
      }, fake);
      await tester.pumpWidget(shadHarness(SchedulePage(api: api)));
      await tester.pumpAndSettle();
      expect(find.text('Date 2026-10-21'), findsOneWidget);
      expect(find.text('No jobs · 09:00 – 13:00'), findsOneWidget);
      expect(find.text('No jobs · 13:00 – 18:00'), findsOneWidget);
    });

    testWidgets('route order with stops and dividers', (tester) async {
      final fake = FakeHttp();
      final api = _api({
        '/v1/sp/schedule': {
          'date': '2026-10-21',
          'morning': [
            {
              'category_name': 'AC Repair',
              'pincode': '682001',
              'status': 'accepted',
            },
            {'pincode': '682002', 'status': 'open'},
          ],
          'evening': [],
        },
      }, fake);
      await tester.pumpWidget(shadHarness(SchedulePage(api: api)));
      await tester.pumpAndSettle();
      expect(find.text('2 job(s) · 09:00 – 13:00'), findsOneWidget);
      expect(find.text('AC Repair'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
    });
  });

  group('EarningsPage', () {
    testWidgets('wide and narrow metric grids', (tester) async {
      final fake = FakeHttp();
      final api = _api({
        '/v1/sp/earnings': {'pending': 300, 'paid': 1200, 'jobs': 4},
      }, fake);
      await tester.pumpWidget(shadHarness(EarningsPage(api: api)));
      await tester.pumpAndSettle();
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('₹300'), findsOneWidget);
      expect(find.text('₹1200'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);

      compactSize(tester);
      await tester.pumpWidget(shadHarness(EarningsPage(api: api)));
      await tester.pumpAndSettle();
      expect(find.text('Pending'), findsOneWidget);
    });
  });
}
