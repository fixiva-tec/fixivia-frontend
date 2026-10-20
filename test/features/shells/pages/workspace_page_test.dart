import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixvia/core/theme/app_theme.dart';
import 'package:fixvia/core/theme/components/components.dart';
import 'package:fixvia/features/shells/pages/workspace_page.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('WorkspacePage', () {
    testWidgets('title, subtitle, actions, and keyed list', (tester) async {
      await tester.pumpWidget(
        materialHarness(
          WorkspacePage(
            title: 'Title',
            subtitle: 'Sub here',
            testId: 'page-x',
            actions: const [Text('Act')],
            child: const Text('Body here'),
          ),
        ),
      );
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Sub here'), findsOneWidget);
      expect(find.text('Act'), findsOneWidget);
      expect(find.text('Body here'), findsOneWidget);
      expect(find.byKey(const Key('page-x')), findsOneWidget);
    });

    testWidgets('subtitle and actions optional', (tester) async {
      await tester.pumpWidget(
        materialHarness(
          const WorkspacePage(
            title: 'Title',
            testId: 'page-x',
            child: Text('Body'),
          ),
        ),
      );
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    });
  });

  group('FetchBody', () {
    testWidgets('skeleton while loading, then data', (tester) async {
      var done = false;
      await tester.pumpWidget(
        materialHarness(
          FetchBody(
            future: Future.delayed(const Duration(milliseconds: 50), () {
              done = true;
              return 'v';
            }),
            skeletonRows: 2,
            builder: (data) => Text('got:$data'),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(LoadingSkeleton), findsOneWidget);
      await tester.pumpAndSettle();
      expect(done, isTrue);
      expect(find.text('got:v'), findsOneWidget);
    });

    testWidgets('error shows alert, retry optional', (tester) async {
      var retried = 0;
      // ignore() absorbs the unhandled-error report; the widget still
      // receives the failure through its own subscription.
      Future<dynamic> fail() {
        final future = Future<dynamic>.error(Exception('down'));
        future.ignore();
        return future;
      }
      await tester.pumpWidget(
        materialHarness(
          FetchBody(
            future: fail(),
            onRetry: () => retried++,
            builder: (_) => const Text('never'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Could not load this page'), findsOneWidget);
      expect(find.textContaining('down'), findsOneWidget);
      await tester.tap(find.byKey(const Key('app_fetch_retry')));
      await tester.pump();
      expect(retried, 1);

      await tester.pumpWidget(
        materialHarness(
          FetchBody(future: fail(), builder: (_) => const Text('never')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Could not load this page'), findsOneWidget);
      expect(find.byKey(const Key('app_fetch_retry')), findsNothing);
    });
  });

  group('EmptyHint', () {
    testWidgets('default and custom icons', (tester) async {
      await tester.pumpWidget(
        themeHarness(const EmptyHint('Nothing here')),
      );
      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);

      await tester.pumpWidget(
        themeHarness(
          const EmptyHint('Empty', icon: Icons.star),
        ),
      );
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });

  group('StatusBadge tones', () {
    Future<Color> dotOf(WidgetTester tester, String label) async {
      await tester.pumpWidget(themeHarness(StatusBadge(label)));
      final dots = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(StatusBadge),
          matching: find.byType(Container),
        ),
      );
      final dot = dots.firstWhere((c) {
        final deco = c.decoration;
        return deco is BoxDecoration && deco.shape == BoxShape.circle;
      });
      return (dot.decoration! as BoxDecoration).color!;
    }

    testWidgets('success, danger, info, featured, and fallback', (tester) async {
      expect(await dotOf(tester, 'approved'), AppColors.successDeep);
      expect(await dotOf(tester, 'completed'), AppColors.successDeep);
      expect(await dotOf(tester, 'paid'), AppColors.successDeep);
      expect(await dotOf(tester, 'cancelled'), AppColors.danger);
      expect(await dotOf(tester, 'dropped'), AppColors.danger);
      expect(await dotOf(tester, 'open'), AppColors.primary);
      expect(await dotOf(tester, 'in_progress'), AppColors.primary);
      expect(await dotOf(tester, 'featured #1'), AppColors.warning);
      expect(
        await dotOf(tester, 'something-else'),
        const Color(0xFF525252),
      );
    });

    testWidgets('label is prettified, dark build works', (tester) async {
      await tester.pumpWidget(themeHarness(const StatusBadge('in_progress')));
      expect(find.text('In progress'), findsOneWidget);
      await tester.pumpWidget(
        themeHarness(const StatusBadge('open'), dark: true),
      );
      expect(find.text('Open'), findsOneWidget);
    });
  });

  group('MetricCard', () {
    testWidgets('label, value, icon, and tint branches', (tester) async {
      await tester.pumpWidget(
        themeHarness(
          const Column(
            children: [
              MetricCard(label: 'Jobs', value: '12'),
              MetricCard(
                label: 'GMV',
                value: '₹1',
                icon: Icons.star,
                tint: Colors.red,
              ),
            ],
          ),
        ),
      );
      expect(find.text('Jobs'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });

  group('InfoRow', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(
        themeHarness(const InfoRow('Quote', '₹500')),
      );
      expect(find.text('Quote'), findsOneWidget);
      expect(find.text('₹500'), findsOneWidget);
    });
  });

  group('data helpers', () {
    test('asMap branches', () {
      final direct = {'a': 1};
      expect(identical(asMap(direct), direct), isTrue);
      // Non-string maps reach the copy branch, which rejects their keys.
      expect(() => asMap({1: 'a'}), throwsA(anything));
      expect(asMap([1]), equals({}));
      expect(asMap(null), equals({}));
      expect(asMap('x'), equals({}));
    });

    test('asMapList branches', () {
      expect(
        asMapList([
          {'a': 1},
          'x',
        ]),
        equals([
          {'a': 1},
          {},
        ]),
      );
      expect(asMapList({}), isEmpty);
      expect(asMapList(null), isEmpty);
    });

    test('field falls back on null, blank, and missing', () {
      expect(field({'a': ' x '}, 'a'), 'x');
      expect(field({'a': '  '}, 'a'), '—');
      expect(field({}, 'a'), '—');
      expect(field({}, 'a', 'fb'), 'fb');
      expect(field({'a': null}, 'a', 'fb'), 'fb');
      expect(field({'a': 5}, 'a'), '5');
    });

    test('money formats and zeroes unknowns', () {
      expect(money(500), '₹500');
      expect(money('12'), '₹12');
      expect(money(null), '₹0');
      expect(money(''), '₹0');
    });

    test('pretty capitalizes and spaces', () {
      expect(pretty('in_progress'), 'In progress');
      expect(pretty('open'), 'Open');
      expect(pretty(''), '');
    });

    // The dot keeps the raw tone; the label runs through the private
    // darken/lighten helpers, so compare label colors instead.
    testWidgets('badge label tone differs between light and dark',
        (tester) async {
      Future<Color> labelOf(bool dark) async {
        await tester.pumpWidget(
          themeHarness(const StatusBadge('open'), dark: dark),
        );
        await tester.pumpAndSettle();
        final text = tester.widget<Text>(find.text('Open'));
        return text.style!.color!;
      }

      final light = await labelOf(false);
      final dark = await labelOf(true);
      expect(light, isNot(dark));
      expect(
        dark.computeLuminance(),
        greaterThan(light.computeLuminance()),
      );
    });
  });
}
