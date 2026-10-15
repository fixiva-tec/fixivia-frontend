import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixvia/core/theme/components/app_workspace.dart';

import '../../../helpers/test_helpers.dart';

List<AppNavDest> dests() => const [
  AppNavDest(label: 'Home', icon: Icons.home, testId: 'nav-home'),
  AppNavDest(label: 'Jobs', icon: Icons.work),
  AppNavDest(label: 'More', icon: Icons.more_horiz, testId: 'nav-more'),
];

Widget frame({
  required ValueChanged<int> onSelect,
  int selectedIndex = 0,
  String? roleLabel,
  Widget? darkBrand,
}) {
  return AppWorkspaceFrame(
    destinations: dests(),
    selectedIndex: selectedIndex,
    onSelect: onSelect,
    body: const Text('Body here'),
    account: const Text('Account here'),
    brand: const Text('Brand here'),
    darkBrand: darkBrand,
    roleLabel: roleLabel,
  );
}

void main() {
  group('AppNavDest', () {
    test('holds label, icon, optional test id', () {
      const d = AppNavDest(label: 'L', icon: Icons.star, testId: 't');
      expect(d.label, 'L');
      expect(d.icon, Icons.star);
      expect(d.testId, 't');
      const bare = AppNavDest(label: 'L', icon: Icons.star);
      expect(bare.testId, isNull);
    });
  });

  group('AppWorkspaceFrame desktop', () {
    testWidgets('sidebar lists destinations, tap selects', (tester) async {
      desktopSize(tester);
      var picked = -1;
      await tester.pumpWidget(shadHarness(frame(onSelect: (i) => picked = i)));
      for (final label in ['Home', 'Jobs', 'More']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('Body here'), findsOneWidget);
      expect(find.text('Account here'), findsOneWidget);
      expect(find.text('Brand here'), findsOneWidget);
      await tester.tap(find.byKey(const Key('nav-more')));
      await tester.pump();
      expect(picked, 2);
    });

    testWidgets('selected tile shows the arrow, others do not', (tester) async {
      desktopSize(tester);
      await tester.pumpWidget(
        shadHarness(frame(onSelect: (_) {}, selectedIndex: 1)),
      );
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    });

    testWidgets('darkBrand wins over brand, role label hidden', (tester) async {
      desktopSize(tester);
      await tester.pumpWidget(
        shadHarness(
          frame(
            onSelect: (_) {},
            roleLabel: 'Owner',
            darkBrand: const Text('Dark brand'),
          ),
        ),
      );
      expect(find.text('Dark brand'), findsOneWidget);
      expect(find.text('Brand here'), findsNothing);
      expect(find.text('Owner'), findsNothing);
    });

    testWidgets('empty destinations and out-of-range index do not crash',
        (tester) async {
      desktopSize(tester);
      await tester.pumpWidget(
        shadHarness(
          AppWorkspaceFrame(
            destinations: const [],
            selectedIndex: 0,
            onSelect: (_) {},
            body: const Text('B'),
            account: const Text('A'),
            brand: const Text('Br'),
          ),
        ),
      );
      expect(find.text('B'), findsOneWidget);

      await tester.pumpWidget(
        shadHarness(frame(onSelect: (_) {}, selectedIndex: 99)),
      );
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    });
  });

  group('AppWorkspaceFrame compact', () {
    testWidgets('header, body, and bottom nav render', (tester) async {
      // Wide-compact: room for the role badge.
      tester.view.physicalSize = const Size(560, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var picked = -1;
      await tester.pumpWidget(
        shadHarness(
          frame(onSelect: (i) => picked = i, roleLabel: 'Owner'),
        ),
      );
      expect(find.text('Brand here'), findsOneWidget);
      expect(find.text('Owner'), findsOneWidget);
      expect(find.text('Body here'), findsOneWidget);
      expect(find.text('Account here'), findsOneWidget);
      for (final label in ['Home', 'Jobs', 'More']) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.tap(find.byKey(const Key('nav-home')));
      await tester.pump();
      expect(picked, 0);
    });

    testWidgets('narrow phones drop the role badge', (tester) async {
      compactSize(tester);
      await tester.pumpWidget(
        shadHarness(
          frame(onSelect: (_) {}, roleLabel: 'Owner'),
        ),
      );
      expect(find.text('Brand here'), findsOneWidget);
      expect(find.text('Account here'), findsOneWidget);
      expect(find.text('Owner'), findsNothing);
    });

    testWidgets('role badge hidden when roleLabel is null', (tester) async {
      compactSize(tester);
      await tester.pumpWidget(shadHarness(frame(onSelect: (_) {})));
      expect(find.text('Brand here'), findsOneWidget);
    });
  });

  group('AppSubpageScaffold', () {
    testWidgets('title, subtitle, child, and footer render', (tester) async {
      await tester.pumpWidget(
        materialHarness(
          const AppSubpageScaffold(
            title: 'Details',
            subtitle: 'Sub here',
            footer: Text('Footer here'),
            child: Text('Child here'),
          ),
        ),
      );
      for (final s in ['Details', 'Sub here', 'Footer here', 'Child here']) {
        expect(find.text(s), findsOneWidget);
      }
    });

    testWidgets('back button pops the route', (tester) async {
      await tester.pumpWidget(
        materialHarness(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AppSubpageScaffold(
                    title: 'Sub',
                    child: Text('Inner'),
                  ),
                ),
              ),
              child: const Text('Go'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(find.text('Sub'), findsOneWidget);
      await tester.tap(find.byKey(const Key('app_subpage_back')));
      await tester.pumpAndSettle();
      expect(find.text('Sub'), findsNothing);
      expect(find.text('Go'), findsOneWidget);
    });
  });
}
