import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phamlehuyhoang/services/attendance_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'check-in transmits GPS capture time rather than network send time',
    () async {
      SharedPreferences.setMockInitialValues({
        'custom_api_base_url': 'https://attendance.example',
      });
      Map<String, dynamic>? sent;
      await http.runWithClient(
        () async {
          await Function.apply(AttendanceService.checkIn, [], {
            #qrToken: 'token',
            #latitude: 10.0,
            #longitude: 106.0,
            #accuracy: 5.0,
            #capturedAt: DateTime.parse('2026-10-21T09:00:00+07:00'),
          });
        },
        () => MockClient((request) async {
          sent = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            '{"success":true,"message":"OK","status":1}',
            200,
          );
        }),
      );
      expect(sent?['clientTimestampUtc'], '2026-10-21T02:00:00.000Z');
    },
  );
}
