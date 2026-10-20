import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:fixvia/main.dart' as app;

import 'helpers/ui_steps.dart';

/// UI-11-04: SP1 accepts a seeded computer job, drops it, is not reoffered;
/// SP2 picks it up and finishes cleanly. The start-work OTP is reused.
/// Wrapper seeds: customer 9180000002 + address + computer booking, SP2.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('UI-11-04 drop and reaccept', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // 1. SP1 accepts the computer job.
    await otpLogin(tester, '9000000003', label: 'sp1');
    await waitVisible(
        tester, find.textContaining('Computer repair'), 'seeded offer');
    await tapOfferFor(tester, 'Computer repair');
    await tapAction(tester, 'sp_offer_accept');
    await waitVisible(tester, find.text('ok'), 'accept ok');
    step('SP1 accepted the computer job');

    // 2. SP1 drops it back to open.
    await tapAction(tester, 'sp_drop');
    await waitVisible(tester, find.text('ok'), 'drop ok');
    step('SP1 dropped the job (back to open)');

    // 3. not reoffered to the dropper (round-trip refetches the inbox).
    await popBack(tester);
    await tapNav(tester, 'Schedule');
    await tester.pumpAndSettle();
    await tapNav(tester, 'Inbox');
    await tester.pumpAndSettle();
    await waitGone(
        tester, find.textContaining('Computer repair'), 'dropped offer');
    step('dropped job not reoffered to SP1');
    await logout(tester);

    // 4. SP2 sees the reoffered job and accepts.
    await otpLogin(tester, '9180000101', label: 'sp2');
    await waitVisible(
        tester, find.textContaining('Computer repair'), 'reoffered to SP2');
    step('dropped job reoffered to SP2');
    await tapOfferFor(tester, 'Computer repair');
    await tapAction(tester, 'sp_offer_accept');
    await waitVisible(tester, find.text('ok'), 'reaccept ok');
    step('SP2 accepted the computer job');

    // 5. SP2 starts with the reused OTP and completes.
    final code =
        await pollFreshOtpCode('9180000002', purpose: 'start_work');
    await tester.enterText(find.byKey(const Key('sp_start_otp')), code);
    await tapAction(tester, 'sp_start_work');
    await waitVisible(tester, find.text('ok'), 'start ok');
    step('SP2 started work with the reused OTP');
    await tapAction(tester, 'sp_complete');
    await waitVisible(tester, find.text('ok'), 'complete ok');
    step('SP2 completed the job, cash collected');
    await popBack(tester);
    await logout(tester);
  });
}
