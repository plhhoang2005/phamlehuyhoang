# Kịch bản sử dụng và trình diễn

## Chuẩn bị

- Chạy PostgreSQL, WebAPI và cấu hình URL thiết bị (Conveyor/LAN hoặc USB).
- Cấu hình SMTP gửi email thật theo [EMAIL_SETUP.md](EMAIL_SETUP.md); kiểm tra hộp thư đến và thư rác.
- Sử dụng tài khoản thật đã được cấp đúng vai trò. Môi trường mới có thể tạo admin bằng cấu hình BootstrapAdmin; không dùng tài khoản/mật khẩu mẫu hoặc mã OTP từ log.
- Admin tạo môn học, lớp, phân công giảng viên và thêm sinh viên qua UI.

## Đăng ký và kích hoạt sinh viên

1. Chọn đăng ký, nhập username, email thật, họ tên, mã sinh viên và mật khẩu.
2. Khi gửi thư thành công, app mở màn hình kích hoạt; ô OTP luôn trống.
3. Đọc mã trong email và nhập tay. Kích hoạt thành công trở về đăng nhập, chưa vào dashboard.
4. Nếu chưa cấu hình hoặc gửi thư lỗi, app báo lỗi; không có nút bỏ qua hoặc mã dev.

## Đăng nhập bằng mật khẩu

1. Nhập tài khoản đã kích hoạt và mật khẩu.
2. Nhận một OTP đăng nhập mới qua email và tự nhập mã.
3. Xác thực thành công vào dashboard đúng vai trò. Thử mã sai/hết hạn/đã dùng để kiểm tra từ chối.
4. Tài khoản cũ chưa xác minh được chuyển sang kích hoạt email trước khi đăng nhập.

## Đăng nhập bằng khuôn mặt

1. Sau khi đăng nhập hợp lệ, đăng ký khuôn mặt cho tài khoản của chính mình.
2. Đăng xuất, chọn đăng nhập bằng khuôn mặt, nhập username và chụp ảnh.
3. Đối chiếu thành công phải tiếp tục nhận và nhập OTP email; không tự vào dashboard.
4. Người khác hoặc ảnh không đạt bị từ chối theo khả năng giải pháp; không tuyên bố có liveness hoàn chỉnh.

## Điểm danh QR và vị trí

1. Giảng viên vào lớp được phân công, tạo buổi, đặt tọa độ/bán kính rồi mở phiên QR.
2. Sinh viên thuộc lớp đăng nhập, quét QR bằng camera và gửi vị trí.
3. Kiểm tra thành công trong vùng; ngoài vùng, mã sai/hết hạn, phiên đã đóng và người ngoài lớp bị từ chối.
4. Quét lại không tạo kết quả thứ hai. Giảng viên xem danh sách và chốt kết quả.

## Dự báo chuyên cần

1. Sinh viên mở chuyên cần theo lớp; dữ liệu lấy từ các buổi đã chốt.
2. Xem số vắng, số còn được vắng và tỷ lệ nếu vắng buổi tiếp.
3. Có thể chuẩn bị một lớp kiểm tra với N=15, L=3, M=8, A=2 để đối chiếu 75% và khoảng 66,67%; không tự giả dữ liệu này ở client.

Chỉ đánh dấu trình diễn thành công khi các bước đã chạy thật; SMTP chấp nhận thư chưa đồng nghĩa đã kiểm tra thư tới Inbox.
