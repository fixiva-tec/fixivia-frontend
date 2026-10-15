import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fixvia/core/session.dart';
import 'package:fixvia/features/auth/http_auth_api.dart';

void main() {
  group('requestOtp', () {
    test('posts mobile + purpose, ok on 200', () async {
      http.Request? seen;
      final api = HttpAuthApi(
        baseUrl: 'http://test',
        client: MockClient((req) async {
          seen = req;
          return http.Response('{}', 200);
        }),
      );
      await api.requestOtp(mobile: '9876543210', purpose: 'login');
      expect(seen!.url.toString(), 'http://test/v1/otp/request');
      expect(
        jsonDecode(seen!.body),
        {'mobile': '9876543210', 'purpose': 'login'},
      );
    });

    test('non-200 throws', () async {
      final api = HttpAuthApi(
        baseUrl: 'http://test',
        client: MockClient((_) async => http.Response('x', 500)),
      );
      await expectLater(
        api.requestOtp(mobile: '1', purpose: 'login'),
        throwsA(
          predicate((e) => '$e'.contains('otp_request_failed')),
        ),
      );
    });
  });

  group('publicPartners', () {
    test('maps the list on 200', () async {
      final api = HttpAuthApi(
        baseUrl: 'http://test',
        client: MockClient(
          (_) async => http.Response(
            '[{"id":"p1","trade_name":"Acme"}]',
            200,
          ),
        ),
      );
      expect(
        await api.publicPartners(),
        [
          {'id': 'p1', 'trade_name': 'Acme'},
        ],
      );
    });

    test('non-200 yields empty (dev flavor off)', () async {
      final api = HttpAuthApi(
        baseUrl: 'http://test',
        client: MockClient((_) async => http.Response('x', 404)),
      );
      expect(await api.publicPartners(), isEmpty);
    });
  });

  group('verifyOtp', () {
    test('minimal body omits unset optionals', () async {
      http.Request? seen;
      final api = HttpAuthApi(
        baseUrl: 'http://test',
        client: MockClient((req) async {
          seen = req;
          return http.Response(
            '{"token":"t","user":{"id":"u","role":"customer",'
            '"full_name":"C","partner_id":null}}',
            200,
          );
        }),
      );
      final out = await api.verifyOtp(
        mobile: '9876543210',
        purpose: 'login',
        code: '123456',
      );
      expect(
        jsonDecode(seen!.body),
        {'mobile': '9876543210', 'purpose': 'login', 'code': '123456'},
      );
      expect(out.token, 't');
      expect(out.user.role, UserRole.customer);
      expect(out.user.partnerId, isNull);
    });

    test('full body carries registration fields', () async {
      http.Request? seen;
      final api = HttpAuthApi(
        baseUrl: 'http://test',
        client: MockClient((req) async {
          seen = req;
          return http.Response(
            '{"token":"t","user":{"id":"u","role":"partner_owner",'
            '"full_name":"O","partner_id":"p1"}}',
            200,
          );
        }),
      );
      final out = await api.verifyOtp(
        mobile: '9876543210',
        purpose: 'register',
        code: '123456',
        fullName: 'O',
        role: 'partner_owner',
        partnerId: 'p1',
      );
      expect(
        jsonDecode(seen!.body),
        {
          'mobile': '9876543210',
          'purpose': 'register',
          'code': '123456',
          'full_name': 'O',
          'role': 'partner_owner',
          'partner_id': 'p1',
        },
      );
      expect(out.user.role, UserRole.partnerOwner);
      expect(out.user.partnerId, 'p1');
    });

    test('unknown roles fall back to customer', () async {
      final api = HttpAuthApi(
        baseUrl: 'http://test',
        client: MockClient(
          (_) async => http.Response(
            '{"token":"t","user":{"id":"u","role":"weird",'
            '"full_name":"W","partner_id":null}}',
            200,
          ),
        ),
      );
      final out = await api.verifyOtp(
        mobile: '1',
        purpose: 'login',
        code: '123456',
      );
      expect(out.user.role, UserRole.customer);
    });

    test('non-200 throws', () async {
      final api = HttpAuthApi(
        baseUrl: 'http://test',
        client: MockClient((_) async => http.Response('x', 401)),
      );
      await expectLater(
        api.verifyOtp(mobile: '1', purpose: 'login', code: '000000'),
        throwsA(
          predicate((e) => '$e'.contains('otp_verify_failed')),
        ),
      );
    });
  });

  group('injectDevUsers', () {
    test('maps accounts, tolerates missing list', () async {
      MockClient client(String body) =>
          MockClient((_) async => http.Response(body, 200));
      final two = HttpAuthApi(baseUrl: 'http://test', client: client(
        '{"accounts":[{"token":"t1","user":{"id":"u1","role":"customer",'
        '"full_name":"A","partner_id":null}},{"token":"t2",'
        '"user":{"id":"u2","role":"master_admin","full_name":"M",'
        '"partner_id":null}}]}',
      ));
      final rows = await two.injectDevUsers();
      expect(rows, hasLength(2));
      expect(rows[0].user.role, UserRole.customer);
      expect(rows[1].user.role, UserRole.masterAdmin);

      final missing = HttpAuthApi(
        baseUrl: 'http://test',
        client: client('{}'),
      );
      expect(await missing.injectDevUsers(), isEmpty);
    });

    test('non-200 yields empty', () async {
      final api = HttpAuthApi(
        baseUrl: 'http://test',
        client: MockClient((_) async => http.Response('x', 404)),
      );
      expect(await api.injectDevUsers(), isEmpty);
    });
  });
}
