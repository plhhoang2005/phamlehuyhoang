namespace phamlehuyhoang.Enums;

public enum AttendanceStatus
{
    Present = 1,   // Có mặt
    Late = 2,      // Đi muộn (vẫn tính tham dự)
    Excused = 3,   // Vắng có phép (không tăng số buổi bị tính vắng A)
    Absent = 4     // Vắng không phép (tăng số buổi bị tính vắng A)
}
