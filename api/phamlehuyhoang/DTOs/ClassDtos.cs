using System.ComponentModel.DataAnnotations;

namespace phamlehuyhoang.DTOs;

public record SubjectDto(
    Guid Id,
    string Code,
    string Name,
    int Credits
);

public record CreateSubjectRequest(
    [Required] string Code,
    [Required] string Name,
    int Credits
);

public record CourseClassDto(
    Guid Id,
    string Code,
    Guid SubjectId,
    string SubjectCode,
    string SubjectName,
    Guid? LecturerId,
    string? LecturerName,
    int TotalSessions,
    int MaxAbsencesAllowed,
    double DefaultLatitude,
    double DefaultLongitude,
    double DefaultRadiusMeters,
    int EnrolledCount
);

public record CreateCourseClassRequest(
    [Required] string Code,
    [Required] Guid SubjectId,
    Guid? LecturerId,
    int TotalSessions = 15,
    int MaxAbsencesAllowed = 3,
    double DefaultLatitude = 10.762622,
    double DefaultLongitude = 106.682333,
    double DefaultRadiusMeters = 100.0
);

public record UpdateCourseClassRequest(
    Guid? LecturerId,
    int TotalSessions,
    int MaxAbsencesAllowed,
    double DefaultLatitude,
    double DefaultLongitude,
    double DefaultRadiusMeters,
    string? Code = null,
    Guid? SubjectId = null
);

public record EnrollmentDto(
    Guid Id,
    Guid StudentId,
    string StudentName,
    string? StudentCode,
    string StudentEmail,
    DateTime EnrolledAtUtc
);

public record EnrollStudentRequest(
    [Required] Guid StudentId
);

public record ClassSessionDto(
    Guid Id,
    Guid CourseClassId,
    int SessionNumber,
    string Title,
    DateTime StartTimeUtc,
    DateTime EndTimeUtc,
    string RoomName,
    double Latitude,
    double Longitude,
    double RadiusMeters,
    bool IsCancelled,
    bool IsFinalized,
    DateTime? FinalizedAtUtc,
    bool HasActiveQrSession
);

public record CreateClassSessionRequest(
    [Required] Guid CourseClassId,
    int SessionNumber,
    [Required] string Title,
    DateTime StartTimeUtc,
    DateTime EndTimeUtc,
    string RoomName,
    double Latitude,
    double Longitude,
    double RadiusMeters
);

public record UpdateClassSessionRequest(
    string Title,
    DateTime StartTimeUtc,
    DateTime EndTimeUtc,
    string RoomName,
    double Latitude,
    double Longitude,
    double RadiusMeters,
    bool IsCancelled,
    int? SessionNumber = null
);
