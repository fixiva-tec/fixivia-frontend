import 'package:flutter_test/flutter_test.dart';
import 'package:fixvia/core/session.dart';

void main() {
  group('roleFromApi', () {
    test('maps every known role slug', () {
      expect(roleFromApi('master_admin'), UserRole.masterAdmin);
      expect(roleFromApi('partner_owner'), UserRole.partnerOwner);
      expect(roleFromApi('partner_admin'), UserRole.partnerAdmin);
      expect(roleFromApi('service_partner'), UserRole.servicePartner);
      expect(roleFromApi('customer'), UserRole.customer);
    });

    test('unknown, empty, or miscased slugs fall back to customer', () {
      for (final bad in [
        '',
        'owner',
        'admin',
        'MASTER_ADMIN',
        'Customer',
        'super_admin',
        'null',
      ]) {
        expect(roleFromApi(bad), UserRole.customer, reason: bad);
      }
    });
  });

  group('SessionUser', () {
    test('holds fields, partnerId optional', () {
      const u = SessionUser(id: 'u-1', role: UserRole.customer, fullName: 'A');
      expect(u.id, 'u-1');
      expect(u.role, UserRole.customer);
      expect(u.fullName, 'A');
      expect(u.partnerId, isNull);

      const p = SessionUser(
        id: 'u-2',
        role: UserRole.partnerOwner,
        fullName: 'B',
        partnerId: 'p-9',
      );
      expect(p.partnerId, 'p-9');
    });
  });
}
