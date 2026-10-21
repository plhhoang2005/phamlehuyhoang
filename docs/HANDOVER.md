# Biên bản Bàn giao Dự án Điểm danh Sinh viên — phamlehuyhoang

**Sinh viên thực hiện:** Phạm Lê Huy Hoàng  
**Học phần:** Lập trình di động  
**Ngày hoàn thành:** 21/10/2026  
**Kho lưu trữ:** `https://github.com/plhhoang2005/phamlehuyhoang`

---

## 1. Hướng dẫn Khởi động Nhanh (1 Lệnh / Scripts)

Hệ thống được tự động hóa tối đa qua các PowerShell scripts đặt tại thư mục `scripts/`:

### Bước 1: Khởi tạo toàn bộ môi trường và cơ sở dữ liệu
Chỉ cần mở PowerShell tại thư mục gốc của repository và chạy:
```powershell
.\scripts\Initialize-Local.ps1
```
*Script sẽ tự động khởi tạo PostgreSQL cluster cục bộ tại `.local/pg-data` (cổng 54321), tạo user `phamlehuyhoang_app`, database `phamlehuyhoang`, chạy EF Core Migration và nạp dữ liệu mẫu đầy đủ (3 tài khoản, môn học, lớp học phần, buổi học).*

### Bước 2: Chạy Backend WebAPI
```powershell
.\scripts\Start-Backend.ps1
```
*API sẽ chạy tại địa chỉ `http://127.0.0.1:5000` (Swagger UI sẵn sàng tại `http://127.0.0.1:5000/swagger`).*

### Bước 3: (Tùy chọn) Chạy đường hầm Conveyor cho thiết bị di động thật
```powershell
.\scripts\Start-Conveyor.ps1
```
*Conveyor cung cấp URL public/LAN an toàn để điện thoại thật hoặc máy ảo truy cập trực tiếp vào máy chủ backend của Visual Studio.*

### Bước 4: Chạy ứng dụng Flutter Mobile
```powershell
cd mobile/phamlehuyhoang
flutter run
```

---

## 2. Thông tin Tài khoản Mẫu Đã Tạo Sẵn

Hệ thống đã nạp sẵn 3 tài khoản đại diện cho 3 vai trò nghiệp vụ với dữ liệu mẫu hoàn chỉnh:

| Vai trò | Tên đăng nhập | Mật khẩu mặc định | Email xác thực | Quyền & Dữ liệu gắn kèm |
| :--- | :--- | :--- | :--- | :--- |
| **Quản trị viên** (Admin) | `admin` | `Admin@123456` | `admin@phamlehuyhoang.edu.vn` | Quản lý toàn bộ môn học, lớp, người dùng, phân công |
| **Giảng viên** (Lecturer) | `giangvien1` | `GiangVien@123` | `giangvien1@phamlehuyhoang.edu.vn` | TS. Nguyễn Văn Hướng — Quản lý lớp Lập trình Di động (INT3101_01), mở QR điểm danh, duyệt kết quả |
| **Sinh viên 1** (Student) | `sinhvien1` | `SinhVien@123` | `sinhvien1@phamlehuyhoang.edu.vn` | Phạm Lê Huy Hoàng (MSSV 23010001) — Đã ghi danh vào lớp, quét QR điểm danh, xem dự báo chuyên cần |
| **Sinh viên 2** (Student) | `sinhvien2` | `SinhVien@123` | `sinhvien2@phamlehuyhoang.edu.vn` | Trần Thị Mai (MSSV 23010002) — Sinh viên cùng lớp học phần |

> **Cơ chế OTP trong môi trường phát triển & chấm điểm:**  
> Hệ thống sinh mã OTP 6 chữ số ngẫu nhiên có hiệu lực trong 5 phút. Để thuận tiện nhất cho việc kiểm thử và chấm bài mà không phụ thuộc hạ tầng SMS/Mail ngoài, Backend trả kèm mã OTP trong phản hồi API (`otpCode`) và in rõ trên cửa sổ Terminal log của WebAPI.

