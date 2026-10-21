# phamlehuyhoang — Ứng dụng Di động Điểm danh Sinh viên

> **Đồ án cá nhân môn Lập trình thiết bị di động**  
> **Sinh viên thực hiện:** Phạm Lê Huy Hoàng  
> **Repository:** https://github.com/plhhoang2005/phamlehuyhoang

---

## 1. Giới thiệu & Công nghệ sử dụng

Ứng dụng điểm danh sinh viên toàn diện hỗ trợ 3 vai trò (**Quản trị viên**, **Giảng viên**, **Sinh viên**) với quy trình nghiệp vụ xuyên suốt:

- **Mobile Client:** Flutter / Dart (Tối ưu hóa cho Android, Material 3, Giao diện 100% tiếng Việt).
- **Backend WebAPI:** ASP.NET Core WebAPI (.NET 10, chạy bằng Kestrel / Visual Studio).
- **Cơ sở dữ liệu:** PostgreSQL 18 thông qua Entity Framework Core 10 và Npgsql.
- **Tunnel truy cập từ xa:** Hỗ trợ Microsoft Visual Studio / Conveyor Cloud để thiết bị di động truy cập trực tiếp API qua mạng Internet/4G.
- **Cloudflare Quick Tunnel:** Chạy `scripts/Start-Cloudflare.ps1` để mở URL HTTPS tạm, dùng được trên điện thoại và máy người kiểm tra. Xem [hướng dẫn Cloudflare](docs/CLOUDFLARE_QUICK_TUNNEL.md).
- **Bảo mật & Xác thực:** Mật khẩu băm PBKDF2 bằng ASP.NET Identity, OTP email bắt buộc, JWT có phiên bản quyền; kiểm soát theo vai trò và lớp học.

---

## 2. Ba chức năng mở rộng đã chọn & Tính năng mới đề xuất

### 2.1. Đăng nhập bằng khuôn mặt (Mục a)
- Thu nhận ảnh mặt qua Camera / Thư viện.
- YuNet phát hiện một khuôn mặt; SFace trích xuất vector 128 chiều chuẩn hóa L2.
- Đối chiếu 1:1 bằng cosine, ngưỡng mặc định 0.363. Cài mô hình bằng `scripts/Initialize-FaceModels.ps1`; xem [thiết lập khuôn mặt](docs/FACE_SETUP.md). Mẫu khuôn mặt cũ cần đăng ký lại. Chưa có liveness.
- Kết hợp OTP 2 lớp trước khi cấp phiên đăng nhập; có fallback sang đăng nhập mật khẩu khi camera/nhận diện gặp sự cố.

### 2.2. Vị trí khi điểm danh (Mục b)
- Giảng viên cấu hình tọa độ phòng học và bán kính cho phép (mặc định 100 mét).
- Sinh viên gửi tọa độ GPS hiện tại và độ chính xác khi quét điểm danh.
- Máy chủ độc lập tính khoảng cách bằng công thức lượng giác hình cầu Haversine; từ chối khi sai số GPS $> 50$m hoặc khoảng cách vượt bán kính.

### 2.3. QR theo buổi học (Mục e)
- Giảng viên mở phiên điểm danh cho buổi học thuộc lớp được phân công.
- Sinh mã QR ngẫu nhiên với thời hạn 60 giây; giảng viên dùng nút làm mới để cấp mã mới.
- Đóng phiên lập tức vô hiệu hóa mã QR.
- Ràng buộc cơ sở dữ liệu UNIQUE `(ClassSessionId, StudentId)` chống triệt để việc điểm danh trùng lặp hoặc race-condition.

### 2.4. Tính năng mới đề xuất: Theo dõi số buổi vắng & Dự báo chuyên cần
- Tính toán chính xác theo công thức:
  * $N$: Tổng số buổi chính thức của lớp.
  * $M$: Số buổi đã chốt kết quả.
  * $A$: Số buổi bị tính vắng kỷ luật (vắng không phép).
  * $L$: Số buổi được phép vắng tối đa.
  * Tỷ lệ hiện tại: $(M - A) / M \times 100\%$.
  * Tỷ lệ nếu vắng buổi tiếp theo: $(M - A) / (M + 1) \times 100\%$.
  * Số buổi còn có thể vắng: $\min(N - M, \max(0, L - A))$.
- Khớp chính xác ví dụ nghiệm thu: $N=15, L=3, M=8, A=2 \rightarrow$ Còn 1 buổi, tỷ lệ hiện tại 75.0%, nếu vắng tiếp ~66.67%.

