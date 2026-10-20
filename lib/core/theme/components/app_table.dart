import 'package:flutter/material.dart';

import '../app_theme.dart';
import 'app_card.dart';
import 'app_test_id.dart';

/// One table column: header label, flex share, alignment.
class AppTableColumn {
  const AppTableColumn(
    this.label, {
    this.flex = 1,
    this.align = TextAlign.left,
    this.headerAlign,
  });

  final String label;
  final int flex;
  final TextAlign align;
  final TextAlign? headerAlign;
}

/// Light admin-style data table: header row, divider-separated rows.
///
/// Cells are caller-built widgets (see [tcell], [tstatus]); rows tap
/// through [onRowTap] and keep their automation ids via [rowTestIds].
class AppDataTable extends StatelessWidget {
  const AppDataTable({
    required this.columns,
    required this.rows,
    this.rowTestIds,
    this.onRowTap,
    this.emptyTitle = 'Nothing here yet',
    this.emptyIcon = Icons.inbox_outlined,
    this.dense = false,
    super.key,
  }) : assert(
          rowTestIds == null || rowTestIds.length == rows.length,
          'rowTestIds must match rows',
        );

  final List<AppTableColumn> columns;
  final List<List<Widget>> rows;
  final List<String?>? rowTestIds;
  final void Function(int index)? onRowTap;
  final String emptyTitle;
  final IconData emptyIcon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final line = AppColors.lineOf(context);
    final headStyle = TextStyle(
      color: AppColors.subOf(context),
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
    );
    final cellPad = EdgeInsets.symmetric(
      horizontal: 12,
      vertical: dense ? 9 : 12,
    );
    Widget row(List<Widget> cells, {bool header = false}) {
      return Padding(
        padding: cellPad,
        child: Row(
          children: [
            for (var i = 0; i < columns.length; i++)
              Expanded(
                flex: columns[i].flex,
                child: header
                    ? Text(
                        columns[i].label,
                        textAlign: columns[i].headerAlign ?? columns[i].align,
                        style: headStyle,
                      )
                    : cells[i],
              ),
          ],
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.canvasOf(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadii.lg),
              ),
            ),
            child: row(const [], header: true),
          ),
          Divider(height: 1, color: line),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(emptyIcon, size: 18, color: AppColors.subOf(context)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      emptyTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.subOf(context),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) Divider(height: 1, color: line),
              _tap(
                context,
                index: i,
                child: row(rows[i]),
              ),
            ],
        ],
      ),
    );
  }

  Widget _tap(BuildContext context, {required int index, required Widget child}) {
    final tap = onRowTap == null
        ? child
        : MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onRowTap!(index),
              child: child,
            ),
          );
    final id = rowTestIds == null ? null : rowTestIds![index];
    if (id == null) return tap;
    return AppTestId(testId: id, child: tap);
  }
}

/// Plain left-aligned table cell with ellipsis.
Widget tcell(
  String text, {
  TextAlign align = TextAlign.left,
  bool bold = false,
  Color? color,
  double size = 13.5,
}) {
  return Text(
    text,
    textAlign: align,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      fontSize: size,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      color: color,
      height: 1.35,
    ),
  );
}

/// Money cell in brand ink.
Widget tmoney(String text, {TextAlign align = TextAlign.left}) {
  return tcell(text, align: align, bold: true, color: AppColors.primary);
}
