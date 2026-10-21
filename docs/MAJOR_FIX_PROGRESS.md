# Sửa lỗi chính đã được xác nhận

Phạm vi: 11 lỗi trong lần rà soát, sửa trên workspace hiện tại và giữ dữ liệu.

- [ ] Gửi Gmail thật: mã nguồn và script cấu hình đã có; chưa có SMTP riêng để kiểm chứng thư đến.
- [ ] Đăng nhập admin bằng email thật: script bootstrap đã có, không ghi đè tài khoản cũ; chưa nhập cấu hình cá nhân.
- [x] CRUD môn học, tài khoản, lớp học trên API và ứng dụng. Tài khoản dùng khóa/mở khóa để giữ lịch sử.
- [x] Tạo/sửa/hủy buổi học và địa điểm để mở QR ngay trong ứng dụng.
- [x] Thay so sánh độ sáng bằng mô hình YuNet/SFace thật; đã cài mô hình và kiểm thử suy luận.
- [x] Điểm danh chỉ báo thành công khi có kết quả tham dự đã lưu; chặn cả trường hợp đồng thời chốt buổi thành vắng.
- [x] Phân quyền theo lớp của giảng viên và lớp sinh viên tham gia.
- [x] Token có phiên bản; không được phục hồi khi khóa/mở khóa hoặc đổi quyền/email rồi đổi lại.
- [x] Kiểm tra tuổi tọa độ GPS và gửi thời điểm đo thật.
- [x] Chặn quét lặp trong suốt thao tác và hộp thoại kết quả.
- [x] Chặn sinh viên lấy token QR từ API; bỏ nhập token AVD/Test.

Không đánh dấu kiểm thử Gmail/thiết bị thật thành công khi chưa có cấu hình hoặc thiết bị.
