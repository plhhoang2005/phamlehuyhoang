import 'package:flutter_test/flutter_test.dart';
import 'package:phamlehuyhoang/main.dart';
import 'package:phamlehuyhoang/models/attendance_models.dart';
import 'package:phamlehuyhoang/models/auth_models.dart';

void main() {
  testWidgets('App renders SplashScreen with phamlehuyhoang title', (WidgetTester tester) async {
    await tester.pumpWidget(const AttendanceApp());
    expect(find.text('phamlehuyhoang'), findsOneWidget);
    expect(find.text('Điểm danh QR • Vị trí • Khuôn mặt • Dự báo'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  test('AttendanceForecastDto json parsing test', () {
    final json = {
      'courseClassId': '11111111-1111-1111-1111-111111111111',
      'classCode': '261_INT3101_01',
      'subjectName': 'Lập trình di động',
      'n': 15,
      'l': 3,
      'm': 8,
      'a': 2,
      'currentPercentage': 75.0,
      'nextAbsentPercentage': 66.67,
      'remainingAbsencesAllowed': 1,
      'isLimitExceeded': false,
      'statusDescription': 'Chuyên cần ổn định',
      'sessionRecords': []
    };

    final dto = AttendanceForecastDto.fromJson(json);

    expect(dto.n, 15);
    expect(dto.l, 3);
    expect(dto.m, 8);
    expect(dto.a, 2);
    expect(dto.currentPercentage, 75.0);
    expect(dto.nextAbsentPercentage, 66.67);
    expect(dto.remainingAbsencesAllowed, 1);
    expect(dto.isLimitExceeded, false);
  });

  test('UserDto json parsing test', () {
    final json = {
      'id': '22222222-2222-2222-2222-222222222222',
      'username': 'sinhvien1',
      'email': 'sinhvien1@phamlehuyhoang.edu.vn',
      'fullName': 'Phạm Lê Huy Hoàng',
      'studentCode': '23010001',
      'role': 'Student',
      'hasFaceRegistered': true
    };

    final user = UserDto.fromJson(json);

    expect(user.username, 'sinhvien1');
    expect(user.role, 'Student');
    expect(user.hasFaceRegistered, true);
  });
}
