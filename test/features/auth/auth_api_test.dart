import 'package:flutter_test/flutter_test.dart';
import 'package:fixvia/core/session.dart';
import 'package:fixvia/features/auth/auth_api.dart';

void main() {
  test('AuthResult holds token and user', () {
    const user = SessionUser(
      id: 'u-1',
      role: UserRole.servicePartner,
      fullName: 'Ravi',
      partnerId: 'p-1',
    );
    const result = AuthResult(token: 'tok', user: user);
    expect(result.token, 'tok');
    expect(result.user, same(user));
  });
}
