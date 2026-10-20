import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fixvia/shared/widgets/fx_logo.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('FxLogo', () {
    testWidgets('default and white both render at given height', (tester) async {
      await tester.pumpWidget(themeHarness(const FxLogo()));
      final plain = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(plain.height, 28);

      await tester.pumpWidget(
        themeHarness(const FxLogo(white: true, height: 40)),
      );
      final white = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(white.height, 40);
    });
  });

  group('FxMark', () {
    testWidgets('renders square at given size', (tester) async {
      await tester.pumpWidget(themeHarness(const FxMark(size: 26)));
      final mark = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(mark.width, 26);
      expect(mark.height, 26);

      await tester.pumpWidget(
        themeHarness(const FxMark(onDark: true, size: 32)),
      );
      final dark = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(dark.width, 32);
      expect(dark.height, 32);
    });
  });
}
