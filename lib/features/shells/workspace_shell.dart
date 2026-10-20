import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../core/booking_rules.dart';
import '../../core/catalog.dart';
import '../../core/session.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/components/components.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/fx_logo.dart';
import '../customer/booking_flow.dart';
import 'pages/resource_pages.dart';
import 'pages/workspace_page.dart';

class WorkspaceShell extends StatefulWidget {
  const WorkspaceShell({
    required this.api,
    required this.user,
    this.onLogout,
    super.key,
  });

  final ApiClient api;
  final SessionUser user;
  final VoidCallback? onLogout;

  @override
  State<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends State<WorkspaceShell> {
  var _index = 0;

  List<_Tab> get _tabs {
    switch (widget.user.role) {
      case UserRole.customer:
        return [
          _Tab(
            'Home',
            Icons.home_rounded,
            () => _CustomerHome(
              api: widget.api,
              user: widget.user,
              onOpenBookings: () => setState(() => _index = 1),
            ),
            testId: 'nav_home',
          ),
          _Tab(
            'Bookings',
            Icons.event_rounded,
            () => BookingsListPage(
              api: widget.api,
              path: '/v1/bookings',
              testId: 'customer_bookings',
              title: 'Your bookings',
              onOpen: (id) => _openBooking(id),
            ),
            testId: 'nav_bookings',
          ),
          _Tab(
            'Addresses',
            Icons.place_rounded,
            () => _AddressesPage(api: widget.api),
            testId: 'nav_addresses',
          ),
        ];
      case UserRole.servicePartner:
        return [
          _Tab(
            'Inbox',
            Icons.inbox_rounded,
            () => _OffersPage(api: widget.api),
            testId: 'nav_inbox',
          ),
          _Tab(
            'Schedule',
            Icons.calendar_month_rounded,
            () => SchedulePage(api: widget.api),
            testId: 'nav_schedule',
          ),
          _Tab(
            'Earnings',
            Icons.payments_rounded,
            () => EarningsPage(api: widget.api),
            testId: 'nav_earnings',
          ),
          _Tab(
            'Profile',
            Icons.person_rounded,
            () => _SpProfilePage(api: widget.api),
            testId: 'nav_profile',
          ),
          _Tab(
            'Reports',
            Icons.insights_rounded,
            () => AnalyticsPage(api: widget.api, testId: 'sp_reports'),
            testId: 'nav_reports',
          ),
        ];
      case UserRole.partnerOwner:
      case UserRole.partnerAdmin:
        return [
          _Tab(
            'Open',
            Icons.pending_actions_rounded,
            () => BookingsListPage(
              api: widget.api,
              path: '/v1/bookings?status=open',
              testId: 'partner_open',
              title: 'Open requests',
              onOpen: _openBooking,
            ),
            testId: 'nav_open',
          ),
          _Tab(
            'Upcoming',
            Icons.upcoming_rounded,
            () => BookingsListPage(
              api: widget.api,
              testId: 'partner_upcoming',
              title: 'Bookings',
              onOpen: _openBooking,
            ),
            testId: 'nav_upcoming',
          ),
          _Tab(
            'Roster',
            Icons.groups_rounded,
            () => _RosterPage(api: widget.api),
            testId: 'nav_roster',
          ),
          _Tab(
            'Pricing',
            Icons.sell_rounded,
            () => PricingPage(api: widget.api),
            testId: 'nav_pricing',
          ),
          _Tab(
            'Analytics',
            Icons.insights_rounded,
            () => AnalyticsPage(api: widget.api, testId: 'partner_analytics'),
            testId: 'nav_analytics',
          ),
        ];
      case UserRole.masterAdmin:
        return [
          _Tab(
            'Partners',
            Icons.apartment_rounded,
            () => PartnersPage(api: widget.api),
            testId: 'nav_partners',
          ),
          _Tab(
            'Categories',
            Icons.category_rounded,
            () => CategoriesPage(api: widget.api),
            testId: 'nav_categories',
          ),
          _Tab(
            'Admins',
            Icons.person_add_rounded,
            () => AdminRequestsPage(api: widget.api),
            testId: 'nav_admins',
          ),
          _Tab(
            'Invoices',
            Icons.receipt_long_rounded,
            () => InvoicesPage(api: widget.api),
            testId: 'nav_invoices',
          ),
          _Tab(
            'Analytics',
            Icons.insights_rounded,
            () => AnalyticsPage(api: widget.api, testId: 'master_analytics'),
            testId: 'nav_analytics',
          ),
        ];
    }
  }

  void _openBooking(String id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _BookingDetail(api: widget.api, id: id, role: widget.user.role),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    final body = tabs[_index].builder();
    return AppWorkspaceFrame(
      brand: const FxLogo(height: 28),
      mark: const FxMark(size: 26),
      roleLabel: _roleLabel(widget.user.role),
      account: AppAccountMenu(
        name: widget.user.fullName,
        subtitle: _roleLabel(widget.user.role),
        logoutLabel: AppLocalizations.of(context).logout,
        onLogout: widget.onLogout ?? () {},
      ),
      railAccount: AppAccountMenu(
        name: widget.user.fullName,
        subtitle: _roleLabel(widget.user.role),
        logoutLabel: AppLocalizations.of(context).logout,
        onLogout: widget.onLogout ?? () {},
        compact: true,
      ),
      destinations: [
        for (final t in tabs)
          AppNavDest(label: t.label, icon: t.icon, testId: t.testId),
      ],
      selectedIndex: _index,
      onSelect: (i) => setState(() => _index = i),
      body: body,
    );
  }
}

String _roleLabel(UserRole role) {
  return switch (role) {
    UserRole.masterAdmin => 'Master admin',
    UserRole.partnerOwner => 'Partner owner',
    UserRole.partnerAdmin => 'Partner admin',
    UserRole.servicePartner => 'Service partner',
    UserRole.customer => 'Customer',
  };
}

class _Tab {
  const _Tab(this.label, this.icon, this.builder, {this.testId});
  final String label;
  final IconData icon;
  final Widget Function() builder;
  final String? testId;
}

class _CustomerHome extends StatelessWidget {
  const _CustomerHome({
    required this.api,
    required this.user,
    required this.onOpenBookings,
  });

