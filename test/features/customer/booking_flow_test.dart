import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:fixvia/core/theme/components/components.dart';
import 'package:fixvia/features/customer/booking_flow.dart';
import 'package:fixvia/features/customer/guest_draft.dart';

import '../../helpers/test_helpers.dart';

List<Map<String, dynamic>> testCats() => [
  {
    'id': 'c-wp',
    'name_en': 'Water purifier repair',
    'slug': 'water-purifier-repair',
    'featured_rank': 1,
    'problems': [
      {'id': 'p1', 'text_en': 'No water flow', 'featured_rank': 1},
      {'id': 'p2', 'text_en': 'Filter change due', 'featured_rank': null},
    ],
  },
  {
    'id': 'c-ac',
    'name_en': 'AC Repair',
    'slug': 'ac-repair',
    'featured_rank': 2,
    'problems': [],
  },
  {
    'id': 'c-pl',
    'name_en': 'Plumbing',
    'slug': 'plumbing',
    'featured_rank': null,
    'problems': [],
  },
];

List<Map<String, dynamic>> testAddrs() => [
  {'id': 'a1', 'label': 'Home', 'pincode': '682001'},
  {'id': 'a2', 'label': 'Office', 'pincode': '682002'},
];

FakeHttp flowHttp({
  Object? bookings,
  List<Map<String, dynamic>>? addrs,
  void Function(Map<String, dynamic>)? onBook,
}) {
  return FakeHttp({
    '/v1/categories': (_) => FakeHttp.json(testCats()),
    '/v1/addresses': (_) => FakeHttp.json(addrs ?? testAddrs()),
    '/v1/bookings': (req) {
      final body = jsonDecode((req as http.Request).body);
      onBook?.call(body as Map<String, dynamic>);
      if (bookings is Exception) throw bookings;
      return FakeHttp.json(bookings ?? {'id': 'b1'});
    },
  });
}

Future<void> pumpFlow(
  WidgetTester tester,
  FakeHttp fake, {
  String? initialCategoryId,
  bool dark = false,
  String? token = 'tok-test',
  Future<void> Function(GuestDraft draft)? onGuestConfirm,
  Set<String>? bookableSlugs,
}) async {
  // Desktop height: the loading skeleton and tall steps need more
  // than the 600px default viewport.
  desktopSize(tester);
  await tester.pumpWidget(
    materialHarness(
      BookingFlow(
        api: testApi(fake, token: token),
        initialCategoryId: initialCategoryId,
        onGuestConfirm: onGuestConfirm,
        bookableSlugs: bookableSlugs,
      ),
      dark: dark,
    ),
  );
  await tester.pumpAndSettle();
}

/// Full-catalog override for tests covering states the launch set
/// cannot reach (e.g. problem-less categories).
const _allLive = {'water-purifier-repair', 'ac-repair', 'plumbing'};

Future<void> next(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('customer_booking_next')));
  await tester.pumpAndSettle();
}

Future<void> back(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('customer_booking_back')));
  await tester.pumpAndSettle();
}

