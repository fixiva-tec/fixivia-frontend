import 'package:flutter/material.dart';

import '../app_theme.dart';
import 'app_test_id.dart';
import 'app_visual.dart';

/// Header account control: avatar + name pill, tap for the menu.
/// Compact mode renders an avatar-only trigger for the nav rail.
class AppAccountMenu extends StatelessWidget {
  const AppAccountMenu({
    required this.name,
    required this.onLogout,
    this.logoutLabel = 'Log out',
    this.subtitle,
    this.compact = false,
    super.key,
  });

  final String name;
  final String? subtitle;
  final String logoutLabel;
  final VoidCallback onLogout;
  final bool compact;

  Future<void> _open(BuildContext context) async {
    final box = context.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        box.localToGlobal(Offset.zero) & box.size,
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      items: [
        PopupMenuItem<String>(
          enabled: false,
          child: Row(
            children: [
              FxAvatar(name: name, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 8),
        PopupMenuItem<String>(
          value: 'logout',
          child: AppTestId(
            testId: 'shell_logout',
            child: Row(
              children: [
                const Icon(
                  Icons.logout_rounded,
                  size: 16,
                  color: AppColors.danger,
                ),
                const SizedBox(width: 10),
                Text(
                  logoutLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    if (value == 'logout') onLogout();
  }

  @override
  Widget build(BuildContext context) {
    return AppTestId(
      testId: 'shell_account_menu',
      child: AppTestId(
        testId: 'shell_account_name',
        child: compact ? _avatarTrigger(context) : _pillTrigger(context),
      ),
    );
  }

  Widget _pillTrigger(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _open(context),
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FxAvatar(name: name, size: 30),
              const SizedBox(width: 8),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more_rounded,
                size: 15,
                color: AppColors.ink.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarTrigger(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _open(context),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.25),
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: FxAvatar(name: name, size: 36),
        ),
      ),
    );
  }
}
