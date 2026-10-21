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
- Tạo cấu hình PostgreSQL riêng trong `.local/`; không tạo tài khoản đăng nhập ứng dụng mẫu.

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

Khi khởi động, WebAPI sẽ thực hiện migration bằng `DbInitializer.InitializeAsync`. Không tự nạp tài khoản, lớp hoặc buổi điểm danh demo. Swagger tại `http://127.0.0.1:5000/swagger`.

Trước khi đăng ký/đăng nhập, cấu hình Gmail/SMTP bằng `scripts/Configure-Email.ps1` và khởi động lại API. Xem [hướng dẫn xác minh email và OTP](EMAIL_SETUP.md).
---

## 4. Cấu hình Tunnel Conveyor cho Điện thoại thật

Có thể dùng **Cloudflare Quick Tunnel** thay Conveyor: chạy `scripts/Start-Cloudflare.ps1` sau khi API hoạt động, rồi nhập URL HTTPS vào app. Hướng dẫn bật/tắt và giữ kết nối: [CLOUDFLARE_QUICK_TUNNEL.md](CLOUDFLARE_QUICK_TUNNEL.md).

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

App Android không tự giả định đang chạy trên máy ảo. Cấu hình URL ở bánh răng màn hình đăng nhập hoặc truyền `--dart-define=API_BASE_URL=...` khi build.

### Khắc phục lỗi kết nối máy chủ

1. Chạy `scripts/Start-Backend.ps1` ở thư mục gốc, giữ cửa sổ API đang chạy. Kiểm tra `http://127.0.0.1:5000/health` trên máy tính phải trả HTTP 200.
2. Điện thoại thật: chọn URL HTTPS do Conveyor cung cấp; không dùng `10.0.2.2` (chỉ dành cho Android Emulator).
3. Khi cùng Wi-Fi, có thể dùng `http://<IP-LAN-may-tinh>:5000` nếu API lắng nghe trên giao diện LAN và mạng cho phép kết nối.
4. Khi cắm USB và bật USB debugging, chạy `adb reverse tcp:5000 tcp:5000`, sau đó nhập `http://127.0.0.1:5000` trong app. Kết nối này phụ thuộc USB/ADB, không phải URL dùng khi phát hành.
5. Chỉ khi chạy Android Emulator mới chọn `http://10.0.2.2:5000`. URL đã lưu trong app được ưu tiên hơn `API_BASE_URL`; sửa trong Cài đặt máy chủ nếu vẫn dùng URL cũ.

Màn hình đăng nhập để trống tài khoản/mật khẩu và không hiển thị lựa chọn tài khoản thử nghiệm. Thay đổi này không xóa người dùng hoặc dữ liệu đã có trong PostgreSQL.

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
