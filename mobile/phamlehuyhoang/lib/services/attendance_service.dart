import '../models/attendance_models.dart';
import '../models/class_models.dart';
import 'api_client.dart';

class AttendanceService {
  static Future<List<CourseClassDto>> getClasses() async {
    final res = await ApiClient.get('/api/courseclasses');
    return (res as List).map((c) => CourseClassDto.fromJson(c)).toList();
  }

  static Future<List<ClassSessionDto>> getSessionsForClass(String courseClassId) async {
    final res = await ApiClient.get('/api/classsessions/class/$courseClassId');
    return (res as List).map((s) => ClassSessionDto.fromJson(s)).toList();
  }

  static Future<QrSessionDto> openQrSession(String classSessionId, {int lifetimeSeconds = 60}) async {
    final res = await ApiClient.post('/api/attendance/qr/open', {
      'classSessionId': classSessionId,
      'lifetimeSeconds': lifetimeSeconds,
    });
    return QrSessionDto.fromJson(res);
  }

  static Future<void> closeQrSession(String classSessionId) async {
    await ApiClient.post('/api/attendance/qr/close/$classSessionId', {});
  }

  static Future<CheckInResultDto> checkIn({
    required String qrToken,
    required double latitude,
    required double longitude,
    required double accuracy,
  }) async {
    final res = await ApiClient.post('/api/attendance/check-in', {
      'qrToken': qrToken,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'clientTimestampUtc': DateTime.now().toUtc().toIso8601String(),
    });
    return CheckInResultDto.fromJson(res);
  }

  static Future<List<AttendanceRecordDto>> getSessionAttendance(String sessionId) async {
    final res = await ApiClient.get('/api/attendance/session/$sessionId/records');
    return (res as List).map((r) => AttendanceRecordDto.fromJson(r)).toList();
  }

  static Future<void> finalizeSession(String sessionId) async {
    await ApiClient.post('/api/classsessions/$sessionId/finalize', {});
  }

  static Future<AttendanceRecordDto> adjustAttendance({
    required String recordId,
    required AttendanceStatus newStatus,
    required String reason,
  }) async {
    final res = await ApiClient.post('/api/attendance/adjust', {
      'attendanceRecordId': recordId,
      'newStatus': newStatus.value,
      'reason': reason,
    });
    return AttendanceRecordDto.fromJson(res);
  }

  static Future<AttendanceForecastDto> getForecast(String courseClassId) async {
    final res = await ApiClient.get('/api/attendance/forecast/class/$courseClassId');
    return AttendanceForecastDto.fromJson(res);
  }

  static Future<List<AttendanceForecastDto>> getMyForecasts() async {
    final res = await ApiClient.get('/api/attendance/forecast/my');
    return (res as List).map((f) => AttendanceForecastDto.fromJson(f)).toList();
  }
}