---

## 3. Ma trận Tính năng Dự án

| STT | Phân hệ / Yêu cầu nghiệp vụ | Hiện trạng | Ghi chú kỹ thuật |
| :---: | :--- | :---: | :--- |
| **1** | **Xác thực & Tài khoản (Auth & OTP)** | **ĐẠT** | Đăng ký kiểm tra trùng email/username, OTP 6 số hết hạn 5 phút, khóa sau 5 lần sai, cooldown 60s. |
| **2** | **Phân quyền 3 vai trò (Admin, Lecturer, Student)** | **ĐẠT** | Phân quyền nghiêm ngặt cả ở Flutter UI Router và ASP.NET Core Policy/Claims (`RoleRequirement`). Sinh viên không thể gọi API quản trị. |
| **3** | **Quản lý Danh mục (CRUD Môn, Lớp, Phân công)** | **ĐẠT** | Quản lý môn học, lớp học phần, gán giảng viên, ghi danh sinh viên (chặn trùng lặp bằng Unique Index). |
| **4** | **Điểm danh Vị trí GPS (Mục b)** | **ĐẠT** | Haversine tính toán khoảng cách trên server; kiểm tra sai số định vị (chặn accuracy > 50m); từ chối khi vượt bán kính cấu hình. |
| **5** | **Điểm danh QR động (Mục e)** | **ĐẠT** | Giảng viên tạo phiên QR có countdown thời gian thực (10-30s); token mã hóa dùng một lần; Unique constraint chống race-condition điểm danh trùng. |
| **6** | **Đăng nhập Khuôn mặt (Mục a)** | **ĐẠT** | Đăng ký vector khuôn mặt 128 chiều; đối chiếu 1:1 Cosine Similarity ($\ge 0.60$); fallback về Password + OTP khi không khớp. |
| **7** | **Dự báo Chuyên cần (Tính năng đề xuất)** | **ĐẠT** | Công thức: Tỷ lệ hiện tại = $\frac{M-A}{M}$, Kịch bản vắng tiếp = $\frac{M-A}{M+1}$, Số buổi còn được phép vắng = $\max(0, L-A)$. Kiểm thử bao phủ toàn bộ ca biên ($M=0, M=N, A>L$). |
| **8** | **Báo cáo, Lịch sử & Điều chỉnh Điểm danh** | **ĐẠT** | Giảng viên xem danh sách sinh viên có mặt/vắng theo phiên; điều chỉnh thủ công có lưu lý do và timestamp kiểm toán. |

---

## 4. Kết quả Kiểm thử Tự động (Automated Test Execution)

### 4.1. Backend WebAPI Tests (`tests/phamlehuyhoang.Tests`)
- **Tổng số test:** 25/25 Tests **PASSED (100%)**
- **Thời gian chạy:** ~3.6 giây
- **Phân loại:**
  - `AttendanceForecastingTests` (5/5 PASSED): Đạt test ca nghiệm thu chuẩn của đề bài $N=15, M=8, A=2, L=3 \rightarrow 75.0\%, 66.67\%, 1$ buổi còn lại; ca biên $M=0$; ca kết thúc môn $M=N$; ca đã vượt ngưỡng vắng $A>L$; ca vắng có phép.
  - `HaversineDistanceTests` (7/7 PASSED): Tính chính xác khoảng cách địa lý, kiểm tra dải dung sai $\pm 0.5$m, bắt ngoại lệ NaN/vô cùng/tọa độ sai.
  - `OtpLifecycleTests` (4/4 PASSED): Mã sinh ngẫu nhiên, tiêu hủy sau khi dùng một lần, khóa sau 5 lần sai, hết hạn sau 5 phút, chặn spam 60s.
  - `FaceMatchingTests` (4/4 PASSED): Đối chiếu cosine 1.0 với vector tương đồng, 0.0 với vector trực giao, trích xuất vector 128 chiều, xử lý ảnh lỗi.
  - `AttendanceCheckInValidationTests` (5/5 PASSED): Chặn ngoài bán kính, chống race-condition quét trùng, kiểm tra hạn token QR, kiểm tra sai số định vị.

