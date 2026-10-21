# Kết quả kiểm chứng — 21/10/2026

## Backend

Lệnh: dotnet test tests/phamlehuyhoang.Tests --no-restore -p:UseAppHost=false.

Kết quả sau lần sửa cuối: **84 passed, 0 failed, 0 skipped**, không có cảnh báo build .NET. Gồm activation/login OTP tách biệt, SMTP thất bại không tạo challenge dùng được, OTP hash/hạn/số lần thử/gửi lại, CRUD, quyền theo lớp, GPS, lưu điểm danh, dự báo, thu hồi token và bootstrap admin.

Đã quan sát kiểm thử thất bại trước khi sửa các lỗi chính. Kiểm thử đồng thời tái hiện chốt buổi chèn bản ghi vắng trong lúc check-in lưu; kết quả không được báo thành công. Khóa/mở khóa, đổi vai trò rồi đổi lại, đổi email rồi đổi lại đều không khôi phục JWT cũ.

**12 kiểm thử khuôn mặt** chạy suy luận OpenCV native thật với YuNet/SFace, hai ảnh khác nhau của cùng một người, người khác, gradient/checkerboard và ảnh hai khuôn mặt. Đây là hồi quy, không phải đánh giá sinh trắc học đại diện toàn bộ người dùng. Mô hình, fixture, hash và giấy phép: [FACE_SETUP.md](FACE_SETUP.md).

## Flutter

Lệnh tại mobile/phamlehuyhoang:

```powershell
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --release --no-pub
```

Phân tích: **No issues found**. Test: **26 passed**, gồm mạng, OTP trống/không đọc mã dev, activation không lưu JWT, CRUD gửi yêu cầu và tải lại dữ liệu, lỗi biểu mẫu giữ dữ liệu, tạo/sửa/hủy buổi, UTC, GPS cũ và quét lặp khi hộp thoại mở.

Build release thành công, APK **68.7 MB** tại mobile/phamlehuyhoang/build/app/outputs/flutter-apk/app-release.apk. Gradle có cảnh báo Java native-access, không làm build thất bại.

APK dài 72.084.632 byte, SHA256: `670C886D6BDF10B9AC2C69A019E6A72AFADF516E0F4A86B19EA3E2D8FE911636`.

## PostgreSQL thật

Harness riêng trong .local/postgres-smoke tạo database tạm tên riêng, áp dụng migration rồi chạy CRUD người dùng/môn/lớp/buổi, ghi danh, QR, lưu/quét trùng, chặn truy cập token, chốt buổi, điều chỉnh có lịch sử, dự báo, đổi email và xóa an toàn. Kết quả **POSTGRES_SMOKE_PASS** sau migration phiên bản quyền. Database thử nghiệm được xóa sau đó; dữ liệu project chính không bị thay bằng fixture.

API local khởi động lại, áp dụng migration 20261021075851_RevokeChangedAccountSessions bổ sung AuthVersion; migration chỉ thêm cột. Database chính vẫn là phamlehuyhoang. GET http://127.0.0.1:5000/health trả HTTP 200 và Healthy.

## Giới hạn bằng chứng

- Mô hình thật đã cài và kiểm tra hash trong .local/models/face.
- SMTP và BootstrapAdmin thật chưa cấu hình. Email tests dùng sender giả trong bộ test, không phải bằng chứng thư đến Gmail. Cần [EMAIL_SETUP.md](EMAIL_SETUP.md).
- Đã khám phá Dart Tooling Daemon và thử hot restart, không có app kết nối; ADB không liệt kê thiết bị. Chưa xác minh camera, GPS, cấp quyền hay giao diện mới trên điện thoại vật lý.
- Chưa có liveness. Phát hiện GPS giả ở client không bảo đảm chống giả mạo toàn diện.
- Ứng dụng không có nhập token AVD/Test, OTP hiển thị hoặc tài khoản đăng nhập nhanh.
