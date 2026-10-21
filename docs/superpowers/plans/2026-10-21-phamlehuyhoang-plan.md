# Kế hoạch dự án phamlehuyhoang

Ngày cập nhật: 21/10/2026.

## 1. Mục tiêu và phạm vi đã chốt

Xây dựng ứng dụng di động điểm danh sinh viên theo hình thức **bài tập cá nhân** của Phạm Lê Huy Hoàng. Đây là kế hoạch phạm vi và lộ trình; công nghệ, cấu trúc mã nguồn và kế hoạch triển khai chi tiết sẽ được chọn sau.

- Tên project ứng dụng: `phamlehuyhoang`.
- Tên project WebAPI: `phamlehuyhoang`.
- Tên cơ sở dữ liệu: `phamlehuyhoang`.
- Một repository GitHub: https://github.com/plhhoang2005/phamlehuyhoang.
- Mã nguồn ứng dụng, WebAPI, tài liệu và script cơ sở dữ liệu được quản lý trong cùng repo.
- Ba chức năng mở rộng đã chọn: **vị trí (b), đăng nhập bằng khuôn mặt (a), QR (e)**.
- Tính năng mới đề xuất: **theo dõi số buổi vắng và dự báo chuyên cần khi vắng buổi tiếp theo**.
- Ưu tiên hoàn thành một quy trình điểm danh xuyên suốt, phù hợp khối lượng của một người.

## 2. Chức năng nền tảng bắt buộc

### Tài khoản

- [ ] Đăng ký tài khoản qua email, kiểm tra email và tên đăng nhập trùng.
- [ ] Thiết kế bước xác minh email khi đăng ký; tách biệt với OTP đăng nhập.
- [ ] Đăng nhập bằng tên đăng nhập + mật khẩu + OTP.
- [ ] OTP có thời hạn, giới hạn thử/gửi lại và chỉ sử dụng một lần.
- [ ] Đăng xuất và xử lý phiên hết hạn.

### Vai trò và quyền truy cập

Một người thực hiện đồ án nhưng ứng dụng vẫn có nhiều vai trò nghiệp vụ:

| Vai trò | Quyền chính |
| --- | --- |
| Quản trị viên | Quản lý tài khoản, môn học, lớp học phần và phân công giảng viên |
| Giảng viên | Quản lý các lớp được giao, buổi học, phiên điểm danh và kết quả |
| Sinh viên | Xem lớp của mình, điểm danh, xem lịch sử và dự báo chuyên cần |

- [ ] Điều hướng đúng màn hình theo vai trò.
- [ ] Kiểm tra quyền tại API, bao gồm quyền trên từng lớp/buổi học.
- [ ] Sinh viên không tự cấp quyền quản trị hoặc sửa kết quả điểm danh.

### CRUD

- [ ] Môn học.
- [ ] Lớp học phần.
- [ ] Thành viên lớp và phân công giảng viên.
- [ ] Buổi học và phiên điểm danh.
- [ ] Tài khoản theo quyền quản trị.
- [ ] Xem và điều chỉnh kết quả điểm danh theo quyền; lưu lý do và lịch sử sửa.

Quy tắc dữ liệu: không thêm trùng sinh viên vào lớp; không tạo hai kết quả cho cùng sinh viên trong cùng buổi. Với dữ liệu đã có lịch sử điểm danh, xác định cách lưu trữ/ngừng sử dụng thay vì xóa dây chuyền làm mất lịch sử.

## 3. Ba chức năng mở rộng đã chọn

### 3.1. Vị trí khi điểm danh — mục b

**Yêu cầu đã chọn:** Gửi vị trí khi điểm danh, kiểm tra khoảng cách tới địa điểm học.

- [ ] Giảng viên thiết lập địa điểm và bán kính chấp nhận cho buổi học.
- [ ] Sinh viên cấp quyền vị trí và gửi vị trí hiện tại khi điểm danh.
- [ ] API tính khoảng cách và kiểm tra điều kiện; không tin kết luận trong/ngoài vùng do client tự gửi.
- [ ] Hiển thị kết quả trong vùng/ngoài vùng và hướng dẫn khi chưa lấy được vị trí.
- [ ] Xử lý từ chối quyền, tắt định vị, vị trí cũ và độ chính xác không phù hợp.
- [ ] Chỉ thu thập vị trí phục vụ thao tác điểm danh, không yêu cầu theo dõi liên tục.

**Nghiệm thu:** Trong vùng và đủ các điều kiện còn lại thì ghi nhận thành công; ngoài vùng hoặc dữ liệu vị trí không hợp lệ thì không ghi nhận và có thông báo rõ ràng. Không tuyên bố GPS loại bỏ hoàn toàn gian lận vị trí.

