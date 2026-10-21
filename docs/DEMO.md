# Kịch bản Trình diễn & Hướng dẫn Đánh giá — phamlehuyhoang

Tài liệu này cung cấp kịch bản trình diễn xuyên suốt toàn bộ chức năng của đồ án theo yêu cầu tại `ANTIGRAVITY_MASTER_PROMPT.md` và `docs/superpowers/plans/2026-10-21-phamlehuyhoang-plan.md`.

---

## 1. Dữ liệu & Tài khoản Mẫu có sẵn

| Vai trò | Tên đăng nhập | Mật khẩu | Ghi chú |
|---|---|---|---|
| **Quản trị viên (Admin)** | `admin` | `Admin@123456` | Quản lý tài khoản, môn học, lớp học phần, phân công |
| **Giảng viên (Lecturer)** | `giangvien1` | `GiangVien@123` | Phụ trách lớp `261_INT3101_01`, mở/đóng QR, chốt kết quả |
| **Sinh viên 1 (Student)** | `sinhvien1` | `SinhVien@123` | MSSV: `23010001` (dùng demo kịch bản điểm danh & dự báo) |
| **Sinh viên 2 (Student)** | `sinhvien2` | `SinhVien@123` | MSSV: `23010002` (sinh viên thứ hai trong lớp) |

---

## 2. Kịch bản Trình diễn Xuyên suốt (End-to-End Demo)

### Bước 1: Quản trị viên khởi tạo và quản lý hệ thống
1. Mở ứng dụng, chọn chip đăng nhập nhanh **Admin** (`admin` / `Admin@123456`).
2. Bấm **Đăng nhập (Bước 1/2)**.
3. Màn hình chuyển sang nhập OTP: mã OTP dev được hiển thị sẵn trên màn hình (hoặc gửi qua email nếu có SMTP). Bấm **Xác thực & Vào ứng dụng**.
4. Màn hình Dashboard Admin xuất hiện:
   - Vào **Quản lý Môn học**: xem môn `INT3101 - Lập trình thiết bị di động (3 TC)`.
   - Vào **Quản lý Lớp học phần**: xem lớp `261_INT3101_01`, được phân công cho TS. Nguyễn Văn Hướng (`giangvien1`), cấu hình $N = 15$ buổi học, $L = 3$ buổi vắng tối đa, bán kính GPS mặc định 100 mét.
   - Bấm **Ghi danh SV**: xem danh sách sinh viên `sinhvien1` và `sinhvien2` đã được ghi danh.
5. Đăng xuất tài khoản Admin.

---

### Bước 2: Sinh viên đăng nhập & Đăng ký khuôn mặt (Mục a)
1. Chọn chip **Sinh viên 1** (`sinhvien1` / `SinhVien@123`).
2. Hoàn thành bước xác thực OTP.
3. Vào Dashboard Sinh viên:
   - Thấy huy hiệu *"Chưa đăng ký khuôn mặt"*.
   - Bấm vào mục **Đăng ký / Cập nhật Mẫu Khuôn mặt (Mục a)**.
   - Bấm **Chụp Camera** (hoặc chọn ảnh từ Thư viện nếu chạy trên Emulator).
   - Bấm **Lưu Mẫu Khuôn mặt vào Hệ thống**.
   - Máy chủ trích xuất vector đặc trưng 128 chiều và lưu an toàn. Huy hiệu đổi thành *"Đã có mẫu khuôn mặt"*.
4. Đăng xuất tài khoản.

---

### Bước 3: Trình diễn Đăng nhập bằng Khuôn mặt (Mục a)
1. Tại màn hình Đăng nhập, bấm nút **Đăng nhập bằng Khuôn mặt (Mục a)**.
2. Nhập tên tài khoản `sinhvien1`.
3. Chụp khuôn mặt của sinh viên.
4. Bấm **Xác thực Khuôn mặt & Nhận OTP**:
   - Máy chủ so khớp 1:1 vector khuôn mặt với mẫu đã đăng ký bằng độ tương đồng Cosine (ngưỡng $\ge 0.60$).
   - Nếu khớp: thông báo thành công và chuyển ngay sang màn hình OTP bước 2.
   - *(Nếu thử chụp khuôn mặt người khác hoặc ảnh không liên quan: hệ thống từ chối và báo rõ độ tương đồng không đạt)*.
