import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../core/catalog.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/components/components.dart';
import '../../shared/widgets/fx_logo.dart';
import '../auth/auth_api.dart';
import '../auth/auth_screen.dart';
import '../customer/booking_confirmed_dialog.dart';
import '../customer/booking_flow.dart';
import '../customer/guest_draft.dart';

/// Public business page: the app's front door.
///
/// Guests read services and coverage, check their pincode, and walk the
/// booking flow without an account. Login lives top-right; confirming as
/// a guest routes through [AuthScreen] and the draft submits right after.
class LandingPage extends StatefulWidget {
  const LandingPage({
    required this.api,
    required this.authApi,
    required this.onAuthenticated,
    super.key,
  });

  final ApiClient api;
  final AuthApi authApi;
  final void Function(AuthResult result) onAuthenticated;

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _pin = TextEditingController();
  List<dynamic> _services = [];
  Set<String> _served = {};
  var _loaded = false;
  String? _error;
  String? _pinVerdict;
  var _pinOk = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        widget.api.get('/v1/categories'),
        widget.api.get('/v1/pincodes?served_only=true'),
      ]);
      if (!mounted) return;
      setState(() {
        _services = results[0] as List<dynamic>;
        _served = {
          for (final p in results[1] as List<dynamic>) '${p['pincode']}',
        };
        _loaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loaded = true;
      });
    }
  }

  void _checkPin() {
    final code = _pin.text.trim();
    setState(() {
      if (code.length != 6 || int.tryParse(code) == null) {
        _pinVerdict = 'Enter a 6-digit pincode';
        _pinOk = false;
      } else if (_served.contains(code)) {
        _pinVerdict = 'Yes — we serve $code. Book below.';
        _pinOk = true;
      } else {
        _pinVerdict = 'Not in $code yet — we are expanding soon.';
        _pinOk = false;
      }
    });
  }

  Future<void> _login() async {
    final result = await Navigator.push<AuthResult>(
      context,
      MaterialPageRoute(
        builder: (_) => AuthScreen(
          api: widget.authApi,
          onAuthenticated: (r) => Navigator.pop(context, r),
        ),
      ),
    );
    if (result != null && mounted) widget.onAuthenticated(result);
  }

  Future<void> _openGuestFlow([String? categoryId]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingFlow(
          api: widget.api,
          initialCategoryId: categoryId,
          onGuestConfirm: _gateGuest,
        ),
      ),
    );
  }

  /// Auth gate for a guest draft: login first, then submit.
  ///
  /// The pincode is pre-checked against the served list so a guest never
  /// burns an OTP on an area we cannot serve; the server re-checks anyway.
  /// Returning normally means booked (the app enters the shell); throwing
  /// surfaces the message on the flow with the draft intact.
  Future<void> _gateGuest(GuestDraft draft) async {
    if (_served.isNotEmpty && !_served.contains(draft.pincode)) {
      throw ApiException("We don't serve ${draft.pincode} yet");
    }
    final result = await Navigator.push<AuthResult>(
      context,
      MaterialPageRoute(
        builder: (_) => AuthScreen(
          api: widget.authApi,
          onAuthenticated: (r) => Navigator.pop(context, r),
        ),
      ),
    );
    if (result == null) return;
    widget.api.token = result.token;
    try {
      await submitGuestDraft(widget.api, draft);
    } catch (_) {
      widget.api.token = null;
      rethrow;
    }
    if (!mounted) return;
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BookingConfirmedDialog(
        serviceName: _serviceName(draft.categoryId),
        subtitle:
            '${draft.serviceDate} · ${draft.slot == 'evening' ? 'Evening' : 'Morning'} · we will notify you on accept.',
        offerView: false,
      ),
    );
    if (!mounted) return;
    Navigator.pop(context);
    widget.onAuthenticated(result);
  }

  @override
  Widget build(BuildContext context) {
    // Full-bleed page: the single ListView below is the only scroller,
    // so its scrollbar sits at the window edge like a browser scroll.
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 32),
          children: [
                Row(
                  children: [
                    const FxLogo(height: 30),
                    const Spacer(),
                    AppButton(
                      text: 'Login',
                      testId: 'landing_login',
                      variant: AppButtonVariant.outline,
                      size: AppButtonSize.sm,
                      expands: false,
                      onPressed: _login,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  child: SizedBox(
                    height: 240,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/services/hero.jpg',
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withValues(alpha: 0.68),
                                Colors.black.withValues(alpha: 0.18),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 20,
                          right: 20,
                          bottom: 18,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Home services at your doorstep',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Verified local technicians for repair, '
                                'plumbing, electrical and more.',
                                style: TextStyle(
                                  color: Color(0xE6FFFFFF),
                                  fontSize: 14,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 12),
                              AppButton(
                                text: 'Book a service',
                                testId: 'landing_book',
                                expands: false,
                                onPressed: () => _openGuestFlow(),
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
                  title: 'Check your pincode',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppInputField(
                              testId: 'landing_pin_input',
                              controller: _pin,
                              placeholder: 'e.g. 682001',
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: AppButton(
                              text: 'Check',
                              testId: 'landing_pin_check',
                              variant: AppButtonVariant.secondary,
                              expands: false,
                              onPressed: _checkPin,
                            ),
                          ),
                        ],
                      ),
                      if (_pinVerdict != null) ...[
                        const SizedBox(height: 10),
                        AppAlert(
                          title: _pinVerdict!,
                          success: _pinOk,
                          destructive: !_pinOk,
                        ),
                      ],
                      if (_served.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final code in _served)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.washSoft,
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.pill,
                                  ),
                                ),
                                child: Text(
                                  code,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (!_loaded)
                  const AppCard(child: LoadingSkeleton(rows: 3))
                else if (_error != null)
                  AppAlert(title: _error!, destructive: true)
                else
                  AppCard(
                    title: 'Our services',
                    child: Column(
                      children: [
                        for (final s in _services)
                          _ServiceRow(
                            name: '${s['name_en'] ?? ''}',
                            detail: _serviceDetail(s),
                            slug: '${s['slug'] ?? ''}',
                            live: isBookableCategory('${s['slug'] ?? ''}'),
                            onTap: () =>
                                _openGuestFlow(s['id'] as String?),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                const AppCard(
                  title: 'Why Fixiva',
                  child: Column(
                    children: [
                      _TrustRow(
                        text: 'Background-verified local technicians',
                      ),
                      SizedBox(height: 8),
                      _TrustRow(text: 'On-time visits with live status'),
                      SizedBox(height: 8),
                      _TrustRow(text: 'Pay cash or UPI after the job'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const AppCard(
                  title: 'How it works',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HowRow(
                        step: '1',
                        text: 'Pick a service and describe the problem',
                      ),
                      SizedBox(height: 8),
                      _HowRow(step: '2', text: 'Choose a day and time slot'),
                      SizedBox(height: 8),
                      _HowRow(
                        step: '3',
                        text: 'Login once to confirm — done',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Fixiva · Trusted home services in Kerala',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
  }

  String _serviceName(String id) {
    for (final s in _services) {
      if (s['id'] == id) return '${s['name_en'] ?? 'Booking'}';
    }
    return 'Booking';
  }

  String _serviceDetail(Map<String, dynamic> s) {
    final problems = s['problems'] as List<dynamic>?;
    if (problems == null || problems.isEmpty) return 'Tap to book';
    final names = [
      for (final p in problems.take(3)) '${p['text_en'] ?? ''}',
    ].where((n) => n.isNotEmpty).join(' · ');
    return names.isEmpty ? 'Tap to book' : names;
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.name,
    required this.detail,
    required this.slug,
    required this.onTap,
    this.live = true,
  });

  final String name;
  final String detail;
  final String slug;
  final VoidCallback onTap;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: live ? 1 : 0.6,
      child: AppTestId(
        testId: 'landing_service_$slug',
        child: MouseRegion(
          cursor: live
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: GestureDetector(
            // Opaque: the whole row taps, not just text and icons.
            behavior: HitTestBehavior.opaque,
            onTap: live ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                FxServiceImage(slug: slug, size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (live)
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: AppColors.primary,
                  )
                else
                  const ComingSoonBadge(),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.verified_rounded,
          size: 18,
          color: AppColors.successDeep,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _HowRow extends StatelessWidget {
  const _HowRow({required this.step, required this.text});

  final String step;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            step,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
