class SubjectDto {
  final String id;
  final String code;
  final String name;
  final int credits;

  SubjectDto({
    required this.id,
    required this.code,
    required this.name,
    required this.credits,
  });

  factory SubjectDto.fromJson(Map<String, dynamic> json) {
    return SubjectDto(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      credits: json['credits'] ?? 3,
    );
  }
}

class CourseClassDto {
  final String id;
  final String code;
  final String subjectId;
  final String subjectCode;
  final String subjectName;
  final String? lecturerId;
  final String? lecturerName;
  final int totalSessions;
  final int maxAbsencesAllowed;
  final double defaultLatitude;
  final double defaultLongitude;
  final double defaultRadiusMeters;
  final int enrolledCount;

  CourseClassDto({
    required this.id,
    required this.code,
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
    this.lecturerId,
    this.lecturerName,
    required this.totalSessions,
    required this.maxAbsencesAllowed,
    required this.defaultLatitude,
    required this.defaultLongitude,
    required this.defaultRadiusMeters,
    required this.enrolledCount,
  });

  factory CourseClassDto.fromJson(Map<String, dynamic> json) {
    return CourseClassDto(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      subjectId: json['subjectId'] ?? '',
      subjectCode: json['subjectCode'] ?? '',
      subjectName: json['subjectName'] ?? '',
      lecturerId: json['lecturerId'],
      lecturerName: json['lecturerName'],
      totalSessions: json['totalSessions'] ?? 15,
      maxAbsencesAllowed: json['maxAbsencesAllowed'] ?? 3,
      defaultLatitude: (json['defaultLatitude'] as num?)?.toDouble() ?? 10.762622,
      defaultLongitude: (json['defaultLongitude'] as num?)?.toDouble() ?? 106.682333,
      defaultRadiusMeters: (json['defaultRadiusMeters'] as num?)?.toDouble() ?? 100.0,
      enrolledCount: json['enrolledCount'] ?? 0,
    );
  }
}

class ClassSessionDto {
  final String id;
  final String courseClassId;
  final int sessionNumber;
  final String title;
  final DateTime startTimeUtc;
  final DateTime endTimeUtc;
  final String roomName;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final bool isCancelled;
  final bool isFinalized;
  final DateTime? finalizedAtUtc;
  final bool hasActiveQrSession;

  ClassSessionDto({
    required this.id,
    required this.courseClassId,
    required this.sessionNumber,
    required this.title,
    required this.startTimeUtc,
    required this.endTimeUtc,
    required this.roomName,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.isCancelled,
    required this.isFinalized,
    this.finalizedAtUtc,
    required this.hasActiveQrSession,
  });

  factory ClassSessionDto.fromJson(Map<String, dynamic> json) {
    return ClassSessionDto(
      id: json['id'] ?? '',
      courseClassId: json['courseClassId'] ?? '',
      sessionNumber: json['sessionNumber'] ?? 1,
      title: json['title'] ?? '',
      startTimeUtc: DateTime.tryParse(json['startTimeUtc'] ?? '') ?? DateTime.now(),
      endTimeUtc: DateTime.tryParse(json['endTimeUtc'] ?? '') ?? DateTime.now(),
      roomName: json['roomName'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 100.0,
      isCancelled: json['isCancelled'] ?? false,
      isFinalized: json['isFinalized'] ?? false,
      finalizedAtUtc: json['finalizedAtUtc'] != null ? DateTime.tryParse(json['finalizedAtUtc']) : null,
      hasActiveQrSession: json['hasActiveQrSession'] ?? false,
    );
  }
}

class EnrollmentDto {
  final String id;
  final String studentId;
  final String studentName;
  final String? studentCode;
  final String studentEmail;
  final DateTime enrolledAtUtc;

  EnrollmentDto({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.studentCode,
    required this.studentEmail,
    required this.enrolledAtUtc,
  });

  factory EnrollmentDto.fromJson(Map<String, dynamic> json) {
    return EnrollmentDto(
      id: json['id'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      studentCode: json['studentCode'],
      studentEmail: json['studentEmail'] ?? '',
      enrolledAtUtc: DateTime.tryParse(json['enrolledAtUtc'] ?? '') ?? DateTime.now(),
    );
  }
}