### 3.2. QR theo buổi học — mục e

**Yêu cầu đã chọn:** Giảng viên mở mã theo buổi; sinh viên quét để tham gia điểm danh.

- [ ] Giảng viên mở/đóng phiên điểm danh cho buổi thuộc lớp được phân công.
- [ ] Tạo QR gắn với phiên, có thời hạn; mã QR không chứa bí mật tài khoản.
- [ ] Sinh viên quét QR bằng camera.
- [ ] API kiểm tra mã, hạn sử dụng, trạng thái phiên, tư cách thành viên lớp và điều kiện vị trí.
- [ ] Ghi nhận một kết quả duy nhất cho mỗi sinh viên/buổi, kể cả khi bấm lại hoặc gửi đồng thời.

**Nghiệm thu:** Quét đúng mã của phiên đang mở thì được xét điểm danh; mã sai, hết hạn, phiên đã đóng hoặc sinh viên ngoài lớp bị từ chối. QR đã quét lại không tạo kết quả thứ hai.

### 3.3. Đăng nhập bằng khuôn mặt — mục a

**Yêu cầu đã chọn:** Đăng nhập bằng cách đối chiếu với khuôn mặt đã đăng ký.

- [ ] Thiết lập luồng đăng ký khuôn mặt khi người dùng đã xác thực tài khoản.
- [ ] Gắn dữ liệu khuôn mặt với đúng tài khoản và giới hạn quyền truy cập.
- [ ] Thu nhận khuôn mặt ở màn hình đăng nhập và đối chiếu với mẫu đã đăng ký.
- [ ] Xử lý không có mặt, nhiều khuôn mặt, thiếu sáng và không khớp.
- [ ] Thử nghiệm biện pháp chống dùng ảnh/video giả mạo; ghi nhận giới hạn của giải pháp.
- [ ] Có đường quay về đăng nhập tên đăng nhập + mật khẩu + OTP khi camera hoặc đối chiếu thất bại.
- [ ] Xác định cách kết hợp OTP trong luồng khuôn mặt theo yêu cầu của thầy; không tự loại bỏ yêu cầu OTP gốc.

**Nghiệm thu:** Người đã đăng ký có thể đăng nhập bằng đối chiếu khuôn mặt theo luồng xác thực đã thống nhất; người không khớp không được đăng nhập. Phát hiện có khuôn mặt hoặc gọi sinh trắc học của điện thoại không mặc nhiên thay thế việc đối chiếu khuôn mặt với tài khoản.

## 4. Tính năng mới đề xuất: theo dõi và dự báo chuyên cần

**Yêu cầu đã chọn:** Sinh viên xem được số buổi đã vắng, còn được vắng bao nhiêu theo quy định của lớp, và nếu vắng buổi tiếp theo thì tỷ lệ chuyên cần thay đổi thế nào.

### Nội dung hiển thị

- [ ] Số buổi đã có kết quả và số buổi vắng.
- [ ] Giới hạn số buổi được vắng theo quy định lớp.
- [ ] Số buổi còn có thể vắng mà chưa vượt giới hạn.
- [ ] Tỷ lệ chuyên cần hiện tại.
- [ ] Tỷ lệ chuyên cần dự kiến nếu vắng thêm buổi tiếp theo.
- [ ] Cảnh báo đạt/vượt giới hạn, kèm số liệu giải thích.

### Quy tắc tính dự kiến

Đề xuất mặc định để chốt trước khi viết code:

- `N`: tổng số buổi chính thức của lớp, không gồm buổi bị hủy.
- `M`: số buổi đã chốt kết quả cho sinh viên; không gồm buổi tương lai hoặc kết quả đang chờ.
- `A`: số buổi bị tính vắng theo quy định lớp trong `M` buổi.
- `L`: số buổi được phép vắng tối đa theo quy định lớp, với `0 <= L <= N`.
- Chuyên cần hiện tại: `(M - A) / M × 100%`, khi `M > 0`.
- Nếu còn buổi học tiếp theo: chuyên cần sau khi vắng buổi đó là `(M - A) / (M + 1) × 100%`.
- Số buổi còn có thể vắng: `min(N - M, max(0, L - A))`, với dữ liệu hợp lệ `0 <= A <= M <= N`.
- Nếu `A > L`, hiển thị rõ đã vượt giới hạn; không chỉ hiển thị số 0.
- Khi `M = 0`, hiển thị chưa có dữ liệu, không chia cho 0 và không kết luận là 0% chuyên cần.
- Khi `M = N`, không hiển thị giả định vắng buổi tiếp theo.
- Đi muộn, vắng có phép, buổi học bù và cách chuyển ngưỡng phần trăm sang số buổi phải có quy tắc rõ trước khi triển khai; không ngầm coi tất cả trạng thái đều là vắng.

