import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/components/components.dart';

/// Cheering confirmation shown right after a booking posts.
///
/// Pops with `true` when the customer taps "View booking", `false` on
/// "Done". Confetti is a one-shot deterministic painter (no packages).
class BookingConfirmedDialog extends StatefulWidget {
  const BookingConfirmedDialog({
    required this.serviceName,
    required this.subtitle,
    this.offerView = true,
    super.key,
  });

  final String serviceName;
  final String subtitle;

  /// False shows Done only (guest entry into the shell has no page yet).
  final bool offerView;

  @override
  State<BookingConfirmedDialog> createState() => _BookingConfirmedDialogState();
}

class _BookingConfirmedDialogState extends State<BookingConfirmedDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();
  late final Animation<double> _pop = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0, 0.35, curve: Curves.elasticOut),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: AppTestId(
        testId: 'booking_confirmed_dialog',
        child: SizedBox(
          width: 320,
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) => CustomPaint(
                    painter: _ConfettiPainter(progress: _ctrl.value),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _pop,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: AppColors.white,
                          size: 42,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Booking confirmed!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.serviceName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.subOf(context),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (widget.offerView) ...[
                      AppButton(
                        text: 'View booking',
                        testId: 'booking_confirmed_view',
                        expands: true,
                        onPressed: () => Navigator.pop(context, true),
                      ),
                      const SizedBox(height: 8),
                    ],
                    AppButton(
                      text: 'Done',
                      testId: 'booking_confirmed_done',
                      variant: widget.offerView
                          ? AppButtonVariant.ghost
                          : AppButtonVariant.primary,
                      expands: true,
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress});

  final double progress;

  static const _tints = <Color>[
    AppColors.primary,
    AppColors.primaryDeep,
    AppColors.success,
    AppColors.info,
    AppColors.amber,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final rng = math.Random(7);
    for (var i = 0; i < 42; i++) {
      final x0 = rng.nextDouble() * size.width;
      final speed = 0.5 + rng.nextDouble() * 0.8;
      final sway = math.sin(progress * 9 + i) * 14;
      final y = progress * speed * (size.height + 24) - 12;
      if (y < -12 || y > size.height + 12) continue;
      final paint = Paint()
        ..color = _tints[i % _tints.length].withValues(
          alpha: (1 - progress).clamp(0.0, 1.0),
        );
      canvas.save();
      canvas.translate(x0 + sway, y);
      canvas.rotate(progress * (2 + i % 4) * (i.isEven ? 1 : -1));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-4, -2.5, 8, 5),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
