import 'package:flutter/material.dart';

import '../app_theme.dart';

/// In-house dialog. Always use [AppDialog.show] from feature code.
class AppDialog {
  AppDialog._();

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? description,
    Widget? child,
    List<Widget> actions = const [],
    bool barrierDismissible = true,
    bool alert = false,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surfaceOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: SizedBox(
          width: 400,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: alert
                        ? AppColors.danger
                        : AppColors.inkOf(context),
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: AppColors.subOf(context),
                    ),
                  ),
                ],
                if (child != null) ...[
                  const SizedBox(height: 12),
                  child,
                ],
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        actions[i],
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
