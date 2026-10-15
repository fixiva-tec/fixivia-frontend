import 'package:flutter_test/flutter_test.dart';
import 'package:fixvia/core/booking_rules.dart';

void main() {
  group('earliestServiceDate', () {
    test('is exactly 48 hours out', () {
      final now = DateTime(2026, 9, 4, 10, 30);
      expect(earliestServiceDate(now), now.add(const Duration(hours: 48)));
    });
  });

  group('isServiceDateAllowed boundaries', () {
    test('day granularity around the +2 day line', () {
      final now = DateTime(2026, 9, 4, 10);
      expect(isServiceDateAllowed(DateTime(2026, 9, 6), now), isTrue);
      expect(isServiceDateAllowed(DateTime(2026, 9, 6, 23, 59), now), isTrue);
      expect(isServiceDateAllowed(DateTime(2026, 9, 5, 23, 59), now), isFalse);
      expect(isServiceDateAllowed(DateTime(2026, 9, 4), now), isFalse);
      expect(isServiceDateAllowed(DateTime(2026, 9, 10), now), isTrue);
    });

    test('late-night now still allows the +2 calendar day', () {
      final now = DateTime(2026, 9, 4, 23, 59);
      expect(isServiceDateAllowed(DateTime(2026, 9, 6), now), isTrue);
      expect(isServiceDateAllowed(DateTime(2026, 9, 5), now), isFalse);
    });

    test('month and year boundaries', () {
      expect(
        isServiceDateAllowed(DateTime(2026, 2, 1), DateTime(2026, 1, 30, 9)),
        isTrue,
      );
      expect(
        isServiceDateAllowed(DateTime(2026, 1, 31), DateTime(2026, 1, 30, 9)),
        isFalse,
      );
      expect(
        isServiceDateAllowed(DateTime(2027, 1, 1), DateTime(2026, 12, 30, 9)),
        isTrue,
      );
    });
  });

  group('forceAssignReady edges', () {
    final now = DateTime(2026, 10, 15, 12, 0);

    Map<String, dynamic> booking({
      String? status = 'open',
      Object? ready,
      Object? refreshes = 1,
      Object? created,
    }) => {
      'status': status,
      'force_assign_ready': ready,
      'dispatch_refresh_count': refreshes,
      'created_at': (created ?? now).toString(),
    };

    test('missing or null status is never ready', () {
      expect(forceAssignReady({}, now), isFalse);
      expect(forceAssignReady(booking(status: null, ready: true), now), isFalse);
    });

    test('non-open statuses are never ready even when flagged', () {
      for (final st in [
        'assigned',
        'en_route',
        'in_progress',
        'completed',
        'cancelled',
      ]) {
        expect(
          forceAssignReady(booking(status: st, ready: true, refreshes: 9), now),
          isFalse,
          reason: st,
        );
      }
    });

    test('server flag wins only on literal true', () {
      expect(forceAssignReady(booking(ready: true), now), isTrue);
      expect(forceAssignReady(booking(ready: false), now), isFalse);
      expect(forceAssignReady(booking(ready: 'yes'), now), isFalse);
      expect(forceAssignReady(booking(ready: 1), now), isFalse);
      expect(forceAssignReady(booking(ready: null), now), isFalse);
    });

    test('refresh count needs a real int >= 2', () {
      expect(forceAssignReady(booking(refreshes: 2), now), isTrue);
      expect(forceAssignReady(booking(refreshes: 9), now), isTrue);
      expect(forceAssignReady(booking(refreshes: 1), now), isFalse);
      expect(forceAssignReady(booking(refreshes: 0), now), isFalse);
      expect(forceAssignReady(booking(refreshes: -2), now), isFalse);
      expect(forceAssignReady(booking(refreshes: '2'), now), isFalse);
      expect(forceAssignReady(booking(refreshes: null), now), isFalse);
    });

    test('age gate honors the exact 3h line', () {
      String at(Duration ago) =>
          now.subtract(ago).toIso8601String();
      expect(
        forceAssignReady(booking(created: at(const Duration(hours: 3))), now),
        isTrue,
      );
      expect(
        forceAssignReady(
          booking(created: at(const Duration(hours: 3) - Duration(seconds: 1))),
          now,
        ),
        isFalse,
      );
      expect(
        forceAssignReady(booking(created: at(const Duration(hours: 5))), now),
        isTrue,
      );
    });

    test('missing or garbage created_at falls back to not ready', () {
      final missing = {'status': 'open'};
      expect(forceAssignReady(missing, now), isFalse);
      expect(forceAssignReady(booking(created: 'not-a-date'), now), isFalse);
      expect(forceAssignReady(booking(created: ''), now), isFalse);
    });
  });
}