  final ApiClient api;
  final SessionUser user;
  final VoidCallback onOpenBookings;

  void _openFlow(BuildContext context, {String? initialCategoryId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingFlow(
          api: api,
          initialCategoryId: initialCategoryId,
          onConfirmed: (id) => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  _BookingDetail(api: api, id: id, role: user.role),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    return WorkspacePage(
      title: '$greeting, ${user.fullName.split(' ').first}',
      subtitle: l10n.authWelcome,
      testId: 'customer_home',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            tint: AppColors.primary,
            padding: const EdgeInsets.all(26),
            child: Stack(
              children: [
                const Positioned.fill(child: FxRings(opacity: 0.2)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'READY WHEN YOU ARE',
                      style: TextStyle(
                        color: Color(0xE6FFFFFF),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.bookAService,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.tagline,
                      style: const TextStyle(
                        color: Color(0xE6FFFFFF),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      text: l10n.bookAService,
                      testId: 'customer_home_book',
                      variant: AppButtonVariant.onBrand,
                      expands: false,
                      size: AppButtonSize.lg,
                      showArrow: true,
                      onPressed: () => _openFlow(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          SectionHeader(
            title: 'Popular services',
            actionLabel: 'Book',
            actionTestId: 'customer_home_book_all',
            onAction: () => _openFlow(context),
          ),
          const SizedBox(height: 12),
          FetchBody(
            future: api.get('/v1/categories'),
            skeletonRows: 2,
            builder: (data) {
              final items = asMapList(data);
              final featured = items
                  .where((c) => c['featured_rank'] != null)
                  .toList();
              final show = (featured.isEmpty ? items : featured).take(6);
              if (show.isEmpty) {
                return const EmptyHint('No services yet.');
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final cols = constraints.maxWidth > 640 ? 3 : 2;
                  // Narrow cells stack the name over the badge: go taller.
                  final cellW =
                      (constraints.maxWidth - (cols - 1) * 10) / cols;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: cols,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: cellW < 200 ? 1.05 : 1.5,
                    children: [
                      for (final c in show)
                        _HomeServiceCard(
                          name: field(c, 'name_en'),
                          slug: field(c, 'slug', ''),
                          live: isBookableCategory(field(c, 'slug', '')),
                          testId:
                              'customer_home_service_${field(c, 'slug', field(c, 'id'))}',
                          onTap: () => _openFlow(
                            context,
                            initialCategoryId: field(c, 'id'),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 26),
          SectionHeader(
            title: 'Upcoming visits',
            actionLabel: 'View all',
            actionTestId: 'customer_home_view_bookings',
            onAction: onOpenBookings,
          ),
          const SizedBox(height: 12),
          FetchBody(
            future: api.get('/v1/bookings'),
            skeletonRows: 2,
            builder: (data) {
              final items = asMapList(data).take(3).toList();
              if (items.isEmpty) {
                return AppCard(
                  child: EmptyState(
                    title: 'No bookings yet',
                    hint: 'Your upcoming and past visits will show up here.',
                    icon: Icons.event_available_rounded,
                    action: AppButton(
                      text: l10n.bookAService,
                      testId: 'customer_home_book_empty',
                      expands: false,
                      showArrow: true,
                      onPressed: () => _openFlow(context),
                    ),
                  ),
                );
              }
              return AppDataTable(
                columns: const [
                  AppTableColumn('Service', flex: 2),
                  AppTableColumn('Date'),
                  AppTableColumn('Amount'),
                  AppTableColumn('Status'),
                ],
                rows: [
                  for (final b in items)
                    [
                      tcell(field(b, 'category_name', 'Booking'), bold: true),
                      tcell(field(b, 'service_date')),
                      tmoney(money(b['quoted_amount'])),
                      StatusBadge(field(b, 'status')),
                    ],
                ],
                rowTestIds: [
                  for (final b in items) 'customer_home_booking_${b['id']}',
                ],
                onRowTap: (i) => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _BookingDetail(
                      api: api,
                      id: '${items[i]['id']}',
                      role: user.role,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HomeServiceCard extends StatelessWidget {
  const _HomeServiceCard({
    required this.name,
    required this.slug,
    required this.testId,
    required this.onTap,
    this.live = true,
  });

  final String name;
  final String slug;
  final String testId;
  final VoidCallback onTap;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: live ? 1 : 0.6,
      child: AppCard(
        testId: testId,
        onTap: live ? onTap : null,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            FxServiceImage(slug: slug, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  if (!live) ...[
                    const SizedBox(height: 6),
                    const ComingSoonBadge(),
                  ],
                ],
              ),
            ),
            if (live)
              const Icon(
                Icons.arrow_forward_rounded,
                size: 17,
                color: AppColors.primaryBright,
              ),
          ],
        ),
      ),
    );
  }
}

class _BookingDetail extends StatefulWidget {
  const _BookingDetail({required this.api, required this.id, required this.role});
  final ApiClient api;
  final String id;
  final UserRole role;

  @override
  State<_BookingDetail> createState() => _BookingDetailState();
}

class _BookingDetailState extends State<_BookingDetail> {
  final _otp = TextEditingController();
  String? _msg;
  var _reload = 0;

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSubpageScaffold(
      title: 'Booking',
      subtitle: 'Track progress and take action',
      child: FutureBuilder(
        future: widget.api.get('/v1/bookings/${widget.id}$_queryBuster'),
        builder: (context, snap) {
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: AppAlert(title: '${snap.error}', destructive: true),
            );
          }
          if (!snap.hasData) {
            return const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: LoadingSkeleton(rows: 4),
            );
          }
          final b = snap.data as Map<String, dynamic>;
          final status = '${b['status'] ?? 'open'}';
          // Role-appropriate actions only; the server re-checks every call.
          final isSp = widget.role == UserRole.servicePartner;
          final isCustomer = widget.role == UserRole.customer;
          final isPartner = widget.role == UserRole.partnerOwner ||
              widget.role == UserRole.partnerAdmin;
          // Work can only start once the service date arrives (server
          // enforces this in Asia/Kolkata; this is the local-day hint).
          final serviceDay =
              DateTime.tryParse('${b['service_date'] ?? ''}');
          final now = DateTime.now();
          final startEarly = serviceDay != null &&
              DateTime(serviceDay.year, serviceDay.month, serviceDay.day)
                  .isAfter(DateTime(now.year, now.month, now.day));
          final banner = serviceImageFor('${b['category_slug'] ?? ''}');
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.lg),
                child: SizedBox(
                  height: 168,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (banner != null)
                        Image.asset(banner, fit: BoxFit.cover)
                      else
                        Container(
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                          ),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.05),
                              Colors.black.withValues(alpha: 0.62),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${b['category_name'] ?? 'Booking'}',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${b['service_date']} · ${pretty('${b['slot'] ?? ''}')} · ${b['pincode']}',
                              style: const TextStyle(
                                color: Color(0xE6FFFFFF),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Progress',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontSize: 17),
                          ),
                        ),
                        StatusBadge(status),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _ProgressSteps(status: status),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                title: 'Visit details',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TechnicianRow(booking: b),
                    const Divider(height: 22),
                    InfoRow('Quote', money(b['quoted_amount'])),
                    InfoRow('Payment', pretty('${b['payment_mode'] ?? '—'}')),
                    InfoRow(
                      'OTP hint',
                      '${b['start_work_otp_hint'] ?? '—'}',
                    ),
                    if (isSp) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Start-work OTP',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      if (startEarly) ...[
                        AppAlert(
                          title:
                              'Work can start on ${b['service_date']}',
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppInputField(
                              testId: 'sp_start_otp',
                              controller: _otp,
                              placeholder: '6-digit code',
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: AppButton(
                              text: 'Start work',
                              testId: 'sp_start_work',
                              variant: AppButtonVariant.secondary,
                              expands: false,
                              onPressed: startEarly
                                  ? null
                                  : () => _act(
                                        '/v1/bookings/${widget.id}/start',
                                        {'code': _otp.text},
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_msg != null) ...[
                      const SizedBox(height: 12),
                      AppAlert(
                        title: _msg!,
                        destructive: _msg != 'ok',
                        success: _msg == 'ok',
                      ),
                    ],
                    if (isSp || isPartner) ...[
                      const SizedBox(height: 18),
                      Text(
                        'Offer actions',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (isSp)
                            AppButton(
                              text: 'Accept',
                              testId: 'sp_offer_accept',
                              expands: false,
                              leading:
                                  const Icon(Icons.check_rounded, size: 16),
                              onPressed: () => _act(
                                  '/v1/bookings/${widget.id}/accept'),
                            ),
                          if (isSp)
                            AppButton(
                              text: 'Decline',
                              testId: 'sp_offer_decline',
                              variant: AppButtonVariant.outline,
                              expands: false,
                              onPressed: () => _act(
                                  '/v1/bookings/${widget.id}/decline'),
                            ),
                          AppButton(
                            text: 'Complete',
                          testId: 'sp_complete',
                          variant: AppButtonVariant.secondary,
                          expands: false,
                          leading: const Icon(
                            Icons.task_alt_rounded,
                            size: 16,
                          ),
                          onPressed: () => _act(
                            '/v1/bookings/${widget.id}/complete',
                            {'payment_mode': 'cash'},
                          ),
                        ),
                        ],
                      ),
                    ],
                    if (forceAssignReady(b, DateTime.now())) ...[
                      const SizedBox(height: 18),
                      _ForceAssignCard(
                        api: widget.api,
                        bookingId: widget.id,
                        onAssigned: () => setState(() => _reload += 1),
                      ),
                    ],
                    if (isSp || isPartner || isCustomer) ...[
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (isSp || isPartner)
                            AppButton(
                              text: 'Drop job',
                              testId: 'sp_drop',
                              variant: AppButtonVariant.ghost,
                              expands: false,
                              onPressed: () => _act(
                                  '/v1/bookings/${widget.id}/drop'),
                            ),
                          if (isCustomer)
                            AppButton(
                              text: 'Cancel booking',
                              testId: 'customer_booking_cancel',
                              variant: AppButtonVariant.destructive,
                              expands: false,
                              size: AppButtonSize.sm,
                              onPressed: () => _act(
                                  '/v1/bookings/${widget.id}/cancel'),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Cache-buster so the detail reloads after each action.
  String get _queryBuster => _reload == 0 ? '' : '?r=$_reload';

  Future<void> _act(String path, [Map<String, dynamic>? body]) async {
    try {
      await widget.api.post(path, body);
      if (mounted) {
        setState(() {
          _msg = 'ok';
          _reload += 1;
        });
      }
    } catch (e) {
      setState(() => _msg = e.toString());
    }
  }
}

/// Partner fallback: assign a technician after a failed 3h cycle.
///
/// Server is authoritative (partner roles only, same constraints as the
/// dispatch pool, start-work OTP reused). Non-partners get 403 and the
/// section hides itself.
class _ForceAssignCard extends StatefulWidget {
  const _ForceAssignCard({
    required this.api,
    required this.bookingId,
    required this.onAssigned,
  });

  final ApiClient api;
  final String bookingId;
  final VoidCallback onAssigned;

  @override
  State<_ForceAssignCard> createState() => _ForceAssignCardState();
}

class _ForceAssignCardState extends State<_ForceAssignCard> {
  String? _selected;
  var _busy = false;
  String? _msg;
  var _reload = 0;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      testId: 'partner_assign_section',
      title: 'Assign technician',
      child: FutureBuilder(
        future: widget.api.get(
          '/v1/bookings/${widget.bookingId}/assignable${_reload == 0 ? '' : '?r=$_reload'}',
        ),
        builder: (context, snap) {
          if (snap.hasError) {
            // Only partner roles may assign; hide for everyone else.
            if ('${snap.error}'.contains('forbidden')) {
              return const SizedBox.shrink();
            }
            return AppAlert(title: '${snap.error}', destructive: true);
          }
          if (!snap.hasData) {
            return const LoadingSkeleton(rows: 2);
          }
          final data = snap.data as Map<String, dynamic>;
          final techs = (data['technicians'] as List?) ?? [];
          if (data['ready'] != true || techs.isEmpty) {
            return const AppAlert(
              title: 'No eligible technicians right now.',
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final t in techs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppChoice(
                    label:
                        '${t['name']} · ${t['jobs_in_slot']}/${t['slot_cap']} this slot',
                    icon: Icons.handyman_rounded,
                    selected: _selected == t['id'],
                    testId: 'partner_assign_pick_${t['id']}',
                    onTap: () => setState(() => _selected = t['id'] as String),
                  ),
                ),
              if (_msg != null) ...[
                const SizedBox(height: 8),
                AppAlert(
                  title: _msg!,
                  destructive: _msg != 'ok',
                  success: _msg == 'ok',
                ),
              ],
              const SizedBox(height: 12),
              AppButton(
                text: 'Assign selected',
                testId: 'partner_assign_confirm',
                expands: false,
                isLoading: _busy,
                onPressed: _selected == null || _busy ? null : _assign,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _assign() async {
    setState(() {
      _busy = true;
      _msg = null;
    });
    try {
      await widget.api.post('/v1/bookings/${widget.bookingId}/force-assign', {
        'service_partner_id': _selected,
      });
      if (mounted) {
        setState(() {
          _msg = 'ok';
          _busy = false;
          _reload += 1;
        });
        widget.onAssigned();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _msg = e.toString();
          _busy = false;
        });
      }
    }
  }
}

class _TechnicianRow extends StatelessWidget {
  const _TechnicianRow({required this.booking});

  final Map<String, dynamic> booking;

  @override
  Widget build(BuildContext context) {
    final name = '${booking['technician_name'] ?? ''}'.trim();
    final mobile = '${booking['technician_mobile_masked'] ?? ''}'.trim();
    final waiting = name.isEmpty || name == 'null';
    return Row(
      children: [
        waiting
            ? const FxServiceTile(
                icon: Icons.hourglass_top_rounded,
                size: 44,
              )
            : FxAvatar(name: name, size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                waiting ? 'Waiting for a technician' : name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                waiting ? 'First accept wins the job' : mobile,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        StatusBadge(waiting ? 'open' : 'assigned'),
      ],
    );
  }
}

class _ProgressSteps extends StatelessWidget {
  const _ProgressSteps({required this.status});

  final String status;

  static const _flow = ['open', 'accepted', 'in_progress', 'completed'];
  static const _labels = ['Open', 'Accepted', 'In progress', 'Done'];

  @override
  Widget build(BuildContext context) {
    final key = status.toLowerCase();
    if (key.contains('cancel') ||
        key.contains('drop') ||
        key.contains('decline')) {
      return AppAlert(title: 'Booking ${pretty(status)}', destructive: true);
    }
    var stage = 0;
    for (var i = 0; i < _flow.length; i++) {
      if (key.contains(_flow[i])) stage = i;
    }
    return Row(
      children: [
        for (var i = 0; i < _flow.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: i <= stage ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: i <= stage ? AppColors.primary : AppColors.canvas,
                  shape: BoxShape.circle,
                  border: i <= stage
                      ? null
                      : Border.all(color: AppColors.border),
                ),
                child: Icon(
                  i < stage
                      ? Icons.check_rounded
                      : i == stage
                      ? Icons.circle
                      : Icons.circle_outlined,
                  size: 14,
                  color: i <= stage ? AppColors.white : AppColors.muted,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _labels[i],
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: i == stage ? FontWeight.w700 : FontWeight.w500,
                  color: i == stage
                      ? AppColors.primary
                      : AppColors.muted,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _OffersPage extends StatelessWidget {
  const _OffersPage({required this.api});
  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return WorkspacePage(
      title: 'Open offers',
      subtitle: 'First accept wins the job.',
      testId: 'sp_inbox',
      child: FetchBody(
        future: api.get('/v1/offers'),
        builder: (data) {
          final items = asMapList(data);
          return AppDataTable(
            columns: const [
              AppTableColumn('Service', flex: 2),
              AppTableColumn('Pincode'),
              AppTableColumn('Date'),
              AppTableColumn('Load'),
              AppTableColumn('Open', flex: 1),
            ],
            rows: [
              for (final o in items)
                [
                  Row(
                    children: [
                      FxServiceImage(
                        slug: '${o['category_slug'] ?? ''}',
                        size: 36,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: tcell(
                          '${o['category_name']}',
                          bold: true,
                        ),
                      ),
                    ],
                  ),
                  tcell('${o['pincode']}'),
                  tcell('${o['service_date']}'),
                  _LoadDots(
                    load: (o['slot_load'] as num?)?.toInt() ?? 0,
                    cap: (o['slot_cap'] as num?)?.toInt() ?? 5,
                  ),
                  AppButton(
                    text: 'Open',
                    testId: 'sp_offer_open_${o['id']}',
                    size: AppButtonSize.sm,
                    expands: false,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _BookingDetail(
                          api: api,
                          id: o['id'] as String,
                          // Inbox is a service-partner-only tab.
                          role: UserRole.servicePartner,
                        ),
                      ),
                    ),
                  ),
                ],
            ],
            emptyTitle: 'No open offers',
            emptyIcon: Icons.inbox_outlined,
          );
        },
      ),
    );
  }
}

/// Compact slot-load meter for the offers table.
class _LoadDots extends StatelessWidget {
  const _LoadDots({required this.load, required this.cap});

  final int load;
  final int cap;

  @override
  Widget build(BuildContext context) {
    final ratio = cap <= 0 ? 0.0 : (load / cap).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$load/$cap',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: AppColors.washSoft,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _AddressesPage extends StatefulWidget {
  const _AddressesPage({required this.api});
  final ApiClient api;
  @override
  State<_AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<_AddressesPage> {
  final _line = TextEditingController();
  final _pin = TextEditingController(text: '682001');
  var _saving = false;

  @override
  void dispose() {
    _line.dispose();
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WorkspacePage(
      title: 'Addresses',
      subtitle: 'Saved places for home visits.',
      testId: 'customer_addresses',
      child: Column(
        children: [
          AppCard(
            title: 'Add address',
            description: 'Where should our technician come?',
            leading: const FxServiceTile(icon: Icons.add_home_rounded),
            child: Column(
              children: [
                AppInputField(
                  label: 'Line 1',
                  testId: 'customer_address_line1',
                  controller: _line,
                  placeholder: 'House / street',
                ),
                const SizedBox(height: 12),
                AppInputField(
                  label: 'Pincode',
                  testId: 'customer_address_pincode',
                  controller: _pin,
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Save address',
                  testId: 'customer_address_save',
                  expands: true,
                  isLoading: _saving,
                  showArrow: true,
                  onPressed: () async {
                    setState(() => _saving = true);
                    try {
                      await widget.api.post('/v1/addresses', {
                        'label': 'home',
                        'line1': _line.text,
                        'pincode': _pin.text,
                        'is_default': true,
                      });
                      _line.clear();
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FetchBody(
            future: widget.api.get('/v1/addresses'),
            builder: (data) {
              final items = asMapList(data);
              return AppDataTable(
                columns: const [
                  AppTableColumn('Address', flex: 2),
                  AppTableColumn('Pincode'),
                  AppTableColumn('Default'),
                ],
                rows: [
                  for (final a in items)
                    [
                      tcell('${a['line1']}', bold: true),
                      tcell('${a['pincode']}'),
                      a['is_default'] == true
                          ? const StatusBadge('default')
                          : tcell('—', color: AppColors.subOf(context)),
                    ],
                ],
                emptyTitle: 'No saved addresses',
                emptyIcon: Icons.home_outlined,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RosterPage extends StatelessWidget {
  const _RosterPage({required this.api});
  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return WorkspacePage(
      title: 'Roster',
      subtitle: 'Service partners on your team.',
      testId: 'partner_roster',
      child: FetchBody(
        future: api.get('/v1/sp/roster'),
        builder: (data) {
          final items = asMapList(data);
          return AppDataTable(
            columns: const [
              AppTableColumn('Technician', flex: 2),
              AppTableColumn('Contact', flex: 2),
              AppTableColumn('KYC'),
              AppTableColumn('Manage', flex: 2),
            ],
            rows: [
              for (final s in items)
                [
                  Row(
                    children: [
                      FxAvatar(name: field(s, 'full_name', '?')),
                      const SizedBox(width: 10),
                      Expanded(
                        child: tcell(field(s, 'full_name'), bold: true),
                      ),
                    ],
                  ),
                  tcell(field(s, 'mobile', field(s, 'email'))),
                  StatusBadge(field(s, 'kyc_status')),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      AppButton(
                        text: 'Approve',
                        testId: 'roster_approve_${s['id']}',
                        size: AppButtonSize.sm,
                        expands: false,
                        leading: const Icon(Icons.check_rounded, size: 15),
                        onPressed: () => api.post('/v1/sp/${s['id']}/kyc', {
                          'status': 'approved',
                        }),
                      ),
                      AppButton(
                        text: 'Reject',
                        testId: 'roster_reject_${s['id']}',
                        variant: AppButtonVariant.outline,
                        size: AppButtonSize.sm,
                        expands: false,
                        onPressed: () => api.post('/v1/sp/${s['id']}/kyc', {
                          'status': 'rejected',
                        }),
                      ),
                    ],
                  ),
                ],
            ],
            emptyTitle: 'No technicians yet',
            emptyIcon: Icons.groups_outlined,
          );
        },
      ),
    );
  }
}

class _SpProfilePage extends StatefulWidget {
  const _SpProfilePage({required this.api});
  final ApiClient api;
  @override
  State<_SpProfilePage> createState() => _SpProfilePageState();
}

class _SpProfilePageState extends State<_SpProfilePage> {
  String? _msg;

  @override
  Widget build(BuildContext context) {
    return WorkspacePage(
      title: 'Your profile',
      subtitle: 'KYC unlocks the offer inbox.',
      testId: 'sp_profile',
      child: FetchBody(
        future: widget.api.get('/v1/sp/profile'),
        builder: (data) {
          final p = asMap(data);
          final pins = p['pincodes'] is List
              ? List<String>.from(
                  (p['pincodes'] as List).map((e) => '$e'),
                )
              : <String>[];
          return AppCard(
            leading: FxAvatar(name: field(p, 'full_name', '?')),
            title: field(p, 'full_name', 'Service partner'),
            description: 'KYC verification',
            trailing: StatusBadge(field(p, 'kyc_status')),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Territory pincodes',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                if (pins.isEmpty)
                  const Text('—')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final pin in pins)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.washSoft,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                            border: Border.all(color: AppColors.wash),
                          ),
                          child: Text(
                            pin,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDeep,
                            ),
                          ),
                        ),
                    ],
                  ),
                if (_msg != null) ...[
                  const SizedBox(height: 12),
                  AppAlert(
                    title: _msg!,
                    success: _msg == 'submitted',
                  ),
                ],
                const SizedBox(height: 16),
                AppButton(
                  text: 'Submit KYC (demo paths)',
                  testId: 'sp_kyc_submit',
                  expands: true,
                  showArrow: true,
                  onPressed: () async {
                    try {
                      await widget.api.put('/v1/sp/profile', {
                        'pincodes': p['pincodes'] is List &&
                                (p['pincodes'] as List).isNotEmpty
                            ? p['pincodes']
                            : ['682001'],
                        'category_ids': p['category_ids'] ?? [],
                        'aadhaar_path': 'local://masked-aadhaar',
                        'police_path': 'local://police',
                      });
                      setState(() => _msg = 'submitted');
                    } catch (e) {
                      setState(() => _msg = e.toString());
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