void main() {
  group('BookingFlow loading', () {
    testWidgets('skeleton first, Next disabled until loaded', (tester) async {
      desktopSize(tester);
      // Gate categories so the skeleton is observable; an instant fake
      // would load before the first frame paints.
      final gate = Completer<List<Map<String, dynamic>>>();
      final fake = FakeHttp({
        '/v1/categories': (_) => gate.future.then(FakeHttp.json),
        '/v1/addresses': (_) => FakeHttp.json([]),
      });
      await tester.pumpWidget(
        materialHarness(BookingFlow(api: testApi(fake, token: 'tok-test'))),
      );
      await tester.pump();
      expect(find.byType(LoadingSkeleton), findsOneWidget);
      expect(find.byType(GridView), findsNothing);
      await tester.tap(find.byKey(const Key('customer_booking_next')));
      await tester.pump();
      expect(find.text('Step 2 of 4 · Describe the problem'), findsNothing);
      gate.complete(testCats());
      await tester.pumpAndSettle();
      expect(find.text('What do you need?'), findsOneWidget);
    });

    testWidgets('unmount mid-load is a safe no-op', (tester) async {
      desktopSize(tester);
      await tester.pumpWidget(
        materialHarness(BookingFlow(api: testApi(flowHttp(), token: 'tok-test'))),
      );
      await tester.pumpWidget(materialHarness(const SizedBox()));
      await tester.pumpAndSettle();
    });

    testWidgets('load failure shows the error', (tester) async {
      desktopSize(tester);
      final fake = FakeHttp({
        '/v1/categories': (_) => FakeHttp.json({'detail': 'boom'}, 500),
        '/v1/addresses': (_) => FakeHttp.json([]),
      });
      await tester.pumpWidget(
        materialHarness(BookingFlow(api: testApi(fake, token: 'tok-test'))),
      );
      await tester.pumpAndSettle();
      expect(find.text('boom'), findsOneWidget);
    });
  });

  group('BookingFlow step 0 categories', () {
    testWidgets('featured grid plus other dropdown', (tester) async {
      await pumpFlow(tester, flowHttp());
      expect(find.text('Water purifier repair'), findsOneWidget);
      expect(find.byKey(const Key('customer_booking_category_water-purifier-repair')),
          findsOneWidget);
      // Featured but not live: dimmed with a soon suffix.
      expect(find.text('AC Repair · soon'), findsOneWidget);
      // Non-featured lives only in the dropdown.
      expect(find.byKey(const Key('customer_booking_category_other')),
          findsOneWidget);
    });

    testWidgets('grid columns follow width (2 / 3 / 4)', (tester) async {
      Future<int> colsAt(double width) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          materialHarness(BookingFlow(api: testApi(flowHttp(), token: 'tok-test'))),
        );
        await tester.pumpAndSettle();
        final grid = tester.widget<GridView>(find.byType(GridView));
        final delegate =
            grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
        return delegate.crossAxisCount;
      }

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      expect(await colsAt(390), 2);
      expect(await colsAt(500), 3);
      expect(await colsAt(1280), 4);
    });

    testWidgets('initialCategoryId preselects', (tester) async {
      await pumpFlow(tester, flowHttp(), initialCategoryId: 'c-wp');
      expect(
        find.descendant(
          of: find.byKey(const Key('customer_booking_category_water-purifier-repair')),
          matching: find.byIcon(Icons.check_circle_rounded),
        ),
        findsOneWidget,
      );
    });

    testWidgets('guard blocks Next without a category', (tester) async {
      await pumpFlow(tester, flowHttp());
      expect(find.byKey(const Key('customer_booking_back')), findsNothing);
      await next(tester);
      expect(find.text('Pick a category'), findsOneWidget);
      expect(find.text('Step 1 of 4 · Choose a service'), findsOneWidget);
    });

    testWidgets('bogus preselect reaches the empty problem state',
        (tester) async {
      await pumpFlow(tester, flowHttp(), initialCategoryId: 'zzz');
      await next(tester);
      expect(find.text('Pick a category first'), findsOneWidget);
    });
  });

  group('BookingFlow step 1 problems', () {
    Future<void> toProblems(WidgetTester tester, FakeHttp fake) async {
      await pumpFlow(tester, fake);
      await tester.tap(
        find.byKey(const Key('customer_booking_category_water-purifier-repair')),
      );
      await tester.pumpAndSettle();
      await next(tester);
    }

    testWidgets('featured and other problems toggle with a counter',
        (tester) async {
      await toProblems(tester, flowHttp());
      expect(find.text('What’s wrong?'), findsOneWidget);
      expect(find.text('Other issues'), findsOneWidget);
      expect(find.text('0 picked'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('customer_booking_problem_p1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('customer_booking_problem_other_p2')),
      );
      await tester.pumpAndSettle();
      expect(find.text('2 picked'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('customer_booking_problem_p1')),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 picked'), findsOneWidget);
    });

    testWidgets('guard blocks Next with no problems picked', (tester) async {
      await toProblems(tester, flowHttp());
      await next(tester);
      expect(find.text('Pick at least one problem'), findsOneWidget);
    });

    testWidgets('category without problems shows no choices', (tester) async {
      await pumpFlow(tester, flowHttp(), bookableSlugs: _allLive);
      await tester.tap(
        find.byKey(const Key('customer_booking_category_other')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plumbing').last);
      await tester.pumpAndSettle();
      await next(tester);
      expect(find.text('Other issues'), findsNothing);
      expect(find.text('0 picked'), findsOneWidget);
    });
  });

  group('BookingFlow step 2 review', () {
    Future<void> toReview(
      WidgetTester tester,
      FakeHttp fake, {
      Set<String>? bookableSlugs,
    }) async {
      await pumpFlow(tester, fake, bookableSlugs: bookableSlugs);
      await tester.tap(
        find.byKey(const Key('customer_booking_category_water-purifier-repair')),
      );
      await tester.pumpAndSettle();
      await next(tester);
      await tester.tap(
        find.byKey(const Key('customer_booking_problem_p1')),
      );
      await tester.pumpAndSettle();
      await next(tester);
    }

    testWidgets('hero, problems, address, and visit rows', (tester) async {
      await toReview(tester, flowHttp());
      expect(find.text('Step 3 of 4 · Review your request'), findsOneWidget);
      expect(find.text('YOUR REQUEST'), findsOneWidget);
      expect(find.text('Water purifier repair'), findsWidgets);
      expect(find.text('No water flow'), findsOneWidget);
      expect(find.text('Home 682001'), findsOneWidget);
      expect(find.textContaining('Morning 09–13'), findsOneWidget);
      expect(find.textContaining(RegExp(r'\d{4}-\d{2}-\d{2}')), findsWidgets);
    });

    testWidgets('edit buttons jump to their steps', (tester) async {
      await toReview(tester, flowHttp());
      await tester.tap(
        find.byKey(const Key('customer_booking_edit_problems')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 4 · Describe the problem'), findsOneWidget);
      await next(tester);
      await tester.tap(
        find.byKey(const Key('customer_booking_edit_address')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Step 4 of 4 · Pick a visit slot'), findsOneWidget);
      await back(tester);
      await tester.tap(
        find.byKey(const Key('customer_booking_edit_schedule')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Step 4 of 4 · Pick a visit slot'), findsOneWidget);
    });

    testWidgets('switching category after picking shows an empty list',
        (tester) async {
      final fake = flowHttp();
      await toReview(tester, fake, bookableSlugs: _allLive);
      await back(tester);
      await back(tester);
      await tester.tap(
        find.byKey(const Key('customer_booking_category_other')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plumbing').last);
      await tester.pumpAndSettle();
      await next(tester);
      await next(tester); // stale pick satisfies the guard
      expect(find.text('Plumbing'), findsWidgets);
      expect(find.text('No water flow'), findsNothing);
    });

    testWidgets('no addresses renders dashes and hides the select',
        (tester) async {
      final fake = flowHttp(addrs: []);
      await toReview(tester, fake);
      expect(find.text('—'), findsWidgets);
      await next(tester);
      expect(find.byKey(const Key('customer_booking_address')), findsNothing);
    });

    testWidgets('back clears the error', (tester) async {
      await pumpFlow(tester, flowHttp());
      await next(tester);
      expect(find.text('Pick a category'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('customer_booking_category_water-purifier-repair')),
      );
      await tester.pumpAndSettle();
      await next(tester);
      await back(tester);
      expect(find.text('Pick a category'), findsNothing);
      expect(find.text('Step 1 of 4 · Choose a service'), findsOneWidget);
    });
  });

  group('BookingFlow step 3 schedule', () {
    Future<void> toSchedule(WidgetTester tester, FakeHttp fake) async {
      await pumpFlow(tester, fake);
      await tester.tap(
        find.byKey(const Key('customer_booking_category_water-purifier-repair')),
      );
      await tester.pumpAndSettle();
      await next(tester);
      await tester.tap(
        find.byKey(const Key('customer_booking_problem_p1')),
      );
      await tester.pumpAndSettle();
      await next(tester);
      await next(tester);
    }

    testWidgets('address change, day pick, and slot switch', (tester) async {
      await toSchedule(tester, flowHttp());
      await tester.tap(find.byKey(const Key('customer_booking_address')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Office 682002').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('customer_booking_day_3')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('customer_booking_slot_evening')),
      );
      await tester.pumpAndSettle();
      await back(tester);
      expect(find.text('Office 682002'), findsOneWidget);
      expect(find.textContaining('Evening 13–18'), findsOneWidget);
    });

    testWidgets('calendar opens and closes without changing the date',
        (tester) async {
      await toSchedule(tester, flowHttp());
      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsNothing);

      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsNothing);
    });
  });

  group('BookingFlow submit', () {
    testWidgets('confirm posts the payload and pops true', (tester) async {
      Map<String, dynamic>? posted;
      Object? popped;
      final fake = flowHttp(
        onBook: (body) => posted = Map<String, dynamic>.from(body),
      );
      await tester.pumpWidget(
        materialHarness(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                popped = await Navigator.of(context).push(
                  MaterialPageRoute<bool>(
                    builder: (_) => BookingFlow(api: testApi(fake, token: 'tok-test')),
                  ),
                );
              },
              child: const Text('Go'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('customer_booking_category_water-purifier-repair')),
      );
      await tester.pumpAndSettle();
      await next(tester);
      await tester.tap(
        find.byKey(const Key('customer_booking_problem_p1')),
      );
      await tester.pumpAndSettle();
      await next(tester);
      await next(tester);
      expect(find.text('Confirm booking'), findsOneWidget);
      await tester.tap(find.byKey(const Key('customer_booking_next')));
      await tester.pumpAndSettle();
      expect(find.text('Booking confirmed!'), findsOneWidget);
      expect(popped, isNull);
      await tester.tap(find.byKey(const Key('booking_confirmed_done')));
      await tester.pumpAndSettle();
      expect(popped, isTrue);
      expect(posted!['address_id'], 'a1');
      expect(posted!['category_id'], 'c-wp');
      expect(posted!['issue_template_ids'], equals(['p1']));
      expect(
        posted!['service_date'],
        matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')),
      );
      expect(posted!['slot'], 'morning');
    });

    testWidgets('submit failure shows the error and stays', (tester) async {
      final fake = flowHttp(
        bookings: Exception('slot taken'),
      );
      await pumpFlow(tester, fake);
      await tester.tap(
        find.byKey(const Key('customer_booking_category_water-purifier-repair')),
      );
      await tester.pumpAndSettle();
      await next(tester);
      await tester.tap(
        find.byKey(const Key('customer_booking_problem_p1')),
      );
      await tester.pumpAndSettle();
      await next(tester);
      await next(tester);
      await tester.tap(find.byKey(const Key('customer_booking_next')));
      await tester.pumpAndSettle();
      expect(find.textContaining('slot taken'), findsOneWidget);
      expect(find.text('Step 4 of 4 · Pick a visit slot'), findsOneWidget);
    });
  });

  group('BookingFlow coming soon', () {
    testWidgets('tapping a soon card shows error and stays', (tester) async {
      await pumpFlow(tester, flowHttp());
      await tester.tap(
        find.byKey(const Key('customer_booking_category_ac-repair')),
      );
      await tester.pumpAndSettle();
      expect(find.text('AC Repair is coming soon'), findsOneWidget);
      expect(find.text('Step 1 of 4 · Choose a service'), findsOneWidget);
    });

    testWidgets('override makes soon cards selectable', (tester) async {
      await pumpFlow(tester, flowHttp(), bookableSlugs: _allLive);
      await tester.tap(
        find.byKey(const Key('customer_booking_category_ac-repair')),
      );
      await tester.pumpAndSettle();
      expect(find.text('AC Repair is coming soon'), findsNothing);
      await next(tester);
      expect(find.text('Step 2 of 4 · Describe the problem'), findsOneWidget);
    });
  });

  group('BookingFlow stepper', () {
    testWidgets('labels render, past steps check off', (tester) async {
      await pumpFlow(tester, flowHttp());
      for (final label in ['Service', 'Problem', 'Review', 'Schedule']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byIcon(Icons.check_rounded), findsNothing);
      await tester.tap(
        find.byKey(const Key('customer_booking_category_water-purifier-repair')),
      );
      await tester.pumpAndSettle();
      await next(tester);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });
  });

  group('BookingFlow dark mode', () {
    testWidgets('cards, day strip, and slots build under dark', (tester) async {
      await pumpFlow(tester, flowHttp(), dark: true);
      expect(find.text('Water purifier repair'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('customer_booking_category_water-purifier-repair')),
      );
      await tester.pumpAndSettle();
      await next(tester);
      await tester.tap(
        find.byKey(const Key('customer_booking_problem_p1')),
      );
      await tester.pumpAndSettle();
      await next(tester);
      await next(tester);
      expect(find.byKey(const Key('customer_booking_day_0')), findsOneWidget);
      expect(
        find.byKey(const Key('customer_booking_slot_morning')),
        findsOneWidget,
      );
    });
  });

  group('InfoLine', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(
        themeHarness(const InfoLine(label: 'Status', value: 'Open')),
      );
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
    });
  });

  group('BookingFlow guest mode', () {
    Future<void> toSchedule(
      WidgetTester tester,
      FakeHttp fake, {
      Future<void> Function(GuestDraft draft)? onGuestConfirm,
    }) async {
      await pumpFlow(tester, fake, token: null, onGuestConfirm: onGuestConfirm);
      await tester.tap(
        find.byKey(const Key('customer_booking_category_water-purifier-repair')),
      );
      await tester.pumpAndSettle();
      await next(tester);
      await tester.tap(
        find.byKey(const Key('customer_booking_problem_p1')),
      );
      await tester.pumpAndSettle();
      await next(tester);
      await next(tester);
    }

    Future<void> fillGuestAddress(WidgetTester tester) async {
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

    testWidgets('skips saved addresses and shows the form', (tester) async {
      final fake = flowHttp();
      await pumpFlow(tester, fake, token: null, onGuestConfirm: (_) async {});
      expect(
        fake.requests.any(
          (r) => r.method == 'GET' && r.url.path == '/v1/addresses',
        ),
        isFalse,
      );
      await tester.tap(
        find.byKey(const Key('customer_booking_category_water-purifier-repair')),
      );
      await tester.pumpAndSettle();
      await next(tester);
      await tester.tap(
        find.byKey(const Key('customer_booking_problem_p1')),
      );
      await tester.pumpAndSettle();
      await next(tester);
      await next(tester);
      expect(find.text('Login to confirm'), findsOneWidget);
      expect(
        find.byKey(const Key('customer_booking_guest_line')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('customer_booking_guest_pin')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('customer_booking_address')), findsNothing);
    });

    testWidgets('review shows the typed address', (tester) async {
      final fake = flowHttp();
      await toSchedule(tester, fake, onGuestConfirm: (_) async {});
      await fillGuestAddress(tester);
      await back(tester);
      expect(find.text('12 Palm St 682001'), findsOneWidget);
    });

    testWidgets('confirm hands the draft to the gate', (tester) async {
      GuestDraft? draft;
      final fake = flowHttp();
      await toSchedule(
        tester,
        fake,
        onGuestConfirm: (d) async => draft = d,
      );
      await fillGuestAddress(tester);
      await tester.tap(find.byKey(const Key('customer_booking_next')));
      await tester.pumpAndSettle();
      expect(draft, isNotNull);
      expect(draft!.categoryId, 'c-wp');
      expect(draft!.issueIds, equals(['p1']));
      expect(draft!.slot, 'morning');
      expect(
        draft!.serviceDate,
        matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')),
      );
      expect(draft!.addressLine, '12 Palm St');
      expect(draft!.pincode, '682001');
      expect(
        fake.requests.any(
          (r) => r.method == 'POST' && r.url.path == '/v1/bookings',
        ),
        isFalse,
      );
    });

    testWidgets('bad pincode blocks the gate', (tester) async {
      var gated = false;
      final fake = flowHttp();
      await toSchedule(
        tester,
        fake,
        onGuestConfirm: (_) async => gated = true,
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('customer_booking_guest_pin')),
          matching: find.byType(TextField),
        ),
        '682',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('customer_booking_next')));
      await tester.pumpAndSettle();
      expect(find.text('Enter an address and 6-digit pincode'), findsOneWidget);
      expect(gated, isFalse);
    });

    testWidgets('missing gate asks for login', (tester) async {
      final fake = flowHttp();
      await toSchedule(tester, fake);
      await fillGuestAddress(tester);
      await tester.tap(find.byKey(const Key('customer_booking_next')));
      await tester.pumpAndSettle();
      expect(find.text('Login required'), findsOneWidget);
    });

    testWidgets('gate failure shows the error and stays', (tester) async {
      final fake = flowHttp();
      await toSchedule(
        tester,
        fake,
        onGuestConfirm: (_) async => throw Exception('area not served'),
      );
      await fillGuestAddress(tester);
      await tester.tap(find.byKey(const Key('customer_booking_next')));
      await tester.pumpAndSettle();
      expect(find.textContaining('area not served'), findsOneWidget);
      expect(find.text('Step 4 of 4 · Pick a visit slot'), findsOneWidget);
    });
  });

  group('submitGuestDraft', () {
    test('creates the address then posts the booking', () async {
      final posts = <String>[];
      final bodies = <Map<String, dynamic>>[];
      final fake = FakeHttp({
        '/v1/addresses': (req) {
          posts.add('addresses');
          bodies.add(
            jsonDecode((req as http.Request).body) as Map<String, dynamic>,
          );
          return FakeHttp.json({'id': 'a9'});
        },
        '/v1/bookings': (req) {
          posts.add('bookings');
          bodies.add(
            jsonDecode((req as http.Request).body) as Map<String, dynamic>,
          );
          return FakeHttp.json({'id': 'b9', 'status': 'open'});
        },
      });
      final out = await submitGuestDraft(
        testApi(fake, token: 'tok-new'),
        const GuestDraft(
          categoryId: 'c-wp',
          issueIds: ['p1'],
          serviceDate: '2026-10-22',
          slot: 'evening',
          addressLine: '12 Palm St',
          pincode: '682001',
        ),
      );
      expect(posts, equals(['addresses', 'bookings']));
      expect(bodies[0]['line1'], '12 Palm St');
      expect(bodies[0]['pincode'], '682001');
      expect(bodies[1]['address_id'], 'a9');
      expect(bodies[1]['category_id'], 'c-wp');
      expect(bodies[1]['slot'], 'evening');
      expect(out['id'], 'b9');
    });
  });
}
