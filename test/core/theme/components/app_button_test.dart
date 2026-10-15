import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixvia/core/theme/app_theme.dart';
import 'package:fixvia/core/theme/components/app_button.dart';

import '../../../helpers/test_helpers.dart';

BoxDecoration buttonDeco(WidgetTester tester, String testId) {
  final boxes = tester.widgetList<AnimatedContainer>(
    find.descendant(
      of: find.byKey(Key(testId)),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return boxes.first.decoration! as BoxDecoration;
}

void main() {
  group('AppButton variants', () {
    testWidgets('every variant renders, taps, and styles distinctly',
        (tester) async {
      final become = {
        AppButtonVariant.primary: AppColors.primaryGradient,
      };
      for (final variant in AppButtonVariant.values) {
        var fired = 0;
        await tester.pumpWidget(
          shadHarness(
            AppButton(
              text: 'Go $variant',
              testId: 'btn-$variant',
              variant: variant,
              onPressed: () => fired++,
            ),
          ),
        );
        expect(find.text('Go $variant'), findsOneWidget);
        await tester.tap(find.byKey(Key('btn-$variant')));
        await tester.pump();
        expect(fired, 1);
        final deco = buttonDeco(tester, 'btn-$variant');
        if (become.containsKey(variant)) {
          expect(deco.gradient, become[variant]);
        }
      }
    });

    testWidgets('secondary flips color with brightness', (tester) async {
      await tester.pumpWidget(
        shadHarness(
          AppButton(
            text: 'S',
            testId: 'b-sec',
            variant: AppButtonVariant.secondary,
            onPressed: () {},
          ),
        ),
      );
      expect(buttonDeco(tester, 'b-sec').color, AppColors.charcoal);

      await tester.pumpWidget(
        shadHarness(
          AppButton(
            text: 'S',
            testId: 'b-sec',
            variant: AppButtonVariant.secondary,
            onPressed: () {},
          ),
          dark: true,
        ),
      );
      // Shad animates theme switches; settle onto the dark theme first.
      await tester.pumpAndSettle();
      expect(buttonDeco(tester, 'b-sec').color, AppColors.white);
    });

    testWidgets('onBrand keeps a white pill with orange text', (tester) async {
      await tester.pumpWidget(
        shadHarness(
          AppButton(
            text: 'Brand',
            testId: 'b-brand',
            variant: AppButtonVariant.onBrand,
            onPressed: () {},
          ),
        ),
      );
      expect(buttonDeco(tester, 'b-brand').color, AppColors.white);
      final label = tester.widget<Text>(find.text('Brand'));
      expect(label.style!.color, AppColors.deepOrange);
    });
  });

  group('AppButton sizes', () {
    testWidgets('sm/md/lg pad and scale text', (tester) async {
      const pads = {
        AppButtonSize.sm: EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        AppButtonSize.md: EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        AppButtonSize.lg: EdgeInsets.symmetric(horizontal: 26, vertical: 16),
      };
      for (final entry in pads.entries) {
        await tester.pumpWidget(
          shadHarness(
            AppButton(
              text: 'Sized',
              testId: 'b-size',
              size: entry.key,
              onPressed: () {},
            ),
          ),
        );
        final box = tester
            .widgetList<AnimatedContainer>(
              find.descendant(
                of: find.byKey(const Key('b-size')),
                matching: find.byType(AnimatedContainer),
              ),
            )
            .first;
        expect(box.padding, entry.value);
        final label = tester.widget<Text>(find.text('Sized'));
        expect(
          label.style!.fontSize,
          entry.key == AppButtonSize.sm ? 13.5 : 15,
        );
      }
    });
  });

  group('AppButton states', () {
    testWidgets('tap fires and shows the arrow', (tester) async {
      var fired = 0;
      await tester.pumpWidget(
        shadHarness(
          AppButton(
            text: 'Next',
            testId: 'b-next',
            showArrow: true,
            onPressed: () => fired++,
          ),
        ),
      );
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
      await tester.tap(find.byKey(const Key('b-next')));
      await tester.pump();
      expect(fired, 1);
    });

    testWidgets('busy hides the arrow and swaps leading for a spinner',
        (tester) async {
      var fired = 0;
      await tester.pumpWidget(
        shadHarness(
          AppButton(
            text: 'Busy',
            testId: 'b-busy',
            showArrow: true,
            isLoading: true,
            leading: const Icon(Icons.star),
            onPressed: () => fired++,
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNothing);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
      await tester.tap(find.byKey(const Key('b-busy')));
      await tester.pump();
      expect(fired, 0);
    });

    testWidgets('disabled and handler-less buttons dim and ignore taps',
        (tester) async {
      var fired = 0;
      await tester.pumpWidget(
        shadHarness(
          Column(
            children: [
              AppButton(
                text: 'Dis',
                testId: 'b-dis',
                enabled: false,
                onPressed: () => fired++,
              ),
              AppButton(text: 'Noop', testId: 'b-noop'),
            ],
          ),
        ),
      );
      for (final id in ['b-dis', 'b-noop']) {
        final opacities = tester.widgetList<AnimatedOpacity>(
          find.descendant(
            of: find.byKey(Key(id)),
            matching: find.byType(AnimatedOpacity),
          ),
        );
        expect(opacities.first.opacity, 0.45);
        await tester.tap(find.byKey(Key(id)));
        await tester.pump();
      }
      expect(fired, 0);
      final mouse = tester.widgetList<MouseRegion>(
        find.descendant(
          of: find.byKey(const Key('b-dis')),
          matching: find.byType(MouseRegion),
        ),
      );
      expect(mouse.first.cursor, SystemMouseCursors.basic);
    });

    testWidgets('leading and trailing slots render', (tester) async {
      await tester.pumpWidget(
        shadHarness(
          AppButton(
            text: 'Both',
            testId: 'b-both',
            leading: const Icon(Icons.star, size: 1),
            trailing: const Icon(Icons.flag, size: 1),
            onPressed: () {},
          ),
        ),
      );
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.flag), findsOneWidget);
    });
  });

  group('AppButton fill', () {
    testWidgets('compact fills, desktop hugs, expands overrides', (tester) async {
      Future<double?> widthOf({bool? expands}) async {
        await tester.pumpWidget(
          shadHarness(
            AppButton(
              text: 'W',
              testId: 'b-w',
              expands: expands,
              onPressed: () {},
            ),
          ),
        );
        return tester
            .widgetList<AnimatedContainer>(
              find.descendant(
                of: find.byKey(const Key('b-w')),
                matching: find.byType(AnimatedContainer),
              ),
            )
            .first
            .constraints
            ?.maxWidth;
      }

      compactSize(tester);
      expect(await widthOf(), isNotNull); // fills
      expect(await widthOf(expands: false), isNull);

      desktopSize(tester);
      expect(await widthOf(), isNull); // hugs
      expect(await widthOf(expands: true), isNotNull);
    });
  });

  group('AppButton.iconOnly', () {
    testWidgets('shows the icon with no text and fixed padding', (tester) async {
      var fired = 0;
      await tester.pumpWidget(
        shadHarness(
          AppButton.iconOnly(
            testId: 'b-icon',
            icon: Icons.add,
            onPressed: () => fired++,
          ),
        ),
      );
      expect(find.byIcon(Icons.add), findsOneWidget);
      final texts = tester.widgetList<Text>(
        find.descendant(
          of: find.byKey(const Key('b-icon')),
          matching: find.byType(Text),
        ),
      );
      expect(texts.every((t) => (t.data ?? '').isEmpty), isTrue);
      final box = tester
          .widgetList<AnimatedContainer>(
            find.descendant(
              of: find.byKey(const Key('b-icon')),
              matching: find.byType(AnimatedContainer),
            ),
          )
          .first;
      expect(box.padding, const EdgeInsets.all(11));
      await tester.tap(find.byKey(const Key('b-icon')));
      await tester.pump();
      expect(fired, 1);
    });
  });

  group('AppButton press and hover', () {
    testWidgets('press scales down and back', (tester) async {
      await tester.pumpWidget(
        shadHarness(
          AppButton(text: 'P', testId: 'b-p', onPressed: () {}),
        ),
      );
      Finder scale() => find.descendant(
        of: find.byKey(const Key('b-p')),
        matching: find.byType(AnimatedScale),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('b-p'))),
      );
      await tester.pump();
      expect(tester.widget<AnimatedScale>(scale()).scale, 0.97);
      await gesture.up();
      await tester.pump();
      expect(tester.widget<AnimatedScale>(scale()).scale, 1);
    });

    testWidgets('cancel resets the press', (tester) async {
      await tester.pumpWidget(
        shadHarness(
          AppButton(text: 'P', testId: 'b-p', onPressed: () {}),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('b-p'))),
      );
      await tester.pump();
      await gesture.cancel();
      await tester.pump();
      expect(find.text('P'), findsOneWidget);
    });

    testWidgets('hover lifts and glows, exit settles', (tester) async {
      await tester.pumpWidget(
        shadHarness(
          AppButton(text: 'H', testId: 'b-h', onPressed: () {}),
        ),
      );
      Finder box() => find.descendant(
        of: find.byKey(const Key('b-h')),
        matching: find.byType(AnimatedContainer),
      );
      Matrix4 transform() =>
          tester.widgetList<AnimatedContainer>(box()).first.transform!;
      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byKey(const Key('b-h'))));
      await tester.pump();
      expect(transform(), Matrix4.translationValues(0, -2, 0));
      expect(
        (tester.widgetList<AnimatedContainer>(box()).first.decoration!
                as BoxDecoration)
            .boxShadow,
        AppShadows.glow,
      );
      // Offset.zero is the button's own top-left corner, so exit
      // to the far corner instead.
      await gesture.moveTo(const Offset(799, 599));
      await tester.pump();
      expect(transform(), Matrix4.translationValues(0, 0, 0));
    });

    testWidgets('hover tints outline and ghost', (tester) async {
      await tester.pumpWidget(
        shadHarness(
          Column(
            children: [
              AppButton(
                text: 'O',
                testId: 'b-ho',
                variant: AppButtonVariant.outline,
                onPressed: () {},
              ),
              AppButton(
                text: 'G',
                testId: 'b-hg',
                variant: AppButtonVariant.ghost,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byKey(const Key('b-ho'))));
      await tester.pump();
      expect(
        (buttonDeco(tester, 'b-ho').border! as Border).top.color,
        AppColors.brightOrange,
      );
      await gesture.moveTo(tester.getCenter(find.byKey(const Key('b-hg'))));
      await tester.pump();
      expect(
        buttonDeco(tester, 'b-hg').color,
        AppColors.charcoal.withValues(alpha: 0.06),
      );
    });
  });

  group('AppButton dark mode', () {
    testWidgets('outline and ghost pick dark fills', (tester) async {
      await tester.pumpWidget(
        shadHarness(
          Column(
            children: [
              AppButton(
                text: 'O',
                testId: 'b-do',
                variant: AppButtonVariant.outline,
                onPressed: () {},
              ),
              AppButton(
                text: 'G',
                testId: 'b-dg',
                variant: AppButtonVariant.ghost,
                onPressed: () {},
              ),
            ],
          ),
          dark: true,
        ),
      );
      expect(buttonDeco(tester, 'b-do').color, Colors.transparent);
      expect(buttonDeco(tester, 'b-dg').color, Colors.transparent);
    });
  });
}
