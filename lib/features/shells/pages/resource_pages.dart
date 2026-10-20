import 'package:flutter/material.dart';

import '../../../api/client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/components/components.dart';
import 'workspace_page.dart';

/// Shared booking row: date badge, category, slot/pincode, quote, status.
class BookingRowCard extends StatelessWidget {
  const BookingRowCard({
    required this.booking,
    this.testId,
    this.onTap,
    super.key,
  });

  final Map<String, dynamic> booking;
  final String? testId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return AppCard(
      testId: testId,
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DateBadge(raw: field(b, 'service_date', '')),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        field(b, 'category_name', 'Booking'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(field(b, 'status')),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${pretty(field(b, 'slot'))} · ${field(b, 'pincode')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      money(b['quoted_amount']),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    if (b['technician_name'] != null) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.person_rounded,
                        size: 13,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          field(b, 'technician_name'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                    if (onTap != null)
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.primaryBright,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.raw});

  final String raw;

  static const _mo = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  @override
  Widget build(BuildContext context) {
    var day = '—';
    var mon = '';
    try {
      final d = DateTime.parse(raw);
      day = '${d.day}';
      mon = _mo[d.month - 1];
    } catch (_) {}
    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            day,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          if (mon.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              mon,
              style: const TextStyle(
                color: Color(0xE6FFFFFF),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PartnersPage extends StatefulWidget {
  const PartnersPage({required this.api, super.key});

  final ApiClient api;

  @override
  State<PartnersPage> createState() => _PartnersPageState();
}

class _PartnersPageState extends State<PartnersPage> {
  late Future<dynamic> _future = widget.api.get('/v1/partners');

  void _reload() {
    final future = widget.api.get('/v1/partners');
    setState(() {
      _future = future;
    });
  }

  Future<void> _review(Map<String, dynamic> p, String status) async {
    await widget.api.post('/v1/partners/${p['id']}/review', {
      'status': status,
      if (status == 'approved')
        'pincodes': [if (p['office_pincode'] != null) p['office_pincode']],
    });
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return WorkspacePage(
      title: 'Operation partners',
      subtitle: 'One approved partner per pincode territory.',
      testId: 'master_partners',
      child: FetchBody(
        future: _future,
        onRetry: _reload,
        builder: (data) {
          final items = asMapList(data);
          return AppDataTable(
            columns: const [
              AppTableColumn('Partner', flex: 2),
              AppTableColumn('Office pin'),
              AppTableColumn('Fee'),
              AppTableColumn('Status'),
              AppTableColumn('Manage', flex: 2),
            ],
            rows: [
              for (final p in items)
                [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      tcell(field(p, 'trade_name'), bold: true),
                      tcell(
                        field(p, 'legal_name', field(p, 'org_type')),
                        size: 12,
                        color: AppColors.subOf(context),
                      ),
                    ],
                  ),
                  tcell(field(p, 'office_pincode')),
                  tcell(money(p['license_fee_amount'])),
                  StatusBadge(field(p, 'status')),
                  if (field(p, 'status') != 'approved')
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        AppButton(
                          text: 'Approve',
                          testId: 'master_partner_approve_${p['id']}',
                          size: AppButtonSize.sm,
                          expands: false,
                          leading: const Icon(
                            Icons.check_rounded,
                            size: 15,
                          ),
                          onPressed: () => _review(p, 'approved'),
                        ),
                        AppButton(
                          text: 'Reject',
                          testId: 'master_partner_reject_${p['id']}',
                          variant: AppButtonVariant.outline,
                          size: AppButtonSize.sm,
                          expands: false,
                          onPressed: () => _review(p, 'rejected'),
                        ),
                      ],
                    )
                  else
                    tcell('—', color: AppColors.subOf(context)),
                ],
            ],
            emptyTitle: 'No partners yet',
            emptyIcon: Icons.apartment_outlined,
          );
        },
      ),
    );
  }
}

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({required this.api, super.key});

  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return WorkspacePage(
      title: 'Service categories',
      subtitle: 'Catalog shown to customers when they book.',
      testId: 'master_categories',
      child: FetchBody(
        future: api.get('/v1/categories'),
        builder: (data) {
          final items = asMapList(data);
          return AppDataTable(
            columns: const [
              AppTableColumn('Service', flex: 2),
              AppTableColumn('Visit'),
              AppTableColumn('Problems'),
              AppTableColumn('Status'),
            ],
            rows: [
              for (final c in items)
                [
                  Row(
                    children: [
                      FxServiceImage(slug: field(c, 'slug', ''), size: 40),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            tcell(field(c, 'name_en'), bold: true),
                            tcell(
                              field(c, 'slug'),
                              size: 12,
                              color: AppColors.subOf(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  tcell('${field(c, 'estimated_minutes', '60')} min'),
                  tcell(
                    c['problems'] is List
                        ? '${(c['problems'] as List).length} templates'
                        : '—',
                  ),
                  c['featured_rank'] != null
                      ? StatusBadge('featured #${c['featured_rank']}')
                      : StatusBadge(
                          c['is_active'] == false ? 'inactive' : 'active',
                        ),
                ],
            ],
            emptyTitle: 'No categories yet',
            emptyIcon: Icons.category_outlined,
          );
        },
      ),
    );
  }
}

class AdminRequestsPage extends StatefulWidget {
  const AdminRequestsPage({required this.api, super.key});

  final ApiClient api;

  @override
  State<AdminRequestsPage> createState() => _AdminRequestsPageState();
}

class _AdminRequestsPageState extends State<AdminRequestsPage> {
  late Future<dynamic> _future = widget.api.get('/v1/partner-admin-requests');

  void _reload() {
    final future = widget.api.get('/v1/partner-admin-requests');
    setState(() {
      _future = future;
    });
  }

  Future<void> _review(Map<String, dynamic> r, String status) async {
    await widget.api.post(
      '/v1/partner-admin-requests/${r['id']}/review',
      {'status': status},
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return WorkspacePage(
      title: 'Partner admin requests',
      subtitle: 'Owners request extra admins; you approve the account.',
      testId: 'master_admin_reqs',
      child: FetchBody(
        future: _future,
        onRetry: _reload,
        builder: (data) {
          final items = asMapList(data);
          return AppDataTable(
            columns: const [
              AppTableColumn('Name', flex: 2),
              AppTableColumn('Contact', flex: 2),
              AppTableColumn('Status'),
              AppTableColumn('Manage', flex: 2),
            ],
            rows: [
              for (final r in items)
                [
                  Row(
                    children: [
                      FxAvatar(name: field(r, 'full_name', '?')),
                      const SizedBox(width: 10),
                      Expanded(child: tcell(field(r, 'full_name'), bold: true)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      tcell(field(r, 'email', field(r, 'mobile'))),
                      tcell(
                        field(r, 'mobile'),
                        size: 12,
                        color: AppColors.subOf(context),
                      ),
                    ],
                  ),
                  StatusBadge(field(r, 'status')),
                  if (field(r, 'status') == 'submitted')
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        AppButton(
                          text: 'Approve',
                          testId: 'master_admin_approve_${r['id']}',
                          size: AppButtonSize.sm,
                          expands: false,
                          leading: const Icon(
                            Icons.check_rounded,
                            size: 15,
                          ),
                          onPressed: () => _review(r, 'approved'),
                        ),
                        AppButton(
                          text: 'Reject',
                          testId: 'master_admin_reject_${r['id']}',
                          variant: AppButtonVariant.outline,
                          size: AppButtonSize.sm,
                          expands: false,
                          onPressed: () => _review(r, 'rejected'),
                        ),
                      ],
                    )
                  else
                    tcell('—', color: AppColors.subOf(context)),
                ],
            ],
            emptyTitle: 'No partner-admin requests',
            emptyIcon: Icons.person_add_outlined,
          );
        },
      ),
    );
  }
}

class InvoicesPage extends StatelessWidget {
  const InvoicesPage({required this.api, super.key});

  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return WorkspacePage(
      title: 'SaaS invoices',
      subtitle: 'License fees — not job GMV.',
      testId: 'master_invoices',
      child: FetchBody(
        future: api.get('/v1/invoices'),
        builder: (data) {
          final items = asMapList(data);
          return AppDataTable(
            columns: const [
              AppTableColumn('Amount'),
              AppTableColumn('Period', flex: 2),
              AppTableColumn('Partner', flex: 2),
              AppTableColumn('Status'),
            ],
            rows: [
              for (final inv in items)
                [
                  tmoney(money(inv['amount'])),
                  tcell(
                    '${field(inv, 'period_start')} → ${field(inv, 'period_end')}',
                  ),
                  tcell(field(inv, 'partner_id')),
                  StatusBadge(field(inv, 'status')),
                ],
            ],
            emptyTitle: 'No invoices yet',
            emptyIcon: Icons.receipt_long_outlined,
          );
        },
      ),
    );
  }
}

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({required this.api, required this.testId, super.key});

  final ApiClient api;
  final String testId;

  @override
  Widget build(BuildContext context) {
    return WorkspacePage(
      title: 'Analytics',
      subtitle: 'Last 30 days. Job GMV is separate from SaaS license fees.',
      testId: testId,
      child: FetchBody(
        future: api.get('/v1/analytics'),
        skeletonRows: 4,
        builder: (data) {
          final a = asMap(data);
          final saas = asMap(a['saas_license_fees']);
          final partners = asMapList(a['by_partner']);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 640;
                  final w = wide
                      ? (constraints.maxWidth - 24) / 4
                      : (constraints.maxWidth - 12) / 2;
                  Widget cell(Widget c) => SizedBox(width: w, child: c);
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      cell(_metric(
                        'Created',
                        field(a, 'created', '0'),
                        Icons.add_circle_outline_rounded,
                        AppColors.info,
                      )),
                      cell(_metric(
                        'Open',
                        field(a, 'still_open', '0'),
                        Icons.pending_actions_rounded,
                        AppColors.primary,
                      )),
                      cell(_metric(
                        'Accepted',
                        field(a, 'accepted', '0'),
                        Icons.task_alt_rounded,
                        AppColors.warning,
                      )),
                      cell(_metric(
                        'Completed',
                        field(a, 'completed', '0'),
                        Icons.verified_rounded,
                        AppColors.successDeep,
                      )),
                      cell(_metric(
                        'Cancelled',
                        field(a, 'cancelled', '0'),
                        Icons.cancel_outlined,
                        AppColors.danger,
                      )),
                      cell(_metric(
                        'Job GMV',
                        money(a['gmv_completed']),
                        Icons.currency_rupee_rounded,
                        AppColors.primaryDeep,
                      )),
                      cell(_metric(
                        'Commission',
                        money(a['commission_completed']),
                        Icons.percent_rounded,
                        AppColors.primaryBright,
                      )),
                      cell(_metric(
                        'Median accept',
                        a['median_accept_minutes'] == null
                            ? '—'
                            : '${a['median_accept_minutes']} min',
                        Icons.timer_outlined,
                        AppColors.ink,
                      )),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              AppCard(
                title: 'Booking funnel',
                description: 'Created → accepted → completed.',
                child: _TrendBars(
                  values: [
                    _intOf(a['created']),
                    _intOf(a['accepted']),
                    _intOf(a['completed']),
                  ],
                  labels: const ['Created', 'Accepted', 'Done'],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                leading: const FxServiceTile(
                  icon: Icons.account_balance_rounded,
                ),
                title: 'SaaS license fees',
                description: field(saas, 'note', field(a, 'gmv_note')),
                child: Column(
                  children: [
                    InfoRow('Invoiced', money(saas['invoiced'])),
                    InfoRow('Collected', money(saas['collected'])),
                    InfoRow('Overdue', money(saas['overdue'])),
                  ],
                ),
              ),
              if (partners.isNotEmpty) ...[
                const SizedBox(height: 16),
                AppCard(
                  title: 'By partner',
                  description: 'Completion rate per operation partner.',
                  child: Column(
                    children: [
                      for (var i = 0; i < partners.length; i++) ...[
                        if (i > 0) const SizedBox(height: 14),
                        _PartnerBar(partner: partners[i]),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon, Color tint) {
    return MetricCard(label: label, value: value, icon: icon, tint: tint);
  }
}

int _intOf(dynamic value) => int.tryParse('$value') ?? 0;

/// Compact bar trio painted from real aggregates (no chart package).
class _TrendBars extends StatelessWidget {
  const _TrendBars({required this.values, required this.labels});

  final List<int> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final max = values.fold<int>(1, (m, v) => v > m ? v : m);
    const tints = [AppColors.info, AppColors.warning, AppColors.successDeep];
    return SizedBox(
      height: 148,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${values[i]}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: FractionallySizedBox(
                        heightFactor: values[i] <= 0
                            ? 0.04
                            : (values[i] / max).clamp(0.04, 1.0),
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                tints[i % tints.length],
                                tints[i % tints.length].withValues(alpha: 0.55),
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.subOf(context),
                        fontWeight: FontWeight.w600,
                      ),
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

class _PartnerBar extends StatelessWidget {
  const _PartnerBar({required this.partner});

  final Map<String, dynamic> partner;

  @override
  Widget build(BuildContext context) {
    final created = int.tryParse(field(partner, 'created', '0')) ?? 0;
    final completed = int.tryParse(field(partner, 'completed', '0')) ?? 0;
    final ratio = created <= 0 ? 0.0 : (completed / created).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                field(partner, 'trade_name'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$completed / $created done',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 9,
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

class BookingsListPage extends StatelessWidget {
  const BookingsListPage({
    required this.api,
    required this.testId,
    required this.title,
    this.path = '/v1/bookings',
    this.onOpen,
    super.key,
  });

  final ApiClient api;
  final String testId;
  final String title;
  final String path;
  final void Function(String id)? onOpen;

  @override
  Widget build(BuildContext context) {
    return WorkspacePage(
      title: title,
      testId: testId,
      child: FetchBody(
        future: api.get(path),
        builder: (data) {
          final items = asMapList(data);
          return AppDataTable(
            columns: const [
              AppTableColumn('Service', flex: 2),
              AppTableColumn('Date'),
              AppTableColumn('Slot'),
              AppTableColumn('Amount'),
              AppTableColumn('Status'),
            ],
            rows: [
              for (final b in items)
                [
                  tcell(field(b, 'category_name', 'Booking'), bold: true),
                  tcell(field(b, 'service_date')),
                  tcell(pretty(field(b, 'slot'))),
                  tmoney(money(b['quoted_amount'])),
                  StatusBadge(field(b, 'status')),
                ],
            ],
            rowTestIds: [for (final b in items) '${testId}_item_${b['id']}'],
            onRowTap: onOpen == null
                ? null
                : (i) {
                    final id = items[i]['id'];
                    if (id != null) onOpen!(id as String);
                  },
            emptyTitle: 'No bookings yet',
            emptyIcon: Icons.event_available_outlined,
          );
        },
      ),
    );
  }
}

class PricingPage extends StatelessWidget {
  const PricingPage({required this.api, super.key});

  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return WorkspacePage(
      title: 'Visit pricing',
      subtitle: 'Charges you set per service category.',
      testId: 'partner_pricing',
      child: FetchBody(
        future: Future.wait([
          api.get('/v1/partner/pricing'),
          api.get('/v1/categories'),
        ]),
        builder: (data) {
          final pair = data as List<dynamic>;
          final prices = asMapList(pair[0]);
          final cats = {
            for (final c in asMapList(pair[1]))
              field(c, 'id'): c,
          };
          return AppDataTable(
            columns: const [
              AppTableColumn('Service', flex: 2),
              AppTableColumn('Visit charge'),
              AppTableColumn('Status'),
            ],
            rows: [
              for (final p in prices)
                [
                  Builder(builder: (context) {
                    final cat = cats[field(p, 'category_id')];
                    final name = cat == null
                        ? field(p, 'category_id')
                        : field(cat, 'name_en');
                    return Row(
                      children: [
                        FxServiceImage(
                          slug: cat == null
                              ? null
                              : field(cat, 'slug', ''),
                          size: 36,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: tcell(name, bold: true)),
                      ],
                    );
                  }),
                  tmoney(money(p['visit_charge'])),
                  StatusBadge(p['enabled'] == false ? 'disabled' : 'enabled'),
                ],
            ],
            emptyTitle: 'No pricing rows yet',
            emptyIcon: Icons.sell_outlined,
          );
        },
      ),
    );
  }
}

class SchedulePage extends StatelessWidget {
  const SchedulePage({required this.api, super.key});

  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return WorkspacePage(
      title: 'Tomorrow’s schedule',
      subtitle: 'Route order per session.',
      testId: 'sp_schedule',
      child: FetchBody(
        future: api.get('/v1/sp/schedule'),
        builder: (data) {
          final s = asMap(data);
          final morning = asMapList(s['morning']);
          final evening = asMapList(s['evening']);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border: Border.all(color: AppColors.lineOf(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 17,
                      color: AppColors.primaryBright,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Date ${field(s, 'date')}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _slotTable(
                'Morning',
                '09:00 – 13:00',
                Icons.wb_sunny_rounded,
                morning,
              ),
              const SizedBox(height: 12),
              _slotTable(
                'Evening',
                '13:00 – 18:00',
                Icons.nights_stay_rounded,
                evening,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _slotTable(
    String label,
    String time,
    IconData icon,
    List<Map<String, dynamic>> jobs,
  ) {
    return AppCard(
      title: '$label · $time',
      child: AppDataTable(
        dense: true,
        columns: const [
          AppTableColumn('#', flex: 1),
          AppTableColumn('Job', flex: 3),
          AppTableColumn('Pincode', flex: 2),
          AppTableColumn('Status', flex: 2),
        ],
        rows: [
          for (var i = 0; i < jobs.length; i++)
            [
              tcell('${i + 1}', bold: true, color: AppColors.primary),
              tcell(field(jobs[i], 'category_name', field(jobs[i], 'pincode'))),
              tcell(field(jobs[i], 'pincode')),
              StatusBadge(field(jobs[i], 'status')),
            ],
        ],
        emptyTitle: 'Nothing scheduled — enjoy the breather.',
        emptyIcon: icon,
      ),
    );
  }
}

class EarningsPage extends StatelessWidget {
  const EarningsPage({required this.api, super.key});

  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return WorkspacePage(
      title: 'Earnings',
      subtitle: 'Partner-defined payouts for completed jobs.',
      testId: 'sp_earnings',
      child: FetchBody(
        future: api.get('/v1/sp/earnings'),
        skeletonRows: 2,
        builder: (data) {
          final e = asMap(data);
          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 560;
              final w = wide
                  ? (constraints.maxWidth - 24) / 3
                  : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: w,
                    child: MetricCard(
                      label: 'Pending',
                      value: money(e['pending']),
                      icon: Icons.hourglass_top_rounded,
                      tint: AppColors.warning,
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: MetricCard(
                      label: 'Paid',
                      value: money(e['paid']),
                      icon: Icons.verified_rounded,
                      tint: AppColors.successDeep,
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: MetricCard(
                      label: 'Jobs',
                      value: field(e, 'jobs', '0'),
                      icon: Icons.work_rounded,
                      tint: AppColors.primary,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
