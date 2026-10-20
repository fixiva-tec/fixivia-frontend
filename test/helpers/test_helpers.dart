import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:fixvia/api/client.dart';
import 'package:fixvia/core/session.dart';
import 'package:fixvia/core/theme/app_theme.dart';
import 'package:fixvia/features/auth/auth_api.dart';
import 'package:fixvia/l10n/app_localizations.dart';

/// Scriptable [AuthApi] fake. Set fields to script behavior; calls are logged.
class FakeAuthApi implements AuthApi {
  Object? requestError;
  Object? verifyError;
  AuthResult? verifyResult;
  List<Map<String, dynamic>> partners = [];

  final List<Map<String, String>> requested = [];
  final List<Map<String, String?>> verified = [];

  @override
  Future<void> requestOtp({
    required String mobile,
    required String purpose,
  }) async {
    requested.add({'mobile': mobile, 'purpose': purpose});
    if (requestError != null) throw requestError!;
  }

  @override
  Future<List<Map<String, dynamic>>> publicPartners() async => partners;

  @override
  Future<AuthResult> verifyOtp({
    required String mobile,
    required String purpose,
    required String code,
    String? fullName,
    String? role,
    String? partnerId,
  }) async {
    verified.add({
      'mobile': mobile,
      'purpose': purpose,
      'code': code,
      'fullName': fullName,
      'role': role,
      'partnerId': partnerId,
    });
    if (verifyError != null) throw verifyError!;
    return verifyResult ??
        AuthResult(
          token: 'tok-$mobile',
          user: SessionUser(
            id: 'u-$mobile',
            role: roleFromApi(role ?? 'customer'),
            fullName: fullName ?? 'Test User',
            partnerId: partnerId,
          ),
        );
  }
}

/// Route-table fake HTTP client. Unmatched paths return `{}` with 200.
/// Handlers may return a [Future] to gate responses behind a Completer.
class FakeHttp extends http.BaseClient {
  FakeHttp(
      [Map<String, FutureOr<http.Response> Function(http.BaseRequest)>?
          routes])
      : routes = routes ?? {};

  final Map<String, FutureOr<http.Response> Function(http.BaseRequest)> routes;
  final List<http.BaseRequest> requests = [];

  static http.Response json(Object body, [int status = 200]) =>
      http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json'},
      );

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    final handler = routes[request.url.path];
    final res = handler == null ? json({}) : await handler(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(res.body)),
      res.statusCode,
      request: request,
      headers: res.headers,
    );
  }
}

/// ApiClient wired to [fake] at a dummy base URL.
ApiClient testApi(FakeHttp fake, {String? token}) =>
    ApiClient(baseUrl: 'http://test', token: token, httpClient: fake);

/// Minimal Material shell for theme components (no localizations needed).
Widget themeHarness(Widget child, {bool dark = false}) {
  return MaterialApp(
    theme: buildAppTheme(Brightness.light),
    darkTheme: buildAppTheme(Brightness.dark),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    home: Scaffold(body: child),
  );
}

/// Material shell with localizations, for shells/flows needing both.
Widget shellHarness(Widget child, {bool dark = false}) {
  return MaterialApp(
    theme: buildAppTheme(Brightness.light),
    darkTheme: buildAppTheme(Brightness.dark),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

/// Full app shell with Material + localizations, like the real app.
Widget materialHarness(Widget child, {bool dark = false}) {
  return MaterialApp(
    theme: buildAppTheme(dark ? Brightness.dark : Brightness.light),
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

/// Desktop viewport with automatic teardown.
void desktopSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Phone viewport with automatic teardown.
void compactSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

SessionUser testUser(
  UserRole role, {
  String id = 'u-1',
  String fullName = 'Test User',
  String? partnerId,
}) => SessionUser(
  id: id,
  role: role,
  fullName: fullName,
  partnerId: partnerId,
);
