import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phamlehuyhoang/models/class_models.dart';
import 'package:phamlehuyhoang/screens/admin/manage_subjects_screen.dart';
import 'package:phamlehuyhoang/screens/admin/manage_users_screen.dart';
import 'package:phamlehuyhoang/screens/admin/manage_classes_screen.dart';
import 'package:phamlehuyhoang/screens/lecturer/lecturer_class_sessions_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final course = CourseClassDto(
  id: 'class1',
  code: 'C1',
  subjectId: 'subject1',
  subjectCode: 'S1',
  subjectName: 'Math',
  totalSessions: 15,
  maxAbsencesAllowed: 3,
  defaultLatitude: 10,
  defaultLongitude: 106,
  defaultRadiusMeters: 100,
  enrolledCount: 0,
);

http.Response jsonResponse(Object value, [int status = 200]) => http.Response(
  jsonEncode(value),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'custom_api_base_url': 'https://attendance.example',
    }),
  );

  testWidgets(
    'subject edit persists changed name and delete requires confirmation',
    (tester) async {
      var name = 'Math';
      var deleted = false;
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            const MaterialApp(home: ManageSubjectsScreen()),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Sửa môn học'));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Tên môn học *'),
            'Physics',
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Lưu'));
          await tester.pumpAndSettle();
          expect(find.text('Physics'), findsOneWidget);
          await tester.tap(find.byTooltip('Xóa môn học'));
          await tester.pumpAndSettle();
          expect(deleted, isFalse);
          await tester.tap(find.text('Xóa').last);
          await tester.pumpAndSettle();
          expect(deleted, isTrue);
          expect(find.text('Physics'), findsNothing);
        },
        () => MockClient((request) async {
          if (request.method == 'PUT') {
            name = (jsonDecode(request.body) as Map)['name'] as String;
          }
          if (request.method == 'DELETE') deleted = true;
          return jsonResponse(
            request.method == 'GET'
                ? (deleted
                      ? []
                      : [
                          {
                            'id': 's1',
                            'code': 'M1',
                            'name': name,
                            'credits': 3,
                          },
                        ])
                : {},
          );
        }),
      );
    },
  );

  testWidgets(
    'user lock is confirmed and persisted without presenting it as deletion',
    (tester) async {
      var active = true;
      var writes = 0;
      await http.runWithClient(
        () async {
          await tester.pumpWidget(const MaterialApp(home: ManageUsersScreen()));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Khóa tài khoản'));
          await tester.pumpAndSettle();
          expect(writes, 0);
          await tester.tap(find.text('Xác nhận'));
          await tester.pumpAndSettle();
          expect(active, isFalse);
          expect(find.byTooltip('Kích hoạt tài khoản'), findsOneWidget);
        },
        () => MockClient((request) async {
          if (request.method == 'DELETE') {
            writes++;
            active = !active;
            return jsonResponse({'isActive': active});
          }
          return jsonResponse([
            {
              'id': 'u1',
              'username': 'student',
              'email': 's@example.com',
              'fullName': 'Student',
              'role': 'Student',
              'hasFaceRegistered': false,
              'isActive': active,
            },
          ]);
        }),
      );
    },
  );

  testWidgets('class exposes edit and confirmed delete actions', (
    tester,
  ) async {
    var deleted = false;
    await http.runWithClient(
      () async {
        await tester.pumpWidget(const MaterialApp(home: ManageClassesScreen()));
        await tester.pumpAndSettle();
        expect(find.byTooltip('Sửa lớp học'), findsOneWidget);
        await tester.tap(find.byTooltip('Xóa lớp học'));
        await tester.pumpAndSettle();
        expect(deleted, isFalse);
        await tester.tap(find.text('Xóa').last);
        await tester.pumpAndSettle();
        expect(deleted, isTrue);
      },
      () => MockClient((request) async {
        if (request.method == 'DELETE') {
          deleted = true;
          return jsonResponse({});
        }
        if (request.url.path == '/api/subjects') {
          return jsonResponse([
            {'id': 'subject1', 'code': 'S1', 'name': 'Math', 'credits': 3},
          ]);
        }
        if (request.url.path == '/api/users') return jsonResponse([]);
        return jsonResponse(
          deleted
              ? []
              : [
                  {
                    'id': 'class1',
                    'code': 'C1',
                    'subjectId': 'subject1',
                    'subjectCode': 'S1',
                    'subjectName': 'Math',
                    'totalSessions': 15,
                    'maxAbsencesAllowed': 3,
                    'defaultLatitude': 10,
                    'defaultLongitude': 106,
                    'defaultRadiusMeters': 100,
                    'enrolledCount': 0,
                  },
                ],
        );
      }),
    );
  });

  testWidgets(
    'empty class can open session creation with explicit coordinates',
    (tester) async {
      await http.runWithClient(() async {
        await tester.pumpWidget(
          MaterialApp(home: LecturerClassSessionsScreen(courseClass: course)),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Tạo buổi học'));
        await tester.pumpAndSettle();
        expect(find.text('Tạo buổi học'), findsWidgets);
        final latitude = tester.widget<TextFormField>(
          find.byKey(const Key('session-latitude')),
        );
        expect(latitude.controller!.text, isEmpty);
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Lưu'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lưu'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Vĩ độ'), findsWidgets);
      }, () => MockClient((_) async => jsonResponse([])));
    },
  );

  testWidgets(
    'user edit preserves lock state and keeps a rejected form editable',
    (tester) async {
      final user = <String, dynamic>{
        'id': 'u1',
        'username': 'student',
        'email': 's@example.com',
        'fullName': 'Student',
        'role': 'Student',
        'studentCode': 'SV1',
        'hasFaceRegistered': false,
        'isActive': false,
      };
      var updates = 0;
      await http.runWithClient(
        () async {
          await tester.pumpWidget(const MaterialApp(home: ManageUsersScreen()));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Sửa tài khoản'));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Họ và tên *'),
            'Updated Student',
          );
          await tester.tap(find.text('Lưu'));
          await tester.pumpAndSettle();
          expect(find.text('Email đã được sử dụng'), findsOneWidget);
          expect(
            find.widgetWithText(TextFormField, 'Updated Student'),
            findsOneWidget,
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Email *'),
            'new@example.com',
          );
          await tester.tap(find.text('Lưu'));
          await tester.pumpAndSettle();
          expect(user['email'], 'new@example.com');
          expect(user['isActive'], isFalse);
          expect(user['role'], 'Student');
          expect(find.text('Updated Student'), findsOneWidget);
          expect(find.byTooltip('Kích hoạt tài khoản'), findsOneWidget);
        },
        () => MockClient((request) async {
          if (request.method == 'PUT') {
            updates++;
            if (updates == 1) {
              return jsonResponse({'message': 'Email đã được sử dụng'}, 409);
            }
            user.addAll(jsonDecode(request.body) as Map<String, dynamic>);
            return jsonResponse({});
          }
          return jsonResponse([user]);
        }),
      );
    },
  );

  testWidgets('class edit persists code policy and explicit GPS coordinates', (
    tester,
  ) async {
    final stored = <String, dynamic>{
      'id': 'class1',
      'code': 'C1',
      'subjectId': 'subject1',
      'subjectCode': 'S1',
      'subjectName': 'Math',
      'totalSessions': 15,
      'maxAbsencesAllowed': 3,
      'defaultLatitude': 10,
      'defaultLongitude': 106,
      'defaultRadiusMeters': 100,
      'enrolledCount': 0,
    };
    await http.runWithClient(
      () async {
        await tester.pumpWidget(const MaterialApp(home: ManageClassesScreen()));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Sửa lớp học'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Mã lớp *'),
          'C2',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Tổng số buổi (N) *'),
          '20',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Tối đa vắng (L) *'),
          '4',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Vĩ độ mặc định *'),
          '10.8',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Kinh độ mặc định *'),
          '106.6',
        );
        await tester.tap(find.text('Lưu'));
        await tester.pumpAndSettle();
        expect(stored['code'], 'C2');
        expect(stored['subjectId'], 'subject1');
        expect(stored['totalSessions'], 20);
        expect(stored['maxAbsencesAllowed'], 4);
        expect(stored['defaultLatitude'], 10.8);
        expect(stored['defaultLongitude'], 106.6);
        expect(stored['lecturerId'], isNull);
        expect(find.text('C2 — Math'), findsOneWidget);
      },
      () => MockClient((request) async {
        if (request.method == 'PUT') {
          stored.addAll(jsonDecode(request.body) as Map<String, dynamic>);
          return jsonResponse({});
        }
        if (request.url.path == '/api/subjects') {
          return jsonResponse([
            {'id': 'subject1', 'code': 'S1', 'name': 'Math', 'credits': 3},
          ]);
        }
        if (request.url.path == '/api/users') return jsonResponse([]);
        return jsonResponse([stored]);
      }),
    );
  });

  testWidgets('lecturer creates a session and sees persisted server data', (
    tester,
  ) async {
    Map<String, dynamic>? created;
    await http.runWithClient(
      () async {
        await tester.pumpWidget(
          MaterialApp(home: LecturerClassSessionsScreen(courseClass: course)),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Tạo buổi học'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Tiêu đề *'),
          'Introduction',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Phòng học *'),
          'A101',
        );
        await tester.enterText(
          find.byKey(const Key('session-latitude')),
          '10.75',
        );
        await tester.enterText(
          find.byKey(const Key('session-longitude')),
          '106.65',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Lưu'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lưu'));
        await tester.pumpAndSettle();
        expect(created?['courseClassId'], 'class1');
        expect(created?['sessionNumber'], 1);
        expect(created?['latitude'], 10.75);
        expect(created?['longitude'], 106.65);
        expect(created?['radiusMeters'], 100);
        expect(
          DateTime.parse(created!['endTimeUtc'] as String)
              .isAfter(DateTime.parse(created!['startTimeUtc'] as String)),
          isTrue,
        );
        expect(find.text('Buổi 1: Introduction'), findsOneWidget);
      },
      () => MockClient((request) async {
        if (request.method == 'POST') {
          created = jsonDecode(request.body) as Map<String, dynamic>;
          return jsonResponse({
            'id': 'session1',
            ...created!,
            'isFinalized': false,
            'isCancelled': false,
            'hasActiveQrSession': false,
          }, 201);
        }
        return jsonResponse(
          created == null
              ? []
              : [
                  {
                    'id': 'session1',
                    ...created!,
                    'isFinalized': false,
                    'isCancelled': false,
                    'hasActiveQrSession': false,
                  },
                ],
        );
      }),
    );
  });

  testWidgets(
    'lecturer edits session and confirmed cancellation removes QR action',
    (tester) async {
      final stored = <String, dynamic>{
        'id': 'session1',
        'courseClassId': 'class1',
        'sessionNumber': 1,
        'title': 'Original',
        'startTimeUtc': '2026-10-21T02:00:00Z',
        'endTimeUtc': '2026-10-21T03:30:00Z',
        'roomName': 'A101',
        'latitude': 10.75,
        'longitude': 106.65,
        'radiusMeters': 100,
        'isCancelled': false,
        'isFinalized': false,
        'hasActiveQrSession': false,
      };
      var updates = 0;
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            MaterialApp(home: LecturerClassSessionsScreen(courseClass: course)),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Sửa buổi học'));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Tiêu đề *'),
            'Updated',
          );
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.text('Lưu'),
            250,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Lưu'));
          await tester.pumpAndSettle();
          expect(find.text('Buổi 1: Updated'), findsOneWidget);
          expect(stored['startTimeUtc'], '2026-10-21T02:00:00.000Z');
          await tester.tap(find.byTooltip('Hủy buổi học'));
          await tester.pumpAndSettle();
          expect(updates, 1);
          await tester.tap(find.text('Xác nhận'));
          await tester.pumpAndSettle();
          expect(updates, 2);
          expect(stored['isCancelled'], isTrue);
          expect(find.text('ĐÃ HỦY'), findsOneWidget);
          expect(find.byTooltip('Mở QR điểm danh'), findsNothing);
        },
        () => MockClient((request) async {
          if (request.method == 'PUT') {
            updates++;
            stored.addAll(jsonDecode(request.body) as Map<String, dynamic>);
            return jsonResponse({});
          }
          return jsonResponse([stored]);
        }),
      );
    },
  );

  testWidgets('load failures are shown rather than reported as empty data', (
    tester,
  ) async {
    await http.runWithClient(
      () async {
        await tester.pumpWidget(
          const MaterialApp(home: ManageSubjectsScreen()),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Máy chủ lỗi'), findsOneWidget);
        expect(find.text('Thử lại'), findsOneWidget);
      },
      () => MockClient(
        (_) async => jsonResponse({'message': 'Máy chủ lỗi'}, 500),
      ),
    );
  });
}