---

## 3. Tài khoản và email xác thực

Ứng dụng không cung cấp tài khoản đăng nhập nhanh, OTP dev hoặc tự điền mã. Đăng ký bằng email thật → nhập OTP kích hoạt → đăng nhập bằng mật khẩu/khuôn mặt → nhập OTP đăng nhập mới.

Cần cấu hình tài khoản SMTP gửi thư trước khi sử dụng. Chạy `scripts/Configure-Email.ps1`, khởi động lại API và làm theo [hướng dẫn email](docs/EMAIL_SETUP.md). Thiếu/lỗi SMTP trả HTTP 503, không có cơ chế bỏ qua xác thực.

API không tự nạp tài khoản/lớp mẫu. Tài khoản, lớp và lịch sử đã có không bị xóa; tài khoản cũ cần xác minh email.

Để tạo quản trị viên dùng email thật, chạy `scripts/Configure-Admin.ps1` rồi khởi động lại API. Không ghi đè admin cũ hoặc tự xác minh email mẫu. Kiểm tra cấu hình bằng `scripts/Test-LocalReadiness.ps1`. Xem [kết quả kiểm chứng](docs/VERIFICATION.md) và [các lỗi chính đã sửa](docs/MAJOR_FIX_PROGRESS.md).

---

## 4. Hướng dẫn Khởi chạy Nhanh

### Bước 1: Khởi động Cơ sở dữ liệu PostgreSQL cục bộ
```powershell
powershell -ExecutionPolicy Bypass -File scripts\Initialize-Local.ps1
```

### Bước 2: Khởi động WebAPI
```powershell
powershell -ExecutionPolicy Bypass -File scripts\Start-Backend.ps1
```
Swagger UI sẵn sàng tại: `http://127.0.0.1:5000/swagger`.

### Bước 3: Khởi chạy Ứng dụng Di động
```powershell
cd mobile\phamlehuyhoang
flutter run
```

---

## 5. Cấu trúc Thư mục

```text
api/phamlehuyhoang/                 # Mã nguồn ASP.NET Core 10 WebAPI
├── Controllers/                    # REST API Controllers (Auth, Users, Classes, Attendance)
├── Data/                           # AppDbContext & DbInitializer (Auto Migrate & Seed)
├── DTOs/                           # Data Transfer Objects
├── Entities/                       # Domain Entities
├── Enums/                          # UserRole, AttendanceStatus
├── Migrations/                     # EF Core PostgreSQL Migrations
├── Services/                       # Attendance, Face, Otp, Email, Auth Services
mobile/phamlehuyhoang/              # Ứng dụng di động Flutter (Android)
├── lib/
│   ├── models/                     # DTOs & Models
│   ├── screens/                    # Giao diện Admin, Giảng viên, Sinh viên, Auth
│   ├── services/                   # ApiClient, LocationService, AttendanceService
│   ├── theme/                      # Material 3 Design Theme
│   └── main.dart                   # Entry point
tests/phamlehuyhoang.Tests/         # 25 bài kiểm thử xUnit cho nghiệp vụ & công thức
database/                           # File SQL dựng schema tự động (schema.sql)
scripts/                            # PowerShell Scripts khởi tạo, chạy backend, conveyor
docs/                               # Toàn bộ tài liệu chi tiết (DECISIONS, SETUP, DEMO, VERIFICATION, HANDOVER)
THIRD_PARTY_NOTICES.md              # Bản quyền thư viện bên thứ ba
README.md                           # Tài liệu tổng quan
```

---

## 6. Tài liệu Chi tiết kèm theo

- [Tài liệu Quyết định Kiến trúc & Kỹ thuật (docs/DECISIONS.md)](docs/DECISIONS.md)
- [Hướng dẫn Cài đặt & Khởi chạy Chi tiết (docs/SETUP.md)](docs/SETUP.md)
- [Kịch bản Trình diễn Toàn diện (docs/DEMO.md)](docs/DEMO.md)
- [Báo cáo Kiểm chứng & Bằng chứng Test (docs/VERIFICATION.md)](docs/VERIFICATION.md)
- [Biên bản Bàn giao Đồ án (docs/HANDOVER.md)](docs/HANDOVER.md)
- [Thông báo Bản quyền Phần mềm bên thứ ba (THIRD_PARTY_NOTICES.md)](THIRD_PARTY_NOTICES.md)