**Ví dụ nghiệm thu:** Lớp có `N = 15`, cho phép vắng tối đa `L = 3`; đã chốt `M = 8` buổi, sinh viên vắng `A = 2`. Hiển thị còn được vắng 1 buổi, chuyên cần hiện tại 75%; nếu vắng buổi tiếp theo thì chuyên cần là khoảng 66,67%.

Đây là tính năng mới **đề xuất cho đồ án**. Cần đối chiếu các ứng dụng tham chiếu và xác nhận với thầy; chưa khẳng định chưa có ứng dụng nào trên thị trường triển khai.

## 5. Luồng trình diễn chính

1. Quản trị viên tạo lớp, phân công giảng viên và thêm sinh viên.
2. Người dùng đăng ký/đăng nhập, hoàn tất các bước xác thực và vào đúng màn hình vai trò.
3. Sinh viên đăng ký khuôn mặt và trình diễn đăng nhập bằng khuôn mặt.
4. Giảng viên tạo buổi học, đặt địa điểm/bán kính và mở QR điểm danh.
5. Sinh viên đăng nhập, quét QR và gửi vị trí.
6. API kiểm tra quyền, mã QR, vị trí, phiên và chống ghi trùng trước khi lưu kết quả.
7. Giảng viên xem, chốt kết quả; sinh viên xem lịch sử.
8. Sinh viên mở dự báo chuyên cần để xem số buổi vắng và tác động của việc vắng thêm một buổi.

Đăng nhập bằng khuôn mặt và QR/vị trí là các luồng khác nhau; không mặc định phải quét mặt lại mỗi lần điểm danh.

## 6. Lộ trình thực hiện cho bài cá nhân

- [x] Chốt tên `phamlehuyhoang` và tạo một repository GitHub.
- [x] Chốt ba chức năng mở rộng và tính năng mới đề xuất.
- [x] Ghi lại phạm vi bài cá nhân vào kế hoạch.
- [ ] Chốt nền tảng mobile, công nghệ WebAPI, cơ sở dữ liệu và môi trường chạy.
- [ ] Xác nhận các điểm liên quan cách chấm ở mục 7.
- [ ] Thử khả thi đối chiếu khuôn mặt và camera trên thiết bị mục tiêu trước khi xây dựng toàn bộ.
- [ ] Thiết kế màn hình, dữ liệu, hợp đồng API và kế hoạch triển khai chi tiết.
- [ ] Hoàn thành đăng ký, đăng nhập mật khẩu + OTP và phân quyền.
- [ ] Hoàn thành CRUD và luồng buổi học/kết quả điểm danh.
- [ ] Hoàn thành QR, vị trí và kiểm tra điểm danh tại API.
- [ ] Tích hợp đăng nhập bằng khuôn mặt theo phương án đã thử.
- [ ] Hoàn thành thống kê và dự báo chuyên cần.
- [ ] Hoàn thiện giao diện, xử lý lỗi và hướng dẫn cài đặt trên máy khác.
- [ ] Kiểm tra toàn bộ luồng trình diễn với tài khoản của cả ba vai trò.

### Kiểm tra trọng tâm trước khi báo cáo

- [ ] OTP sai, hết hạn và dùng lại bị từ chối.
- [ ] Sinh viên/giảng viên không truy cập được dữ liệu ngoài quyền.
- [ ] QR hết hạn, phiên đóng và yêu cầu điểm danh đồng thời không tạo kết quả sai.
- [ ] Từ chối quyền camera/vị trí và mất mạng không tạo trạng thái thành công giả.
- [ ] Khuôn mặt không khớp không đăng nhập được; báo cáo kết quả thử với ảnh/video giả mạo.
- [ ] Dự báo đúng với ví dụ 15/8/2/3; xử lý chưa có dữ liệu, hết buổi và vượt giới hạn.
- [ ] Hướng dẫn cài đặt, cấu hình mẫu và dữ liệu mẫu đủ để chạy lại trên môi trường khác.

## 7. Những điểm cần xác nhận trước triển khai chi tiết

- Ba chức năng a, b, e có phù hợp danh sách đã thuyết trình của cá nhân không.
- Cách kết hợp khuôn mặt với OTP và tiêu chí thầy chấp nhận cho đăng nhập bằng khuôn mặt.
- Quy định vắng, đi muộn, có phép và ngưỡng chuyên cần của lớp mẫu.
- Tiêu chí công nhận tính năng mới so với ứng dụng tham chiếu.
- Cách tính điểm vì các số ghi trong đề hiện cộng thành 11.
- Yêu cầu repo public/private khi nộp bài; hiện repo là Private.

Chưa triển khai mã nguồn trong bước cập nhật kế hoạch này.
