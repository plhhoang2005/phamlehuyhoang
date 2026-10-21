# Hướng dẫn Cài đặt & Khởi chạy — phamlehuyhoang

Tài liệu này hướng dẫn cài đặt và khởi chạy toàn bộ hệ thống Điểm danh sinh viên (gồm Database PostgreSQL, WebAPI ASP.NET Core, và Mobile App Flutter Android).

---

## 1. Yêu cầu môi trường (Prerequisites)

- **Hệ điều hành:** Windows 10/11 (hoặc macOS/Linux tương đương).
- **.NET SDK:** .NET 10 (Target `net10.0`, kiểm tra bằng `dotnet --version`).
- **PostgreSQL:** PostgreSQL 18 (hoặc 15-18). Mặc định công cụ tại `C:\Program Files\PostgreSQL\18\bin`.
- **Flutter SDK:** Flutter 3.47+ (Dart 3.13+, kiểm tra bằng `flutter --version`).
- **Android SDK:** Hỗ trợ Android API 23 đến 36.

---

## 2. Khởi tạo Cơ sở dữ liệu PostgreSQL cục bộ

Dự án cung cấp script khởi tạo cluster dữ liệu cục bộ tự động tại `.local/pg-data`, chạy cổng riêng `54321` (không xung đột với database có sẵn trên máy):

```powershell
# Chạy từ thư mục gốc repository phamlehuyhoang:
powershell -ExecutionPolicy Bypass -File scripts\Initialize-Local.ps1
```

Script sẽ:
- Khởi tạo cluster PostgreSQL 18 tại `.local/pg-data`.
- Chạy PostgreSQL daemon tại `127.0.0.1:54321`.
- Tự động tạo role `phamlehuyhoang_app` và database `phamlehuyhoang`.
- Tạo file cấu hình và lưu thông tin đăng nhập tại `.local/dev-accounts.txt`.

*Để tắt PostgreSQL khi không sử dụng:*
```powershell
powershell -ExecutionPolicy Bypass -File scripts\Stop-Database.ps1
```

---

## 3. Khởi chạy WebAPI ASP.NET Core

### Cách 1: Chạy bằng PowerShell Script
```powershell
powershell -ExecutionPolicy Bypass -File scripts\Start-Backend.ps1
```

### Cách 2: Chạy trực tiếp bằng dotnet CLI
```powershell
cd api\phamlehuyhoang
dotnet run --launch-profile "http"
```

Khi khởi động, WebAPI sẽ:
- Tự động thực hiện EF Core Migration (`DbInitializer.SeedAsync`).
- Tự động nạp dữ liệu mẫu môi trường Development:
  * 1 Quản trị viên: `admin` / `Admin@123456`
  * 1 Giảng viên: `giangvien1` / `GiangVien@123`
  * 2 Sinh viên: `sinhvien1` / `SinhVien@123` (MSSV 23010001), `sinhvien2` / `SinhVien@123`
  * 1 Lớp học phần: `261_INT3101_01` (N = 15, L = 3)
  * 8 buổi học đầu tiên đã chốt (sinhvien1 có A = 2 buổi vắng để khớp dữ liệu mẫu)
  * Buổi 9 đang mở sẵn phiên QR điểm danh.
- Swagger UI có thể truy cập tại: `http://127.0.0.1:5000/swagger`.

---

## 4. Cấu hình Tunnel Conveyor cho Điện thoại thật

Để điện thoại di động truy cập được API chạy trên máy tính qua mạng Internet/4G:

1. **Mở dự án trong Visual Studio 2022/2026:**
   - Mở file `phamlehuyhoang.slnx`.
   - Chọn profile `IIS Express` hoặc `http` (cổng 5000).
   - Bấm nút **Conveyor** trên thanh công cụ Visual Studio.
2. **Lấy Remote URL:**
   - Cửa sổ Conveyor hiển thị URL dạng: `https://xxxx.conveyor.cloud`.
3. **Cấu hình trên ứng dụng di động:**
   - Khi mở app Flutter, bấm biểu tượng **Cài đặt (bánh răng)** ở góc phải màn hình Đăng nhập.
   - Dán URL Conveyor vào và bấm **Lưu**.
   - Mọi request, upload ảnh mặt và quét QR sẽ tự động đi qua URL này mà không cần build lại APK.

*(Nếu chạy trên Android Emulator AVD, app mặc định dùng `http://10.0.2.2:5000` để kết nối thẳng tới máy host).*

---

## 5. Chạy ứng dụng Flutter Di động

### Chạy trực tiếp trên thiết bị / Máy ảo
```powershell
cd mobile\phamlehuyhoang
flutter run
```

### Build file APK Android
```powershell
cd mobile\phamlehuyhoang
flutter build apk
```
File APK xuất xưởng sẽ nằm tại:
`mobile/phamlehuyhoang/build/app/outputs/flutter-apk/app-release.apk`
