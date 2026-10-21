import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phamlehuyhoang/models/auth_models.dart';
import 'package:phamlehuyhoang/screens/auth/login_screen.dart';
import 'package:phamlehuyhoang/screens/auth/otp_verification_screen.dart';
import 'package:phamlehuyhoang/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'custom_api_base_url': 'https://attendance.example',
    }),
  );

  testWidgets('legacy developer OTP hints are ignored and input starts empty', (
    tester,
  ) async {
    final response = PreAuthResponse.fromJson({
      'ticket': 'activation-ticket',
      'message': 'Kiểm tra email của bạn.',
      'purpose': 'EmailActivation',
      'devOtpCode': '123456',
    });
    await tester.pumpWidget(
      MaterialApp(
        home: OtpVerificationScreen(
          ticket: response.ticket,
          message: response.message,
          username: 'student',
          isActivation: response.isActivation,
        ),
      ),
    );
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      isEmpty,
    );
    expect(find.textContaining('Dev/Test'), findsNothing);
    expect(find.text('123456'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'activation calls verify-email and returns to login without storing a token',
    (tester) async {
      String? calledPath;
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            const MaterialApp(
              home: OtpVerificationScreen(
                ticket: 'activation-ticket',
                message: 'Kiểm tra email.',
                username: 'student',
                isActivation: true,
              ),
            ),
          );
          await tester.enterText(find.byType(TextField), '123456');
          await tester.tap(
            find.widgetWithText(ElevatedButton, 'Kích hoạt tài khoản'),
          );
          await tester.pumpAndSettle();
          expect(calledPath, '/api/auth/verify-email');
          expect(find.byType(LoginScreen), findsOneWidget);
          expect(
            (await SharedPreferences.getInstance()).getString('jwt_token'),
            isNull,
          );
        },
        () => MockClient((request) async {
          calledPath = request.url.path;
          expect(jsonDecode(request.body)['code'], '123456');
          return http.Response(
            '{"message":"Đã kích hoạt."}',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  test(
    'registration returns activation challenge instead of a logged-in user',
    () async {
      await http.runWithClient(
        () async {
          final result = await AuthService.register(
            username: 'student',
            email: 'student@example.com',
            fullName: 'Student',
            password: 'StrongPass123!',
          );
          expect(result.isActivation, isTrue);
          expect(
            (await SharedPreferences.getInstance()).getString('jwt_token'),
            isNull,
          );
        },
        () => MockClient((request) async {
          expect(request.url.path, '/api/auth/register');
          return http.Response(
            '{"ticket":"registration-ticket","message":"Kiểm tra email.","purpose":"EmailActivation","expiresInSeconds":300}',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
    },
  );
}
