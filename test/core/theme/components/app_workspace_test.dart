import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixvia/core/theme/app_theme.dart';
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
  Widget? mark,
  Widget? railAccount,
}) {
  return AppWorkspaceFrame(
    destinations: dests(),
    selectedIndex: selectedIndex,
    onSelect: onSelect,
    body: const Text('Body here'),
    account: const Text('Account here'),
    brand: const Text('Brand here'),
    mark: mark,
    railAccount: railAccount,
    roleLabel: roleLabel,
  );
}

/// Rail buttons whose circle carries the selected blue fill.
int blueButtons(WidgetTester tester) {
  return tester
      .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
      .where(
        (a) => (a.decoration as BoxDecoration?)?.color == AppColors.primary,
      )
      .length;
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
    testWidgets('rail shows icons, tap selects', (tester) async {
      desktopSize(tester);
      var picked = -1;
      await tester.pumpWidget(
        themeHarness(
          frame(
            onSelect: (i) => picked = i,
            railAccount: const Text('Account here'),
          ),
        ),
      );
      // Icon-only rail: icons present, labels live in tooltips.
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.work), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz), findsOneWidget);
      for (final label in ['Home', 'Jobs', 'More']) {
        expect(find.text(label), findsNothing);
      }
      expect(find.text('Body here'), findsOneWidget);
      expect(find.text('Account here'), findsOneWidget);
      expect(find.text('Brand here'), findsOneWidget);
      await tester.tap(find.byKey(const Key('nav-more')));
      await tester.pump();
      expect(picked, 2);
    });

    testWidgets('selected button is blue, others are not', (tester) async {
      desktopSize(tester);
      await tester.pumpWidget(
        themeHarness(frame(onSelect: (_) {}, selectedIndex: 1)),
      );
      expect(blueButtons(tester), 1);
    });

    testWidgets('mark wins over brand, rail account hides when null',
        (tester) async {
      desktopSize(tester);
      await tester.pumpWidget(
        themeHarness(
          frame(onSelect: (_) {}, mark: const Text('Mark here')),
        ),
      );
      expect(find.text('Mark here'), findsOneWidget);
      expect(find.text('Brand here'), findsNothing);
      expect(find.text('Account here'), findsNothing);
    });

    testWidgets('empty destinations and out-of-range index do not crash',
        (tester) async {
      desktopSize(tester);
      await tester.pumpWidget(
        themeHarness(
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
      expect(blueButtons(tester), 0);

      await tester.pumpWidget(
        themeHarness(frame(onSelect: (_) {}, selectedIndex: 99)),
      );
      expect(blueButtons(tester), 0);
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
        themeHarness(
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
        themeHarness(
          frame(onSelect: (_) {}, roleLabel: 'Owner'),
        ),
      );
      expect(find.text('Brand here'), findsOneWidget);
      expect(find.text('Account here'), findsOneWidget);
      expect(find.text('Owner'), findsNothing);
    });

    testWidgets('role badge hidden when roleLabel is null', (tester) async {
      compactSize(tester);
      await tester.pumpWidget(themeHarness(frame(onSelect: (_) {})));
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
