import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:fixvia/main.dart' as app;

import 'helpers/ui_steps.dart';

/// UI-11-01: customer books a water-purifier job end to end in the UI,
/// the SP accepts / starts / completes it, and the customer sees the
/// technician.
/// Statuses are proven by the backend-guarded chain: each 'ok' requires
/// the previous state (accept -> assigned, start -> in_progress).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('UI-11-01 booking to cash', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // 1. customer login.
    await otpLogin(tester, '9000000004', label: 'customer');
    await waitVisible(
        tester, find.byKey(const Key('customer_home')), 'customer home');

    // 2. add an address (pincode pre-filled; typed anyway).
    await tapNav(tester, 'Addresses');
    await waitVisible(
        tester, find.byKey(const Key('customer_addresses')), 'addresses page');
    await tester.enterText(
        find.byKey(const Key('customer_address_line1')), '12 Palm St');
    await tester.enterText(
        find.byKey(const Key('customer_address_pincode')), '682001');
    final save = find.byKey(const Key('customer_address_save'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    await waitVisible(tester, find.text('12 Palm St'), 'saved address row');
    step("address '12 Palm St, 682001' saved");

    // 3. open the booking flow.
    await tapNav(tester, 'Home');
    await tester.pumpAndSettle();
    final book = find.byKey(const Key('customer_home_book'));
    final bookBtn = book.evaluate().isNotEmpty
        ? book
        : find.byKey(const Key('customer_home_book_empty'));
    await tester.ensureVisible(bookBtn);
    await tester.tap(bookBtn);
    await tester.pumpAndSettle();
    await waitVisible(tester, find.text('Step 1 of 4 · Choose a service'),
        'booking flow step 0');
    step('booking flow opened');

    // 4. pick the live purifier category.
    final purifier = find.byKey(
        const Key('customer_booking_category_water-purifier-repair'));
    await tester.ensureVisible(purifier);
    await tester.tap(purifier);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('customer_booking_next')));
    await tester.pumpAndSettle();
    step("category 'Water purifier repair' picked");

    // 5. pick a problem.
    final problem = find.text('Not cooling').first;
    await tester.ensureVisible(problem);
    await tester.tap(problem);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('customer_booking_next')));
    await tester.pumpAndSettle();
    step("problem 'Not cooling' picked");

    // 6. review matches the selections.
    expect(find.text('Water purifier repair'), findsWidgets);
    expect(find.text('Not cooling'), findsWidgets);
    await tester.tap(find.byKey(const Key('customer_booking_next')));
    await tester.pumpAndSettle();
    step('review matches selections');

    // 7. schedule: address + date + slot defaults are fine -> confirm.
    // The pop is async (POST round-trip) and the home route matches
    // finders while buried, so wait for the flow itself to close.
    final confirm = find.byKey(const Key('customer_booking_next'));
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    await dismissConfirmed(tester);
    step('celebration dialog dismissed');
    await waitGone(tester, find.byKey(const Key('customer_booking_next')),
        'booking flow');
    step('booking confirmed with default slot');
    // Same-day journey: start is rejected before the service date.
    await makeCustomerBookingsDue('9000000004');

    // 8. open it from the bookings list; cancel proves the detail loaded.
    await tapNav(tester, 'Bookings');
    await tapBookingRowFor(tester, 'Water purifier repair');
    await waitVisible(tester, find.byKey(const Key('customer_booking_cancel')),
        'cancel button');
    step('booking detail opened while open');
    await popBack(tester);
    await logout(tester);
    step('customer logged out');

    // 9. the SP accepts the job.
    await otpLogin(tester, '9000000003', label: 'sp');
    await tapNav(tester, 'Inbox');
    await tapOfferFor(tester, 'Water purifier repair');
    final baseline = await readOtpCode('9000000004', purpose: 'start_work');
    await tapAction(tester, 'sp_offer_accept');
    await waitVisible(tester, find.text('ok'), 'accept ok');
    step('SP accepted the purifier job');

    // 10. start work with the fresh OTP.
    final code = await pollFreshOtpCode('9000000004',
        purpose: 'start_work', differentFrom: baseline);
    await tester.enterText(find.byKey(const Key('sp_start_otp')), code);
    await tapAction(tester, 'sp_start_work');
    await waitVisible(tester, find.text('ok'), 'start ok');
    step('work started with OTP (proves assigned)');

    // 11. complete with cash.
    await tapAction(tester, 'sp_complete');
    await waitVisible(tester, find.text('ok'), 'complete ok');
    step('job completed, cash collected (proves in_progress)');
    await popBack(tester);
    await logout(tester);

    // 12. the customer sees the technician on the detail.
    await otpLogin(tester, '9000000004', label: 'customer');
    await tapNav(tester, 'Bookings');
    await tapBookingRowFor(tester, 'Water purifier repair');
    await waitVisible(tester, find.text('Ravi Technician'), 'tech name');
    step("customer detail shows 'Ravi Technician'");
    await popBack(tester);
    await logout(tester);
  });
}
