import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixvia/core/theme/components/app_test_id.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  testWidgets('exposes the key and the semantics identifier', (tester) async {
    // Dispose in-body: end-of-test verification runs before tearDowns.
    final handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        themeHarness(
          const AppTestId(testId: 'my-id', child: Text('Hi')),
        ),
      );
      expect(find.byKey(const Key('my-id')), findsOneWidget);
      expect(find.text('Hi'), findsOneWidget);
      final semantics = tester.getSemantics(find.byKey(const Key('my-id')));
      expect(semantics.identifier, 'my-id');
    } finally {
      handle.dispose();
    }
  });
}