### 4.2. Mobile Flutter Tests (`mobile/phamlehuyhoang/test`)
- **Linter:** `flutter analyze` $\rightarrow$ **0 errors, 0 warnings (No issues found!)**
- **Widget & Model Tests:** 3/3 Tests **PASSED (100%)**
  - Render màn hình khởi động Splash với giao diện Material 3 tiếng Việt.
  - Parse và serialize JSON đối tượng DTO Dự báo Chuyên cần (`AttendanceForecastDto`).
  - Parse và serialize JSON đối tượng Người dùng & Token (`UserDto`).

---

## 5. Thông tin Gói Ứng dụng Android (APK Deliverable)

- **Tệp cài đặt phát hành:** `mobile/phamlehuyhoang/build/app/outputs/flutter-apk/app-release.apk`
- **Đường dẫn tuyệt đối:** `D:\Ltdd\phamlehuyhoang\mobile\phamlehuyhoang\build\app\outputs\flutter-apk\app-release.apk`
- **Tên gói ứng dụng (Package Name):** `com.phamlehuyhoang.app`
- **Kích thước file:** 71,094,540 bytes (~67.8 MB)
- **Mã băm SHA-256:** `CC830D9B96FDFDB9906888D06262A290A762033EEA973C20FB5365FCE2170B04`

---

## 6. Báo cáo Trung thực về Hiện trạng Thử nghiệm Thực tế

Tuân thủ nghiêm ngặt nguyên tắc trung thực tuyệt đối trong kỹ thuật:

1. **Phần cứng Camera & Quét QR:**
   - *Đã kiểm thử thực tế:* Logic giải mã QR, token lifecycle, cơ chế countdown làm mới mã, và chức năng chọn ảnh/nhập mã QR giả lập trên máy ảo.
   - *Giới hạn thiết bị thật:* Thao tác quét camera trực tiếp cần được mở trên điện thoại Android vật lý có cấp quyền `android.permission.CAMERA`. Khi chạy trên môi trường không có camera vật lý, app cung cấp nút hỗ trợ nhập mã kiểm thử để đánh giá luồng.
2. **Định vị GPS:**
   - *Đã kiểm thử thực tế:* Toàn bộ thuật toán Haversine và validation tọa độ máy chủ được kiểm thử với các điểm thực tế tại TP. Hồ Chí Minh.
   - *Giới hạn thiết bị thật:* Trên máy ảo Android/PC, tọa độ GPS phụ thuộc vào Location mô phỏng của giả lập (VD: tọa độ mặc định Googleplex). Để test điểm danh thành công ngoài đời, giảng viên cần cấu hình tọa độ lớp học gần với vị trí của thiết bị, hoặc bật chế độ thử nghiệm.
3. **Nhận diện Khuôn mặt & Chống Giả mạo (Anti-Spoofing):**
   - *Đã kiểm thử thực tế:* Đăng ký mẫu khuôn mặt, trích xuất đặc trưng vector 128 chiều chuẩn hóa, đối chiếu Cosine với ngưỡng chấp nhận 0.60, kiểm tra điều kiện ảnh sáng/tương phản.
   - *Giới hạn thiết bị thật:* Hệ thống sử dụng giải pháp phân tích đặc trưng 2D cục bộ kết hợp lọc chất lượng ảnh; chưa tích hợp cảm biến 3D Structured Light hoặc thuật toán quét chuyển động mí mắt/đầu thời gian thực nên mức độ chống ảnh in màu ở mức cơ bản. Luôn cung cấp luồng dự phòng Đăng nhập bằng Mật khẩu + OTP.
4. **Hạ tầng Mạng & Database:**
   - Cơ sở dữ liệu PostgreSQL 18 chạy độc lập, an toàn và lưu trữ bền vững.
   - Sẵn sàng tích hợp Conveyor để mở cổng cho các điện thoại trong mạng LAN kết nối tới backend máy phát triển.
