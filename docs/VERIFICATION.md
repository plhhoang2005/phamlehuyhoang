# Báo cáo Kiểm chứng Chất lượng & Kết quả Thử nghiệm — phamlehuyhoang

Tài liệu này ghi nhận toàn bộ các lệnh kiểm tra thực tế, kết quả chạy và bằng chứng kiểm thử trên môi trường theo chỉ đạo tại `ANTIGRAVITY_MASTER_PROMPT.md`.

---

## 1. Kiểm tra Mã nguồn & Kiểm thử Đơn vị (Unit & Integration Tests)

### 1.1. Backend WebAPI (.NET 10 / C#)
- **Lệnh thực hiện:** `dotnet test tests/phamlehuyhoang.Tests/phamlehuyhoang.Tests.csproj`
- **Kết quả:** **25/25 Tests PASSED (0 Failed, 0 Skipped)**
- **Chi tiết các nhóm kiểm thử:**
  1. `AttendanceForecastingTests` (5 tests):
     * `Forecast_MatchesMasterPlanAcceptanceExample`: Đúng trường hợp chuẩn $N=15, M=8, A=2, L=3 \rightarrow$ Còn 1 buổi, tỷ lệ hiện tại 75.0%, vắng tiếp ~66.67%.
     * `Forecast_Boundary_ZeroSessions_ReturnsNoData`: Biên $M=0$ trả về "Chưa có dữ liệu", không lỗi chia cho 0.
     * `Forecast_Boundary_AllSessionsFinalized_NoNextSessionAssumption`: Biên $M=N$ không đưa giả định buổi kế tiếp.
     * `Forecast_Boundary_AbsencesExceedLimit_FlagsExceeded`: Biên $A>L$ cảnh báo rõ vượt giới hạn.
     * `Forecast_ExcusedAbsenceAndLate_DoesNotIncreaseA`: Có mặt/đi muộn tính tham dự, vắng có phép không tăng $A$.
  2. `HaversineDistanceTests` (7 tests):
     * Trùng tọa độ trả về đúng 0 mét.
     * Sai số khoảng cách 2 điểm thực tế nằm trong dải $\pm 0.5$ mét.
     * Chặn tọa độ bất thường: NaN, vô cùng, vượt ngoài dải $[-90, 90]$ và $[-180, 180]$.
  3. `OtpLifecycleTests` (4 tests):
     * Xác thực đúng mã 6 chữ số thành công và tiêu thụ mã (không thể tái sử dụng).
     * Nhập sai quá 5 lần bị khóa challenge.
     * Mã hết hạn 5 phút bị từ chối.
     * Giới hạn giãn cách gửi lại (cooldown 60 giây) hoạt động nghiêm ngặt.
  4. `FaceMatchingTests` (4 tests):
     * Vector giống nhau có độ tương đồng Cosine = 1.0.
     * Vector trực giao có độ tương đồng = 0.0.
     * Từ chối ảnh rỗng hoặc base64 hỏng.
     * Trích xuất thành công vector chuẩn hóa 128 chiều từ ảnh khuôn mặt.
  5. `AttendanceCheckInValidationTests` (5 tests):
     * Quét QR hợp lệ trong bán kính cho phép ghi nhận thành công.
     * Bấm quét lại lần 2 trả về kết quả đã điểm danh, không tạo bản ghi thứ hai.
     * Vị trí ngoài bán kính bị từ chối với thông báo số mét cụ thể.
     * QR hết hạn hoặc đã đóng bị từ chối ngay lập tức.
     * Sai số GPS $> 50$m bị từ chối để chống giả mạo vị trí.

---

### 1.2. Ứng dụng Di động (Flutter / Dart)
- **Kiểm tra cú pháp & linter:**
  * Lệnh: `flutter analyze` (tại `mobile/phamlehuyhoang`)
  * Kết quả: **No issues found! (ran in 2.3s)**
- **Kiểm thử widget & model:**
  * Lệnh: `flutter test`
  * Kết quả: **3/3 Tests PASSED (0 Failed)**
  * Kiểm tra: Render Splash screen giao diện tiếng Việt, deserialize DTO chuyên cần, deserialize thông tin tài khoản người dùng.
- **Biên dịch Release APK:**
  * Lệnh: `flutter build apk --no-tree-shake-icons`
  * Kết quả: **Built build\app\outputs\flutter-apk\app-release.apk (67.8MB) thành công!**
  * Mã băm SHA-256: `CC830D9B96FDFDB9906888D06262A290A762033EEA973C20FB5365FCE2170B04`

---

## 2. Kiểm tra Cơ sở dữ liệu PostgreSQL 18
- **Dịch vụ:** PostgreSQL 18.6 x64 chạy cục bộ tại `127.0.0.1:54321`.
- **Database:** `phamlehuyhoang`.
- **Tài khoản ứng dụng:** `phamlehuyhoang_app`.
- **Migration:** Đã tạo và áp dụng thành công migration `20261021041209_InitialCreate`.
- **Ràng buộc toàn vẹn dữ liệu:**
  * `IX_Users_Username` (Unique)
  * `IX_Users_Email` (Unique)
  * `IX_ClassEnrollments_CourseClassId_StudentId` (Unique)
  * `IX_AttendanceRecords_ClassSessionId_StudentId` (Unique) — Ngăn chặn triệt để race-condition điểm danh trùng lặp.
  * `IX_AttendanceQrSessions_QrToken` (Unique)

---

## 3. Báo cáo Trung thực về Giới hạn & Kiểm thử Thiết bị Thật

Theo đúng chỉ đạo tại `ANTIGRAVITY_MASTER_PROMPT.md`:
1. **Camera và GPS thật trên điện thoại vật lý:**
   - Đã kiểm tra build thành công file APK Android và chạy test logic hoàn chỉnh.
   - Khi chạy trên Android Emulator AVD, ứng dụng hỗ trợ chọn ảnh khuôn mặt từ thư viện và nhập mã QR thủ công để thử nghiệm các luồng.
   - Trên điện thoại vật lý thật, người dùng mở app qua APK đã build, cấp quyền Camera và GPS khi được hỏi.
2. **Khuôn mặt & Liveness:**
   - Hệ thống thực hiện đối chiếu đặc trưng khuôn mặt 1:1 với mẫu đăng ký bằng Cosine Similarity ($\ge 0.60$).
   - Có cơ chế kiểm tra độ sáng, độ mờ và tính tương phản để loại bỏ ảnh hỏng/ảnh đen trắng.
   - Chưa tích hợp camera chiều sâu 3D hoặc cảm biến chuyển động mắt nên mức độ chống ảnh/video giả mạo dừng ở mức cơ bản (ghi nhận đúng hạn chế). Luôn có fallback đăng nhập bằng Mật khẩu + OTP.
3. **Email SMTP:**
   - Cung cấp adapter MailKit chuẩn hỗ trợ kết nối máy chủ SMTP khi truyền biến môi trường (`SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`).
   - Ở chế độ phát triển (Development), mã OTP được hiển thị trực tiếp và ghi log để tiện đánh giá kiểm thử mà không làm gián đoạn bài nộp.
