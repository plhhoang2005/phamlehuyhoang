# Xác minh email và OTP đăng nhập

## Luồng sử dụng

1. Đăng ký: tạo tài khoản chưa xác minh và gửi OTP kích hoạt tới email đã nhập.
2. Nhập OTP kích hoạt: xác minh quyền sở hữu email, trở về màn hình đăng nhập. Bước này không cấp JWT hoặc đưa vào dashboard.
3. Đăng nhập bằng mật khẩu hoặc khuôn mặt: tài khoản đã kích hoạt nhận OTP đăng nhập mới; nhập đúng mã mới được cấp phiên.
4. Tài khoản từ phiên bản cũ chưa xác minh: lần đăng nhập tiếp theo chuyển sang kích hoạt trước. Không tự coi email đã xác minh chỉ vì tài khoản từng tồn tại.

Hai loại OTP có ticket và mục đích riêng; không thể dùng chéo. Mã có hạn 5 phút, tối đa 5 lần thử; gửi lại sau 60 giây vô hiệu mã cũ. Mã không được trả về API, không ghi log và không tự điền trong app, kể cả khi WebAPI chạy Development. Database lưu giá trị băm của OTP.

## Cấu hình Gmail gửi thư thật

Email gửi thư là tài khoản của hệ thống; email nhận là email người dùng đăng ký. Không cần mỗi người dùng cung cấp mật khẩu Gmail.

1. Chủ email gửi bật xác minh hai bước và tự tạo App Password nếu tài khoản Google cho phép: [hướng dẫn Google](https://support.google.com/mail/answer/185833?hl=vi). Dùng App Password của tài khoản gửi, không dùng mật khẩu đăng nhập Google thông thường. Nếu tổ chức không cho phép App Password, dùng SMTP/provider được tổ chức chấp thuận.
2. Từ thư mục project, chạy:

```powershell
.\scripts\Configure-Email.ps1
```

Script yêu cầu email gửi và App Password bằng ô nhập ẩn, lưu trong `.local/api-settings.json` đã được gitignore. Không nhập App Password trong chat, mã nguồn hoặc tham số lệnh được lưu vào lịch sử.

3. Khởi động lại WebAPI:

```powershell
.\scripts\Start-Backend.ps1
```

SMTP Gmail mặc định: `smtp.gmail.com`, cổng `587` với STARTTLS bắt buộc. Cổng `465` dùng TLS ngay khi kết nối. Không tắt kiểm tra chứng chỉ. Nếu chạy WebAPI từ profile không phải Development, dùng cấu hình môi trường hoặc user-secrets thay cho file `.local` chỉ được nạp ở Development.

Cũng có thể cấp `Smtp:Host`, `Smtp:Port`, `Smtp:User`, `Smtp:Password` qua cơ chế cấu hình ASP.NET Core, hoặc các biến `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`. Khởi động lại API sau khi thay đổi.

## Khi dịch vụ email chưa sẵn sàng

- API trả HTTP 503 với thông báo không gửi được email; không nói đã gửi, không cấp ticket dùng được và không có OTP dự phòng.
- Đăng ký gặp lỗi email có thể đã lưu tài khoản ở trạng thái chưa xác minh. Sau khi cấu hình email, dùng tài khoản/mật khẩu đó để yêu cầu OTP kích hoạt từ màn hình đăng nhập.
- Chỉ phản hồi SMTP chấp nhận thư mới được coi là gửi thành công. Cần kiểm tra thư đến/thư rác thực tế; chấp nhận SMTP chưa chứng minh thư đã vào Inbox.
- Nếu báo sai tài khoản gửi/SMTP, kiểm tra App Password, chính sách tài khoản Google, cổng và kết nối mạng. Không bật fallback hiển thị mã trên app.

## Quản trị viên trên môi trường mới

API không tự tạo tài khoản mẫu hoặc nạp lớp/buổi điểm danh demo. Chạy `.\scripts\Configure-Admin.ps1` để nhập username mới, email thật và mật khẩu bằng ô nhập ẩn, sau đó khởi động lại API. Script lưu riêng `BootstrapAdmin:Username`, `BootstrapAdmin:Email`, `BootstrapAdmin:Password` trong `.local/api-settings.json`. Dùng username/email chưa được dùng; tài khoản bootstrap cũng phải xác minh email và nhập OTP đăng nhập như người dùng khác. Không tự cập nhật quyền hoặc email của tài khoản đã có. Sau khi tạo thành công, xóa mục `BootstrapAdmin` khỏi cấu hình để bỏ mật khẩu bootstrap; tài khoản đã lưu trong database vẫn giữ nguyên.

Nếu database cũ chỉ có admin/giảng viên dùng địa chỉ mẫu không nhận được thư, tạo một admin mới bằng email thật theo bước trên; không đánh dấu xác minh cho email mẫu. Admin mới có thể quản lý giảng viên và tài khoản cũ bằng giao diện quản trị. Giảng viên có email thật do admin tạo cũng kích hoạt qua luồng đăng nhập.

Chạy `.\scripts\Test-LocalReadiness.ps1` để kiểm tra cấu hình có mặt mà không in App Password hoặc mật khẩu database. Kết quả `SmtpConfigured = True` chưa chứng minh gửi thư thành công; vẫn cần đăng ký và nhận OTP thực tế.

Nâng cấp không xóa tài khoản, lớp hoặc lịch sử cũ. Các OTP dev đang chờ bị vô hiệu khi migration được áp dụng; mọi tài khoản cũ phải xác minh email trước khi được cấp hoặc sử dụng phiên.
