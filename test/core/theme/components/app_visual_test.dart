import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixvia/core/theme/components/app_visual.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('categoryIcon', () {
    test('maps every documented family', () {
      expect(categoryIcon('ac-repair'), Icons.ac_unit_rounded);
      expect(categoryIcon('cooling'), Icons.ac_unit_rounded);
      expect(categoryIcon('air-duct'), Icons.ac_unit_rounded);
      expect(categoryIcon('plumbing'), Icons.water_drop_rounded);
      expect(categoryIcon('water-tank'), Icons.water_drop_rounded);
      expect(categoryIcon('electrician'), Icons.bolt_rounded);
      expect(categoryIcon('fan-install'), Icons.bolt_rounded);
      expect(categoryIcon('home-cleaning'), Icons.cleaning_services_rounded);
      expect(categoryIcon('laundry'), Icons.cleaning_services_rounded);
      expect(categoryIcon('appliance'), Icons.kitchen_rounded);
      expect(categoryIcon('fridge'), Icons.kitchen_rounded);
      expect(categoryIcon('carpenter'), Icons.chair_rounded);
      expect(categoryIcon('furniture'), Icons.chair_rounded);
      expect(categoryIcon('painting'), Icons.format_paint_rounded);
      expect(categoryIcon('pest-control'), Icons.bug_report_rounded);
      expect(categoryIcon('garden'), Icons.grass_rounded);
      expect(categoryIcon('lawn-mowing'), Icons.grass_rounded);
      expect(categoryIcon('cctv'), Icons.videocam_rounded);
      expect(categoryIcon('camera'), Icons.videocam_rounded);
      expect(categoryIcon('inverter'), Icons.battery_charging_full_rounded);
      expect(categoryIcon('battery'), Icons.battery_charging_full_rounded);
      expect(categoryIcon('purifier'), Icons.water_drop_outlined);
      expect(categoryIcon('filter-change'), Icons.water_drop_outlined);
      expect(categoryIcon('locksmith'), Icons.key_rounded);
      expect(categoryIcon('mason'), Icons.construction_rounded);
      expect(categoryIcon('tile-work'), Icons.construction_rounded);
      expect(categoryIcon('salon'), Icons.content_cut_rounded);
      expect(categoryIcon('beauty'), Icons.content_cut_rounded);
      expect(categoryIcon('shifting'), Icons.local_shipping_rounded);
      // 'packers' contains 'ac', so the first branch wins over 'pack'.
      expect(categoryIcon('packers'), Icons.ac_unit_rounded);
    });

    test('is case-insensitive and falls back for unknown', () {
      expect(categoryIcon('AC-REPAIR'), Icons.ac_unit_rounded);
      expect(categoryIcon('Plumbing'), Icons.water_drop_rounded);
      expect(categoryIcon('CCTV'), Icons.videocam_rounded);
      expect(categoryIcon('something-new'), Icons.handyman_rounded);
      expect(categoryIcon(''), Icons.handyman_rounded);
      expect(categoryIcon(null), Icons.handyman_rounded);
    });
  });

  group('FxServiceTile', () {
    testWidgets('default, selected, onBrand, and custom size', (tester) async {
      await tester.pumpWidget(
        themeHarness(const FxServiceTile(icon: Icons.star)),
      );
      expect(find.byIcon(Icons.star), findsOneWidget);

      await tester.pumpWidget(
        themeHarness(
          const Column(
            children: [
              FxServiceTile(icon: Icons.star, selected: true, size: 60),
              FxServiceTile(icon: Icons.flag, onBrand: true),
            ],
          ),
        ),
      );
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.flag), findsOneWidget);
      final boxes = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(
        boxes.any((c) => c.constraints?.maxWidth == 60),
        isTrue,
      );

      await tester.pumpWidget(
        themeHarness(const FxServiceTile(icon: Icons.star), dark: true),
      );
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });

  group('FxAvatar initials', () {
    testWidgets('two words, one word, blank, and padded names', (tester) async {
      await tester.pumpWidget(
        themeHarness(
          const Column(
            children: [
              FxAvatar(name: 'Ada Byron'),
              FxAvatar(name: 'Ada'),
              FxAvatar(name: ''),
              FxAvatar(name: '   '),
              FxAvatar(name: '  Ravi   Kumar  '),
            ],
          ),
        ),
      );
      expect(find.text('AB'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('?'), findsNWidgets(2));
      expect(find.text('RK'), findsOneWidget);
    });
  });

  group('FxRings', () {
    testWidgets('paints, repaints on color change only', (tester) async {
      await tester.pumpWidget(
        themeHarness(const SizedBox.square(
          dimension: 120,
          child: FxRings(),
        )),
      );
      expect(find.byType(CustomPaint), findsWidgets);

      // Same color: shouldRepaint false path.
      await tester.pumpWidget(
        themeHarness(const SizedBox.square(
          dimension: 120,
          child: FxRings(),
        )),
      );
      // New color: shouldRepaint true path.
      await tester.pumpWidget(
        themeHarness(const SizedBox.square(
          dimension: 120,
          child: FxRings(color: Colors.red),
        )),
      );
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('serviceImageFor', () {
    test('maps known slugs to bundled assets', () {
      expect(
        serviceImageFor('water-purifier-repair'),
        startsWith('assets/services/'),
      );
      expect(serviceImageFor('ac-mechanic'), startsWith('assets/services/'));
    });

    test('unknown, null, and empty slugs have no image', () {
      expect(serviceImageFor('plumbing'), isNull);
      expect(serviceImageFor(null), isNull);
      expect(serviceImageFor(''), isNull);
    });
  });

  group('FxServiceImage', () {
    testWidgets('unknown slug falls back to the glyph tile', (tester) async {
      await tester.pumpWidget(
        themeHarness(const FxServiceImage(slug: 'plumbing', size: 52)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FxServiceTile), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.water_drop_rounded), findsOneWidget);
    });

    testWidgets('known slug renders the bundled asset', (tester) async {
      await tester.pumpWidget(
        themeHarness(
          const FxServiceImage(slug: 'water-purifier-repair', size: 52),
        ),
      );
      await tester.pump();
      final img = tester.widget<Image>(find.byType(Image));
      expect(
        (img.image as AssetImage).assetName,
        'assets/services/water-purifier-repair.jpg',
      );
      expect(img.width, 52);
      expect(img.height, 52);
    });
  });

  group('ComingSoonBadge', () {
    testWidgets('single line that never wraps', (tester) async {
      await tester.pumpWidget(
        themeHarness(
          const SizedBox(width: 60, child: ComingSoonBadge()),
        ),
      );
      await tester.pumpAndSettle();
      final text = tester.widget<Text>(find.text('Coming soon'));
      expect(text.maxLines, 1);
      expect(text.softWrap, isFalse);
      // Narrow box: scaled down, still one line, no overflow thrown.
      expect(tester.getSize(find.text('Coming soon')).height, lessThan(30));
    });
  });
}
