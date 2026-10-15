import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fixvia/shared/widgets/fx_logo.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('FxLogo', () {
    testWidgets('default and white both render at given height', (tester) async {
      await tester.pumpWidget(shadHarness(const FxLogo()));
      final plain = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(plain.height, 28);

      await tester.pumpWidget(
        shadHarness(const FxLogo(white: true, height: 40)),
      );
      final white = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(white.height, 40);
    });
  });
}
