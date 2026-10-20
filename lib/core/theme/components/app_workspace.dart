import 'package:flutter/material.dart';

import '../app_theme.dart';
import 'app_button.dart';
import 'app_test_id.dart';

class AppNavDest {
  const AppNavDest({required this.label, required this.icon, this.testId});

  final String label;
  final IconData icon;
  final String? testId;
}

/// Logged-in chrome: navy icon rail on desktop, floating bottom bar on
/// compact, white header with the account menu.
class AppWorkspaceFrame extends StatelessWidget {
  const AppWorkspaceFrame({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
    required this.body,
    required this.account,
    required this.brand,
    this.mark,
    this.railAccount,
    this.roleLabel,
    super.key,
  });

  final List<AppNavDest> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Widget body;
  final Widget account;
  final Widget brand;

  /// Icon mark topping the desktop rail. Defaults to [brand].
  final Widget? mark;

  /// Account control pinned to the rail bottom. Hidden when null.
  final Widget? railAccount;

  /// Small badge shown next to the brand on compact (e.g. role name).
  final String? roleLabel;

  @override
  Widget build(BuildContext context) {
    final compact = appIsCompact(context);
    return Scaffold(
      backgroundColor: AppColors.canvasOf(context),
      body: compact
          ? Column(
              children: [
                _Header(
                  account: account,
                  brand: brand,
                  roleLabel: roleLabel,
                ),
                Expanded(child: body),
                _BottomNav(
                  destinations: destinations,
                  selectedIndex: selectedIndex,
                  onSelect: onSelect,
                ),
              ],
            )
          : Row(
              children: [
                _Rail(
                  destinations: destinations,
                  selectedIndex: selectedIndex,
                  onSelect: onSelect,
                  mark: mark ?? brand,
                  account: railAccount,
                ),
                Expanded(
                  child: body,
                ),
              ],
            ),
    );
  }
}

class AppSubpageScaffold extends StatelessWidget {
  const AppSubpageScaffold({
    required this.title,
    required this.child,
    this.subtitle,
    this.footer,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasOf(context),
      body: Column(
        children: [
          Material(
            color: AppColors.surfaceOf(context),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  SizedBox(
                    height: 72,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          AppButton.iconOnly(
                            testId: 'app_subpage_back',
                            icon: Icons.arrow_back_rounded,
                            onPressed: () => Navigator.maybePop(context),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                if (subtitle != null)
                                  Text(
                                    subtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1, color: AppColors.lineOf(context)),
                ],
              ),
            ),
          ),
          Expanded(child: child),
          if (footer != null)
            Material(
              color: AppColors.surfaceOf(context),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Divider(height: 1, color: AppColors.lineOf(context)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: footer,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.account, required this.brand, this.roleLabel});

  final Widget account;
  final Widget brand;
  final String? roleLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceOf(context),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Narrow phones can't fit brand + badge + account, so
                    // the badge yields; the role stays in the account menu.
                    final showBadge =
                        roleLabel != null && constraints.maxWidth >= 480;
                    return Row(
                      children: [
                        brand,
                        if (showBadge) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(
                                AppRadii.pill,
                              ),
                            ),
                            child: Text(
                              roleLabel!,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: account,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Divider(height: 1, color: AppColors.lineOf(context)),
          ],
        ),
      ),
    );
  }
}

/// Dark navy icon rail: brand mark on top, icon destinations with
/// tooltips, account control pinned to the bottom.
class _Rail extends StatelessWidget {
  const _Rail({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
    required this.mark,
    this.account,
  });

  final List<AppNavDest> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Widget mark;
  final Widget? account;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      color: AppColors.navy,
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            const SizedBox(height: 18),
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: mark,
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (var i = 0; i < destinations.length; i++) ...[
                    _RailButton(
                      dest: destinations[i],
                      selected: i == selectedIndex,
                      onTap: () => onSelect(i),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            if (account != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: account!,
              ),
          ],
        ),
      ),
    );
  }
}

/// One rail destination: filled blue circle when selected, translucent
/// disc otherwise. Labels live in tooltips — the rail is icon-only.
class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.dest,
    required this.selected,
    required this.onTap,
  });

  final AppNavDest dest;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final button = Tooltip(
      message: dest.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary
                  : AppColors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              boxShadow: selected ? AppShadows.glowSoft : const [],
            ),
            child: Icon(
              dest.icon,
              size: 22,
              color: selected
                  ? AppColors.white
                  : AppColors.white.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
    if (dest.testId == null) return button;
    return AppTestId(testId: dest.testId!, child: button);
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<AppNavDest> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.lineOf(context)),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _NavTile(
                    dest: destinations[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact bottom-bar tile: icon over a small label.
class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.dest,
    required this.selected,
    required this.onTap,
  });

  final AppNavDest dest;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = selected
        ? AppColors.white
        : (dark ? const Color(0xFFB8B0A6) : AppColors.muted);
    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : null,
        borderRadius: BorderRadius.circular(18),
        boxShadow: selected ? AppShadows.glowSoft : const [],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(dest.icon, size: 20, color: fg),
          const SizedBox(height: 3),
          Text(
            dest.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fg,
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    final tappable = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: tile),
    );
    if (dest.testId == null) return tappable;
    return AppTestId(testId: dest.testId!, child: tappable);
  }
}
