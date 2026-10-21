# Bàn giao phamlehuyhoang — 21/10/2026

Flutter Android, ASP.NET Core WebAPI .NET 10 và PostgreSQL. Conveyor cung cấp đường truy cập tới API từ Visual Studio. Project mobile, WebAPI và database chính giữ tên phamlehuyhoang.

## Thiết lập để sử dụng

Từ repository, chạy lần lượt trong PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/Initialize-Local.ps1
powershell -ExecutionPolicy Bypass -File scripts/Configure-Email.ps1
powershell -ExecutionPolicy Bypass -File scripts/Configure-Admin.ps1
powershell -ExecutionPolicy Bypass -File scripts/Initialize-FaceModels.ps1
powershell -ExecutionPolicy Bypass -File scripts/Start-Backend.ps1
```

Cấu hình riêng lưu trong .local đã được gitignore. Email gửi OTP cần SMTP thật. Script nhập mật khẩu bằng ô ẩn; không đưa mật khẩu vào mã nguồn, chat hoặc Git. Admin mới dùng username/email chưa tồn tại, xác minh email rồi đăng nhập bằng OTP mới. Sau khi tạo admin, bỏ mục BootstrapAdmin trong cấu hình riêng để không giữ mật khẩu bootstrap.

Xem [EMAIL_SETUP.md](EMAIL_SETUP.md), [FACE_SETUP.md](FACE_SETUP.md) và [SETUP.md](SETUP.md). Test-LocalReadiness.ps1 chỉ kiểm tra sự hiện diện của cấu hình/mô hình; không chứng minh thư đã đến.

## Luồng sử dụng

1. Admin tạo môn, lớp, phân công giảng viên, ghi danh sinh viên. Có sửa/xóa môn và lớp; lớp có lịch sử điểm danh không được xóa. Tài khoản có sửa, khóa/mở khóa để giữ lịch sử.
2. Giảng viên tạo buổi học, nhập thời gian, tọa độ và bán kính hoặc chọn lấy GPS thật. Có sửa/hủy/khôi phục buổi chưa chốt.
3. Giảng viên mở QR theo buổi, mã hiệu lực 60 giây; dùng nút làm mới khi hết hạn. Sinh viên quét bằng camera, gửi GPS và thời điểm đo thật.
4. API kiểm tra lớp, hạn QR, trạng thái buổi, độ mới GPS, sai số và khoảng cách trước khi lưu. Không báo thành công nếu lưu lỗi hoặc kết quả đồng thời là vắng do chốt buổi.
5. Giảng viên chốt buổi và điều chỉnh kết quả kèm lý do. Sinh viên xem lịch sử và dự báo số buổi còn được vắng.
6. Sinh viên đăng nhập bằng mật khẩu để đăng ký mẫu khuôn mặt mới. YuNet/SFace đối chiếu danh tính; đăng nhập khuôn mặt vẫn cần OTP email.

## Nâng cấp và xác thực

API tự áp dụng migration bổ sung EmailConfirmed, OTP hash và AuthVersion. Không xóa người dùng, lớp hoặc lịch sử cũ. JWT cũ phải đăng nhập lại. Đổi vai trò/email/khóa/mở khóa tăng phiên bản quyền và vô hiệu OTP đang chờ; hoàn tác giá trị cũ không làm JWT cũ dùng lại được.

Mẫu khuôn mặt độ sáng cũ bị từ chối. Người dùng phải đăng nhập bằng mật khẩu và đăng ký lại mặt. Nhận diện chưa có liveness; không tuyên bố chống ảnh in hoặc video phát lại.

## Bằng chứng và giới hạn

Xem [VERIFICATION.md](VERIFICATION.md). Bộ test backend 84/84, Flutter 26/26, phân tích sạch và PostgreSQL thật đã được kiểm tra. APK release mới đã build thành công tại mobile/phamlehuyhoang/build/app/outputs/flutter-apk/app-release.apk.

Hiện chưa cấu hình SMTP/BootstrapAdmin thật và không có thiết bị debug kết nối. Chưa xác nhận thư đến Gmail hoặc camera/GPS trên điện thoại sau lần sửa này. Không thay các bước còn lại bằng OTP dev, dữ liệu giả hoặc nhập token thủ công.
