import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:fixvia/main.dart' as app;

import 'helpers/ui_steps.dart';

/// UI-11-02: the SP works a seeded TV job (accept / start / complete),
/// watches it leave the inbox, then checks schedule and earnings.
/// Wrapper seeds: customer 9180000001 + address + TV booking.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('UI-11-02 SP day', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // 1. SP login; the inbox is the landing tab.
    await otpLogin(tester, '9000000003', label: 'sp');
    await waitVisible(
        tester, find.textContaining('TV mechanic'), 'seeded TV offer');
    step("inbox lists the seeded 'TV mechanic' offer");

    // 2. accept.
    await tapOfferFor(tester, 'TV mechanic');
    final baseline = await readOtpCode('9180000001', purpose: 'start_work');
    await tapAction(tester, 'sp_offer_accept');
    await waitVisible(tester, find.text('ok'), 'accept ok');
    step('SP accepted the TV job');

    // 3. start with the fresh OTP.
    final code = await pollFreshOtpCode('9180000001',
        purpose: 'start_work', differentFrom: baseline);
    await tester.enterText(find.byKey(const Key('sp_start_otp')), code);
    await tapAction(tester, 'sp_start_work');
    await waitVisible(tester, find.text('ok'), 'start ok');
    step('work started with OTP');

    // 4. complete with cash.
    await tapAction(tester, 'sp_complete');
    await waitVisible(tester, find.text('ok'), 'complete ok');
    step('job completed, cash collected');

    // 5. back; a tab round-trip refetches the inbox; the offer is gone.
    await popBack(tester);
    await tapNav(tester, 'Schedule');
    await waitVisible(
        tester, find.byKey(const Key('sp_schedule')), 'schedule page');
    step('schedule page loaded');
    await tapNav(tester, 'Inbox');
    await tester.pumpAndSettle();
    await waitGone(
        tester, find.textContaining('TV mechanic'), 'completed offer');
    step('completed job left the inbox');

    // 6. earnings renders the three aggregates.
    await tapNav(tester, 'Earnings');
    await waitVisible(
        tester, find.byKey(const Key('sp_earnings')), 'earnings page');
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('Jobs'), findsOneWidget);
    step('earnings aggregates rendered');
    await logout(tester);
  });
}
