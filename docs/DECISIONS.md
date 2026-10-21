# Quyết định kiến trúc và kỹ thuật — phamlehuyhoang

Tài liệu này ghi lại toàn bộ quyết định kỹ thuật tự chủ cho đồ án theo chỉ đạo tại `ANTIGRAVITY_MASTER_PROMPT.md` và `docs/superpowers/plans/2026-10-21-phamlehuyhoang-plan.md`.

---

## 1. Cơ sở dữ liệu và Môi trường chạy PostgreSQL
- **Quyết định:** Sử dụng phiên bản PostgreSQL 18 có sẵn trên máy (`C:\Program Files\PostgreSQL\18\bin`), khởi tạo cluster dữ liệu cục bộ riêng biệt tại `.local/pg-data` chạy cổng `54321` (tránh xung đột với cổng 5432 của dịch vụ hệ thống vốn đang có mật khẩu quản trị riêng).
- **Tên cơ sở dữ liệu:** `phamlehuyhoang`
- **Tài khoản ứng dụng:** `phamlehuyhoang_app`
- **Quản lý Schema:** Sử dụng EF Core Code-First Migrations với `Npgsql.EntityFrameworkCore.PostgreSQL`. Toàn bộ migration và script SQL được lưu trong `api/phamlehuyhoang/Migrations` và `database/`.
- **Dữ liệu thời gian:** Toàn bộ timestamp lưu chuẩn UTC trong PostgreSQL và chuyển đổi hiển thị sang múi giờ Việt Nam (`Asia/Ho_Chi_Minh` / UTC+7) trên giao diện.

---

## 2. WebAPI ASP.NET Core và Tunnel Conveyor
- **Framework:** .NET 10 (Target `net10.0`, SDK `10.0.204` có sẵn trên máy).
- **Tên project / Assembly:** `phamlehuyhoang`.
- **Cấu hình Conveyor:** WebAPI cấu hình Launch Profiles trong `Properties/launchSettings.json` hỗ trợ IIS Express / Kestrel tại cổng `5000` (HTTP) và `5001` (HTTPS) để Conveyor tự động nhận diện và mở tunnel ra thiết bị di động.
- **Client Configuration:** Mobile Flutter nhận `API_BASE_URL` thông qua `--dart-define=API_BASE_URL=https://...`, không hardcode URL Conveyor.

---

## 3. Xác thực, OTP và Phân quyền
- **Đăng ký:** Chỉ cho phép đăng ký tài khoản mới với vai trò `Student`. Vai trò `Admin` và `Lecturer` do Quản trị viên quản lý.
- **Mật khẩu:** Sử dụng `Microsoft.AspNetCore.Identity.PasswordHasher<ApplicationUser>` (PBKDF2 SHA-256 tiêu chuẩn của ASP.NET Core).
- **Luồng đăng nhập 2 lớp (Mật khẩu / Khuôn mặt + OTP):**
  1. Người dùng nhập Username/Password HOẶC nhận diện khuôn mặt thành công.
  2. API cấp một `PreAuthTicket` (chỉ dùng để xác thực OTP, không gọi được các API nghiệp vụ).
  3. API sinh mã OTP 6 chữ số ngẫu nhiên bảo mật (`RandomNumberGenerator`), hiệu lực 5 phút, tối đa 5 lần thử, thời gian chờ gửi lại 60 giây.
  4. Người dùng xác nhận OTP đúng -> API cấp JWT Access Token chính thức với vai trò tương ứng.
- **Dịch vụ Email OTP:** Cung cấp `EmailService` tích hợp `MailKit`. Hỗ trợ cấu hình SMTP thực qua biến môi trường (`SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`). Ở chế độ Development/Local test, mã OTP được ghi đồng thời ra dev log và trả kèm thông báo dev rõ ràng để không làm gián đoạn kiểm thử khi chưa nạp tài khoản SMTP thật.

---

## 4. Ba chức năng mở rộng đã chọn