5. Nhập OTP và vào Dashboard Sinh viên.

---

### Bước 4: Giảng viên mở phiên điểm danh QR (Mục e)
1. Đăng nhập tài khoản Giảng viên (`giangvien1` / `GiangVien@123`) + OTP.
2. Vào lớp `261_INT3101_01`:
   - Danh sách hiển thị 15 buổi học. Các buổi từ 1 đến 8 đã chốt kết quả.
   - Chọn **Buổi 9** (chưa chốt), bấm biểu tượng **Mã QR**.
3. Màn hình hiển thị mã QR động:
   - Đồng hồ đếm ngược 60 giây.
   - Bấm **Làm mới Mã QR**: hệ thống tự động gia hạn và sinh mã challenge mới.
   - Để nguyên mã QR trên màn hình để sinh viên quét.

---

### Bước 5: Sinh viên quét QR & Gửi vị trí GPS (Mục e & Mục b)
1. Mở app sinh viên (hoặc thiết bị thứ hai / màn hình thứ hai).
2. Tại Dashboard Sinh viên, bấm **BẬT QUÉT QR + GỬI TỌA ĐỘ**.
3. Camera bật lên, hướng vào mã QR của Giảng viên (hoặc bấm biểu tượng bàn phím nhập mã token thủ công nếu chạy 2 cửa sổ trên cùng máy).
4. Hệ thống tự động thu thập tọa độ GPS hiện tại qua `geolocator`:
   - Máy chủ tính khoảng cách Haversine giữa tọa độ sinh viên và phòng học.
   - Kiểm tra sai số GPS $\le 50$m, thời gian $\le 60$s.
   - Báo kết quả: **"Điểm danh thành công! Khoảng cách tới phòng học: 15.2 mét"**.
5. Bấm quét lại lần thứ hai: hệ thống nhận diện sinh viên đã điểm danh trước đó, không tạo bản ghi trùng lặp và không gây lỗi.

---

### Bước 6: Giảng viên chốt kết quả & Điều chỉnh có lưu lịch sử
1. Quay lại màn hình Giảng viên, vào buổi 9:
   - Sinh viên `sinhvien1` hiển thị trạng thái **Có mặt** kèm giờ điểm danh và khoảng cách.
   - Sinh viên `sinhvien2` chưa quét QR.
2. Bấm **Chốt buổi học**:
   - Hệ thống tự động ghi nhận sinh viên `sinhvien2` là **Vắng mặt** (Unexcused absent).
3. Thao tác điều chỉnh điểm danh:
   - Bấm biểu tượng cây bút tại dòng sinh viên `sinhvien2`.
   - Đổi trạng thái từ *"Vắng mặt"* sang *"Có phép"*.
   - Nhập lý do: *"Có đơn xin phép nghỉ ốm hợp lệ"*.
   - Bấm **Lưu thay đổi**: hệ thống lưu lại lịch sử người sửa, thời điểm và lý do.

---

### Bước 7: Sinh viên kiểm tra Dự báo Chuyên cần (Tính năng đề xuất)
1. Đăng nhập lại `sinhvien1`.
2. Bấm **Dự báo chuyên cần**:
   - Hiển thị đầy đủ số liệu theo đúng trường hợp kiểm thử trong kế hoạch:
     * Tổng số buổi chính thức: $N = 15$.
     * Giới hạn vắng tối đa: $L = 3$.
     * Số buổi đã chốt: $M = 8$.
     * Số buổi vắng tính kỷ luật: $A = 2$.
     * Tỷ lệ chuyên cần hiện tại: $(8 - 2) / 8 \times 100\% = \mathbf{75.0\%}$.
     * Tỷ lệ dự báo nếu vắng buổi tiếp theo: $(8 - 2) / (8 + 1) \times 100\% \approx \mathbf{66.67\%}$.
     * Số buổi còn có thể vắng: $\min(15 - 8, \max(0, 3 - 2)) = \mathbf{1\text{ buổi}}$.
   - Trạng thái cảnh báo: *"Chuyên cần ổn định: Bạn còn có thể vắng tối đa 1 buổi nữa mà không vượt giới hạn."*
