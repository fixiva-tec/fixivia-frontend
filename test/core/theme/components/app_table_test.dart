import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixvia/core/theme/components/app_table.dart';

import '../../../helpers/test_helpers.dart';

Widget table({
  List<AppTableColumn> columns = const [
    AppTableColumn('Name', flex: 2),
    AppTableColumn('Pin'),
  ],
  List<List<Widget>> rows = const [],
  List<String?>? rowTestIds,
  void Function(int index)? onRowTap,
  String emptyTitle = 'Nothing here yet',
  bool dense = false,
}) {
  return AppDataTable(
    columns: columns,
    rows: rows,
    rowTestIds: rowTestIds,
    onRowTap: onRowTap,
    emptyTitle: emptyTitle,
    dense: dense,
  );
}

void main() {
  group('AppDataTable', () {
    testWidgets('headers and rows render with dividers', (tester) async {
      desktopSize(tester);
      await tester.pumpWidget(
        themeHarness(
          table(
            rows: [
              [tcell('FixCo', bold: true), tcell('682001')],
              [tcell('NewCo'), tcell('683101')],
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Pin'), findsOneWidget);
      expect(find.text('FixCo'), findsOneWidget);
      expect(find.text('683101'), findsOneWidget);
      // Header divider plus one between the rows.
      expect(find.byType(Divider), findsNWidgets(2));
    });

    testWidgets('empty state shows the title', (tester) async {
      desktopSize(tester);
      await tester.pumpWidget(
        themeHarness(table(emptyTitle: 'No partners yet')),
      );
      await tester.pumpAndSettle();
      expect(find.text('No partners yet'), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('long empty title wraps instead of overflowing',
        (tester) async {
      compactSize(tester);
      await tester.pumpWidget(
        themeHarness(
          table(emptyTitle: 'Nothing scheduled — enjoy the breather.'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Nothing scheduled — enjoy the breather.'),
        findsOneWidget,
      );
      // Reaching here means no RenderFlex overflow was thrown.
    });

    testWidgets('row taps report the index', (tester) async {
      desktopSize(tester);
      var tapped = -1;
      await tester.pumpWidget(
        themeHarness(
          table(
            rows: [
              [tcell('FixCo'), tcell('682001')],
              [tcell('NewCo'), tcell('683101')],
            ],
            rowTestIds: const ['row_fixco', 'row_newco'],
            onRowTap: (i) => tapped = i,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('row_fixco')), findsOneWidget);
      await tester.tap(find.text('NewCo'));
      await tester.pumpAndSettle();
      expect(tapped, 1);
    });

    testWidgets('dense rows are shorter', (tester) async {
      desktopSize(tester);
      Widget roomy({required bool dense}) => SizedBox(
        width: 600,
        child: table(
          dense: dense,
          rows: [
            [tcell('FixCo'), tcell('682001')],
          ],
        ),
      );
      await tester.pumpWidget(themeHarness(roomy(dense: false)));
      await tester.pumpAndSettle();
      final roomyHeight =
          tester.getSize(find.byType(AppDataTable)).height;
      await tester.pumpWidget(themeHarness(roomy(dense: true)));
      await tester.pumpAndSettle();
      final denseHeight =
          tester.getSize(find.byType(AppDataTable)).height;
      expect(denseHeight, lessThan(roomyHeight));
    });
  });
}