### 4.1. Vị trí khi điểm danh (Mục b)
- Giảng viên cấu hình tọa độ phòng học (`Latitude`, `Longitude`) và bán kính chấp nhận (mặc định 100m).
- Client gửi tọa độ hiện tại, độ chính xác (`Accuracy`) và thời điểm lấy vị trí.
- API độc lập tính khoảng cách bằng công thức Haversine (Great-circle distance), không tin cậy cờ `isWithinRange` từ client gửi lên.
- Điều kiện hợp lệ:
  * Sai số vị trí `Accuracy <= 50m`.
  * Thời gian lấy vị trí không quá 60 giây so với hiện tại.
  * Khoảng cách thực tế `<= RadiusMeters`.

### 4.2. QR theo buổi học (Mục e)
- Giảng viên mở phiên điểm danh cho buổi học thuộc lớp mình phụ trách.
- Phiên sinh mã QR token ngẫu nhiên, có thời hạn 60 giây và có thể làm mới trong khi phiên mở.
- Khi giảng viên ấn "Đóng phiên", toàn bộ mã QR của phiên đó lập tức hết hiệu lực.
- Chống ghi trùng: Ràng buộc UNIQUE `(SessionId, StudentId)` trong cơ sở dữ liệu PostgreSQL đảm bảo mỗi sinh viên chỉ có duy nhất một kết quả điểm danh cho mỗi buổi, chống hoàn toàn race-condition hoặc bấm gửi nhiều lần.

### 4.3. Đăng nhập bằng khuôn mặt (Mục a)
- Chỉ sinh viên đã đăng nhập mới được đăng ký/cập nhật mẫu khuôn mặt của chính mình.
- Sử dụng trích xuất đặc trưng khuôn mặt (facial feature embedding vector) và đối chiếu 1:1 với mẫu đã lưu của tài khoản bằng độ tương đồng Cosine (Cosine Similarity).
- Ngưỡng đối chiếu (Threshold): `>= 0.60` theo chuẩn OpenCV SFace.
- Xử lý các tình huống biên: không phát hiện khuôn mặt, phát hiện nhiều khuôn mặt, ảnh mờ/lỗi, khuôn mặt không khớp.
- Fallback: Luôn có nút quay về đăng nhập Mật khẩu + OTP khi nhận diện hoặc camera gặp sự cố.
- Liveness: Ghi nhận trung thực giới hạn chống giả mạo ảnh/video 2D (cần camera chiều sâu/chuyển động để có liveness hoàn chỉnh).

---

## 5. Dự báo chuyên cần (Tính năng đề xuất)
- **Công thức áp dụng:**
  * `N`: Tổng số buổi chính thức của lớp.
  * `M`: Số buổi đã chốt kết quả.
  * `A`: Số buổi bị tính vắng (vắng không phép).
  * `L`: Số buổi được phép vắng tối đa.
  * Tỷ lệ hiện tại: `(M - A) / M * 100%` (khi `M > 0`). Nếu `M == 0`: hiển thị `"Chưa có dữ liệu"`.
  * Tỷ lệ nếu vắng buổi tiếp theo: `(M - A) / (M + 1) * 100%` (khi `M < N`). Nếu `M == N`: không hiển thị giả định buổi tiếp theo.
  * Số buổi còn được phép vắng: `min(N - M, max(0, L - A))`.
  * Khi `A > L`: cảnh báo `"Đã vượt giới hạn số buổi vắng cho phép"`.
- **Trường hợp kiểm thử chuẩn:** $N = 15, M = 8, A = 2, L = 3 \rightarrow$ Còn được vắng 1 buổi, tỷ lệ hiện tại 75.0%, nếu vắng tiếp tỷ lệ đạt khoảng 66.67%.

---

## 6. Tài khoản mẫu môi trường Development
- **Quản trị viên:** `admin` / `Admin@123456`
- **Giảng viên:** `giangvien1` / `GiangVien@123`
- **Sinh viên:** `sinhvien1` / `SinhVien@123`
- **Sinh viên 2:** `sinhvien2` / `SinhVien@123`
