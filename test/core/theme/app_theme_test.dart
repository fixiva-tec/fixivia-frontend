import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixvia/core/theme/app_theme.dart';

/// Runs [body] while swallowing google_fonts' uncaught async load errors.
///
/// Plain `test()` cases run on real async, so the font futures created by
/// [buildAppTheme]/[appTextTheme] fire (and fail, offline) on
/// a timing lottery that can sink the test running when they land. Widget
/// tests are immune: their font futures never complete under FakeAsync.
/// Only the google_fonts failure is swallowed; any other stray error
/// re-fails loudly, and `expect` failures propagate untouched.
Future<void> withoutFontNoise(FutureOr<void> Function() body) async {
  final strays = <Object>[];
  await runZonedGuarded(
    () async {
      await body();
      // Let the font futures fire while the zone is still active.
      await Future<void>.delayed(const Duration(milliseconds: 300));
    },
    (Object e, StackTrace s) {
      if ('$e'.contains('allowRuntimeFetching') ||
          '$e'.contains('unable to load font')) {
        return;
      }
      strays.add(e);
    },
  );
  if (strays.isNotEmpty) throw strays.first;
}

/// Reads brightness-dependent tokens under a fixed [brightness].
Future<Map<String, Color>> tokens(
  WidgetTester tester,
  Brightness brightness,
) async {
  late Map<String, Color> out;
  await tester.pumpWidget(
    MaterialApp(
      home: Theme(
        // NB: read through an explicit Theme so MaterialApp's themeMode
        // resolution can't substitute a light theme behind our back.
        data: brightness == Brightness.dark
            ? ThemeData.dark()
            : ThemeData.light(),
        child: Builder(
          builder: (context) {
            out = {
              'surface': AppColors.surfaceOf(context),
              'canvas': AppColors.canvasOf(context),
              'ink': AppColors.inkOf(context),
              'sub': AppColors.subOf(context),
              'line': AppColors.lineOf(context),
            };
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  return out;
}

Future<bool> compactAt(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  var compact = false;
  var wide = false;
  var maxW = 0.0;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          compact = appIsCompact(context);
          wide = appIsWide(context);
          maxW = appContentMaxWidth(context);
          return const SizedBox();
        },
      ),
    ),
  );
  expect(wide, width >= 1100);
  expect(maxW, width < 768 ? double.infinity : 720);
  return compact;
}

void main() {
  group('AppColors tokens', () {
    test('brand core values are pinned', () {
      expect(AppColors.primary, const Color(0xFF2563EB));
      expect(AppColors.primaryDeep, const Color(0xFF1E40AF));
      expect(AppColors.primaryBright, const Color(0xFF3B82F6));
      expect(AppColors.ink, const Color(0xFF1E293B));
      expect(AppColors.navy, const Color(0xFF0B1526));
      expect(AppColors.danger, const Color(0xFFDC2626));
      expect(AppColors.success, const Color(0xFF16A34A));
    });

    testWidgets('light tokens resolve to the light palette', (tester) async {
      final light = await tokens(tester, Brightness.light);
      expect(light['surface'], AppColors.white);
      expect(light['canvas'], AppColors.canvas);
      expect(light['ink'], AppColors.ink);
      expect(light['sub'], AppColors.muted);
      expect(light['line'], AppColors.border);
    });

    testWidgets('dark tokens resolve to the dark palette', (tester) async {
      final dark = await tokens(tester, Brightness.dark);
      expect(dark['surface'], AppColors.darkSurface);
      expect(dark['canvas'], AppColors.darkCanvas);
      expect(dark['ink'], AppColors.darkText);
      expect(dark['sub'], AppColors.darkMuted);
      expect(dark['line'], AppColors.darkLine);
    });
  });

  group('AppRadii', () {
    test('corner values are pinned', () {
      expect(AppRadii.sm, 10.0);
      expect(AppRadii.md, 16.0);
      expect(AppRadii.lg, 24.0);
      expect(AppRadii.pill, 999.0);
    });
  });

  group('breakpoints', () {
    testWidgets('compact < 768, wide >= 1100, content width follows',
        (tester) async {
      expect(await compactAt(tester, 390), isTrue);
      expect(await compactAt(tester, 767), isTrue);
      expect(await compactAt(tester, 768), isFalse);
      expect(await compactAt(tester, 1099), isFalse);
      expect(await compactAt(tester, 1100), isFalse);
      expect(await compactAt(tester, 1400), isFalse);
    });
  });

  group('buildAppTheme', () {
    test('light and dark carry brand + brightness', () async {
      await withoutFontNoise(() {
        final light = buildAppTheme(Brightness.light);
        expect(light.brightness, Brightness.light);
        expect(light.colorScheme.primary, AppColors.primary);
        expect(light.colorScheme.secondary, AppColors.primaryDeep);
        expect(light.colorScheme.error, AppColors.danger);
        expect(light.scaffoldBackgroundColor, AppColors.canvas);
        expect(light.dividerColor, AppColors.border);
        expect(light.textTheme.titleLarge!.fontSize, 19);

        final dark = buildAppTheme(Brightness.dark);
        expect(dark.brightness, Brightness.dark);
        expect(dark.colorScheme.surface, AppColors.darkSurface);
        expect(dark.scaffoldBackgroundColor, AppColors.darkCanvas);
        expect(dark.dividerColor, AppColors.darkLine);
      });
    });

    test('date picker states resolve for both brightnesses', () async {
      await withoutFontNoise(() {
        for (final brightness in [Brightness.light, Brightness.dark]) {
          final theme = buildAppTheme(brightness);
          final picker = theme.datePickerTheme;
          expect(picker.headerForegroundColor, AppColors.primary);
          final dayFg = picker.dayForegroundColor!;
          expect(
            dayFg.resolve({WidgetState.selected}),
            AppColors.white,
          );
          expect(
            dayFg.resolve({}),
            brightness == Brightness.dark
                ? AppColors.darkText
                : AppColors.ink,
          );
          final dayBg = picker.dayBackgroundColor!;
          expect(
            dayBg.resolve({WidgetState.selected}),
            AppColors.primary,
          );
          expect(dayBg.resolve({}), Colors.transparent);
          expect(
            picker.todayForegroundColor!.resolve({}),
            AppColors.primary,
          );
        }
      });
    });
  });

  group('appTextTheme', () {
    test('headings use display sizes, body uses ink', () async {
      await withoutFontNoise(() {
        final light = appTextTheme(Brightness.light);
        expect(light.displaySmall!.fontSize, 40);
        expect(light.titleLarge!.fontSize, 19);
        expect(light.bodySmall!.color, AppColors.muted);
        final dark = appTextTheme(Brightness.dark);
        expect(dark.bodySmall!.color, AppColors.darkMuted);
        expect(dark.titleMedium!.color, AppColors.darkText);
      });
    });
  });
}
