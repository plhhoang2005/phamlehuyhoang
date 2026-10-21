enum AttendanceStatus {
  present(1, 'Có mặt'),
  late(2, 'Đi muộn'),
  excused(3, 'Có phép'),
  absent(4, 'Vắng mặt');

  final int value;
  final String label;
  const AttendanceStatus(this.value, this.label);

  static AttendanceStatus fromValue(int val) {
    return AttendanceStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => AttendanceStatus.present,
    );
  }
}

class QrSessionDto {
  final String id;
  final String classSessionId;
  final String qrToken;
  final DateTime expiresAtUtc;
  final bool isOpen;
  final int remainingSeconds;

  QrSessionDto({
    required this.id,
    required this.classSessionId,
    required this.qrToken,
    required this.expiresAtUtc,
    required this.isOpen,
    required this.remainingSeconds,
  });

  factory QrSessionDto.fromJson(Map<String, dynamic> json) {
    return QrSessionDto(
      id: json['id'] ?? '',
      classSessionId: json['classSessionId'] ?? '',
      qrToken: json['qrToken'] ?? '',
      expiresAtUtc: DateTime.tryParse(json['expiresAtUtc'] ?? '') ?? DateTime.now(),
      isOpen: json['isOpen'] ?? false,
      remainingSeconds: json['remainingSeconds'] ?? 0,
    );
  }
}

class CheckInResultDto {
  final bool success;
  final String message;
  final AttendanceStatus? status;
  final double? distanceMeters;
  final DateTime? checkedInAtUtc;

  CheckInResultDto({
    required this.success,
    required this.message,
    this.status,
    this.distanceMeters,
    this.checkedInAtUtc,
  });

  factory CheckInResultDto.fromJson(Map<String, dynamic> json) {
    return CheckInResultDto(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      status: json['status'] != null ? AttendanceStatus.fromValue(json['status']) : null,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
      checkedInAtUtc: json['checkedInAtUtc'] != null ? DateTime.tryParse(json['checkedInAtUtc']) : null,
    );
  }
}

class AttendanceRecordDto {
  final String id;
  final String classSessionId;
  final String studentId;
  final String studentName;
  final String? studentCode;
  final AttendanceStatus status;
  final DateTime? checkedInAtUtc;
  final String checkInMethod;
  final double? distanceMeters;
  final double? accuracyMeters;
  final String? note;

  AttendanceRecordDto({
    required this.id,
    required this.classSessionId,
    required this.studentId,
    required this.studentName,
    this.studentCode,
    required this.status,
    this.checkedInAtUtc,
    required this.checkInMethod,
    this.distanceMeters,
    this.accuracyMeters,
    this.note,
  });

  factory AttendanceRecordDto.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordDto(
      id: json['id'] ?? '',
      classSessionId: json['classSessionId'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      studentCode: json['studentCode'],
      status: AttendanceStatus.fromValue(json['status'] ?? 1),
      checkedInAtUtc: json['checkedInAtUtc'] != null ? DateTime.tryParse(json['checkedInAtUtc']) : null,
      checkInMethod: json['checkInMethod'] ?? '',
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
      accuracyMeters: (json['accuracyMeters'] as num?)?.toDouble(),
      note: json['note'],
    );
  }
}

class AttendanceForecastDto {
  final String courseClassId;
  final String classCode;
  final String subjectName;
  final int n;
  final int l;
  final int m;
  final int a;
  final double? currentPercentage;
  final double? nextAbsentPercentage;
  final int remainingAbsencesAllowed;
  final bool isLimitExceeded;
  final String statusDescription;
  final List<AttendanceRecordDto> sessionRecords;

  AttendanceForecastDto({
    required this.courseClassId,
    required this.classCode,
    required this.subjectName,
    required this.n,
    required this.l,
    required this.m,
    required this.a,
    this.currentPercentage,
    this.nextAbsentPercentage,
    required this.remainingAbsencesAllowed,
    required this.isLimitExceeded,
    required this.statusDescription,
    required this.sessionRecords,
  });

  factory AttendanceForecastDto.fromJson(Map<String, dynamic> json) {
    var rawRecords = json['sessionRecords'] as List? ?? [];
    return AttendanceForecastDto(
      courseClassId: json['courseClassId'] ?? '',
      classCode: json['classCode'] ?? '',
      subjectName: json['subjectName'] ?? '',
      n: json['n'] ?? 15,
      l: json['l'] ?? 3,
      m: json['m'] ?? 0,
      a: json['a'] ?? 0,
      currentPercentage: (json['currentPercentage'] as num?)?.toDouble(),
      nextAbsentPercentage: (json['nextAbsentPercentage'] as num?)?.toDouble(),
      remainingAbsencesAllowed: json['remainingAbsencesAllowed'] ?? 0,
      isLimitExceeded: json['isLimitExceeded'] ?? false,
      statusDescription: json['statusDescription'] ?? '',
      sessionRecords: rawRecords.map((r) => AttendanceRecordDto.fromJson(r)).toList(),
    );
  }
}
