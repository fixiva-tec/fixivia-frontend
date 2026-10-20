import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixvia/features/customer/booking_confirmed_dialog.dart';

import '../../helpers/test_helpers.dart';

Future<void> pumpDialog(
  WidgetTester tester,
  List<bool?> popped, {
  bool offerView = true,
}) async {
  desktopSize(tester);
  await tester.pumpWidget(
    materialHarness(
      Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            popped.add(
              await showDialog<bool>(
                context: context,
                builder: (_) => BookingConfirmedDialog(
                  serviceName: 'Water purifier repair',
                  subtitle: '2026-10-22 · Morning',
                  offerView: offerView,
                ),
              ),
            );
          },
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('BookingConfirmedDialog', () {
    testWidgets('renders the cheer, service, and both actions',
        (tester) async {
      await pumpDialog(tester, []);
      expect(find.text('Booking confirmed!'), findsOneWidget);
      expect(find.text('Water purifier repair'), findsOneWidget);
      expect(find.text('2026-10-22 · Morning'), findsOneWidget);
      expect(
        find.byKey(const Key('booking_confirmed_view')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('booking_confirmed_done')),
        findsOneWidget,
      );
    });

    testWidgets('View booking pops true', (tester) async {
      final popped = <bool?>[];
      await pumpDialog(tester, popped);
      await tester.tap(find.byKey(const Key('booking_confirmed_view')));
      await tester.pumpAndSettle();
      expect(popped, equals([true]));
    });

    testWidgets('Done pops false', (tester) async {
      final popped = <bool?>[];
      await pumpDialog(tester, popped);
      await tester.tap(find.byKey(const Key('booking_confirmed_done')));
      await tester.pumpAndSettle();
      expect(popped, equals([false]));
    });

    testWidgets('guest mode shows Done only', (tester) async {
      await pumpDialog(tester, [], offerView: false);
      expect(
        find.byKey(const Key('booking_confirmed_view')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('booking_confirmed_done')),
        findsOneWidget,
      );
    });
  });
}
