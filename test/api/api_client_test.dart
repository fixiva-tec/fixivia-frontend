import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fixvia/api/client.dart';

void main() {
  group('ApiException', () {
    test('toString is the message', () {
      expect(ApiException('sp_ineligible').toString(), 'sp_ineligible');
    });
  });

  group('request shape', () {
    test('get joins base + path and sends auth header when set', () async {
      http.BaseRequest? seen;
      final client = ApiClient(
        baseUrl: 'http://test',
        token: 'tok-1',
        httpClient: MockClient((req) async {
          seen = req;
          return http.Response('{}', 200);
        }),
      );
      await client.get('/v1/me');
      expect(seen!.method, 'GET');
      expect(seen!.url.toString(), 'http://test/v1/me');
      expect(seen!.headers['Authorization'], 'Bearer tok-1');
      expect(seen!.headers['Content-Type'], 'application/json');
    });

    test('no auth header without a token', () async {
      http.BaseRequest? seen;
      final client = ApiClient(
        baseUrl: 'http://test',
        httpClient: MockClient((req) async {
          seen = req;
          return http.Response('{}', 200);
        }),
      );
      await client.get('/v1/me');
      expect(seen!.headers.containsKey('Authorization'), isFalse);
    });

    test('post defaults an empty body and encodes maps', () async {
      http.Request? seen;
      final client = ApiClient(
        baseUrl: 'http://test',
        httpClient: MockClient((req) async {
          seen = req;
          return http.Response('{}', 200);
        }),
      );
      await client.post('/v1/x');
      expect(seen!.method, 'POST');
      expect(seen!.body, '{}');
      await client.post('/v1/x', {'a': 1});
      expect(jsonDecode(seen!.body), {'a': 1});
    });

    test('put requires and encodes its body', () async {
      http.Request? seen;
      final client = ApiClient(
        baseUrl: 'http://test',
        httpClient: MockClient((req) async {
          seen = req;
          return http.Response('{}', 200);
        }),
      );
      await client.put('/v1/x', {'a': 2});
      expect(seen!.method, 'PUT');
      expect(jsonDecode(seen!.body), {'a': 2});
    });
  });

  group('decode', () {
    Future<dynamic> run(int status, String body) {
      final client = ApiClient(
        baseUrl: 'http://test',
        httpClient: MockClient((_) async => http.Response(body, status)),
      );
      return client.get('/v1/x');
    }

    test('decodes maps, lists, and empty bodies', () async {
      expect(await run(200, '{"a":1}'), {'a': 1});
      expect(await run(200, '[1,2]'), [1, 2]);
      expect(await run(200, ''), isNull);
      expect(await run(201, '{"ok":true}'), {'ok': true});
    });

    test('error detail map surfaces its message', () async {
      expect(
        run(400, '{"detail":"sp_ineligible"}'),
        throwsA(
          predicate(
            (e) => e is ApiException && e.message == 'sp_ineligible',
          ),
        ),
      );
    });

    test('error map without detail uses the whole body', () async {
      expect(
        run(422, '{"a":1}'),
        throwsA(
          predicate((e) => e is ApiException && e.message == '{a: 1}'),
        ),
      );
    });

    test('non-map error bodies surface raw text', () async {
      expect(
        run(500, ''),
        throwsA(
          predicate((e) => e is ApiException && e.message == ''),
        ),
      );
      expect(
        run(404, '[1]'),
        throwsA(
          predicate((e) => e is ApiException && e.message == '[1]'),
        ),
      );
    });

    test('invalid json raises FormatException', () async {
      expect(run(200, 'oops'), throwsFormatException);
    });
  });
}
