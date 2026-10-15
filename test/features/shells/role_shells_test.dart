import 'package:flutter_test/flutter_test.dart';
import 'package:fixvia/core/session.dart';
import 'package:fixvia/features/shells/role_shells.dart';

import '../../helpers/test_helpers.dart';

void main() {
  test('shellFor builds a WorkspaceShell for every role', () {
    final api = testApi(FakeHttp());
    var loggedOut = 0;
    for (final role in UserRole.values) {
      final user = testUser(role);
      final w = shellFor(user, api, onLogout: () => loggedOut++);
      expect(w, isA<WorkspaceShell>());
      final shell = w as WorkspaceShell;
      expect(shell.user, same(user));
      expect(shell.api, same(api));
      shell.onLogout!();
    }
    expect(loggedOut, UserRole.values.length);
  });

  test('shellFor logout is optional', () {
    final w = shellFor(testUser(UserRole.customer), testApi(FakeHttp()));
    expect((w as WorkspaceShell).onLogout, isNull);
  });
}
