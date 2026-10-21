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
- **Bảo mật & Xác thực:** Mật khẩu băm PBKDF2 SHA-256 (ASP.NET Identity standard), xác thực 2 lớp bắt buộc (Mật khẩu / Khuôn mặt + OTP 6 chữ số), JWT Bearer Token, kiểm soát quyền theo vai trò và đối tượng.

---

## 2. Ba chức năng mở rộng đã chọn & Tính năng mới đề xuất

### 2.1. Đăng nhập bằng khuôn mặt (Mục a)
- Thu nhận ảnh mặt qua Camera / Thư viện.
- Trích xuất vector đặc trưng khuôn mặt (Embedding 128 chiều chuẩn hóa L2).
- Đối chiếu 1:1 với mẫu đã lưu của tài khoản bằng độ tương đồng Cosine (ngưỡng $\ge 0.60$ theo chuẩn OpenCV SFace).
- Kết hợp OTP 2 lớp trước khi cấp phiên đăng nhập; có fallback sang đăng nhập mật khẩu khi camera/nhận diện gặp sự cố.

### 2.2. Vị trí khi điểm danh (Mục b)
- Giảng viên cấu hình tọa độ phòng học và bán kính cho phép (mặc định 100 mét).
- Sinh viên gửi tọa độ GPS hiện tại và độ chính xác khi quét điểm danh.
- Máy chủ độc lập tính khoảng cách bằng công thức lượng giác hình cầu Haversine; từ chối khi sai số GPS $> 50$m hoặc khoảng cách vượt bán kính.

### 2.3. QR theo buổi học (Mục e)
- Giảng viên mở phiên điểm danh cho buổi học thuộc lớp được phân công.
- Sinh mã QR challenge ngẫu nhiên với thời hạn 60 giây, cho phép làm mới tự động.
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

## 3. Danh sách Tài khoản Kiểm thử Môi trường Phát triển

| Vai trò | Tên đăng nhập | Mật khẩu | Mô tả / Chức năng |
|---|---|---|---|
| **Admin** | `admin` | `Admin@123456` | Quản trị tài khoản, môn học, lớp học phần, phân công |
| **Giảng viên** | `giangvien1` | `GiangVien@123` | TS. Nguyễn Văn Hướng — Mở QR, chốt kết quả, điều chỉnh điểm danh |
| **Sinh viên 1** | `sinhvien1` | `SinhVien@123` | Phạm Lê Huy Hoàng (MSSV 23010001) — Demo QR, GPS, Mặt & Dự báo |
| **Sinh viên 2** | `sinhvien2` | `SinhVien@123` | Trần Thị Mai (MSSV 23010002) — Sinh viên thứ hai trong lớp |

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
