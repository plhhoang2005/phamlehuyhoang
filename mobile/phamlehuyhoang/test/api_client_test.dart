import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phamlehuyhoang/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'custom_api_base_url': 'https://attendance.example',
    });
  });

  test(
    'invalid server address does not replace working configuration',
    () async {
      await expectLater(
        ApiClient.setBaseUrl('not a server'),
        throwsA(isA<ApiException>()),
      );
      expect(await ApiClient.getBaseUrl(), 'https://attendance.example');
    },
  );

  test('normalizes a valid server address', () async {
    await ApiClient.setBaseUrl(' https://attendance.example/// ');
    expect(await ApiClient.getBaseUrl(), 'https://attendance.example');
  });

  test(
    'connection failure explains emulator address and server settings',
    () async {
      await ApiClient.setBaseUrl('http://10.0.2.2:5000');
      await http.runWithClient(
        () => expectLater(
          ApiClient.post('/api/auth/login', {}, requireAuth: false),
          throwsA(
            isA<ApiException>().having(
              (error) => error.message,
              'connection guidance',
              allOf(contains('10.0.2.2'), contains('Conveyor')),
            ),
          ),
        ),
        () =>
            MockClient((_) async => throw http.ClientException('unreachable')),
      );
    },
  );

  testWidgets('unresponsive login request stops waiting after 15 seconds', (
    tester,
  ) async {
    await ApiClient.getBaseUrl();
    final response = Completer<http.Response>();
    Object? error;
    var completed = false;
    final request = http.runWithClient(
      () => ApiClient.post('/api/auth/login', {}, requireAuth: false),
      () => MockClient((_) => response.future),
    );
    unawaited(
      request.then<void>(
        (_) => completed = true,
        onError: (Object failure) {
          error = failure;
          completed = true;
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 16));
    // Complete the mock even if the assertion fails, leaving no pending work.
    response.complete(http.Response('{}', 200));
    expect(completed, isTrue);
    expect(error, isA<ApiException>());
    await tester.pump();
  });

  test('preserves authentication error status and message', () async {
    await http.runWithClient(
      () => expectLater(
        ApiClient.post('/api/auth/login', {}, requireAuth: false),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'status', 401)
              .having((error) => error.message, 'message', 'Sai tài khoản'),
        ),
      ),
      () => MockClient(
        (_) async => http.Response(
          '{"message":"Sai tài khoản"}',
          401,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
  });
}
