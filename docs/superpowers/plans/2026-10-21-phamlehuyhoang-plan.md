# Kế hoạch dự án phamlehuyhoang

Ngày cập nhật: 21/10/2026.

Tiến độ sửa các lỗi lớn đã được người dùng duyệt: [MAJOR_FIX_PROGRESS.md](../../MAJOR_FIX_PROGRESS.md). Kết quả kiểm chứng hiện tại: [VERIFICATION.md](../../VERIFICATION.md). Các ô yêu cầu dưới đây không thay thế bằng chứng kiểm thử Gmail/thiết bị thật.

## 1. Mục tiêu và phạm vi đã chốt

Xây dựng ứng dụng di động điểm danh sinh viên theo hình thức **bài tập cá nhân** của Phạm Lê Huy Hoàng. Công nghệ đã chốt: Flutter cho mobile, PostgreSQL cho dữ liệu; ASP.NET Core WebAPI được chọn để triển khai với Conveyor trong môi trường Visual Studio. Conveyor cung cấp đường truy cập tới API, không thay thế mã nguồn WebAPI.

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
- [x] Chốt Flutter + ASP.NET Core WebAPI + PostgreSQL; dùng Conveyor để điện thoại truy cập API.
- [ ] Kiểm tra phiên bản SDK, PostgreSQL, Conveyor và môi trường chạy thực tế.
- [ ] Ghi nhận giả định cho các điểm chưa có xác nhận ở mục 7, triển khai theo mặc định tại mục 9 mà không dừng hỏi người dùng.
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

## 7. Các điểm liên quan cách chấm cần ghi nhận

- Ba chức năng a, b, e có phù hợp danh sách đã thuyết trình của cá nhân không.
- Cách kết hợp khuôn mặt với OTP và tiêu chí thầy chấp nhận cho đăng nhập bằng khuôn mặt.
- Quy định vắng, đi muộn, có phép và ngưỡng chuyên cần của lớp mẫu.
- Tiêu chí công nhận tính năng mới so với ứng dụng tham chiếu.
- Cách tính điểm vì các số ghi trong đề hiện cộng thành 11.
- Yêu cầu repo public/private khi nộp bài; hiện repo là Private.

Mã nguồn đã được triển khai; trạng thái kiểm chứng thực tế xem `docs/VERIFICATION.md`. Theo chỉ đạo tại mục 9 và 10, các điểm chưa có xác nhận không chặn việc code; dùng giả định được ghi lại và không bật xác thực giả.

## 8. Chiến lược hoàn thiện nhanh trước hạn nộp

### Hạn nộp và nguyên tắc ưu tiên

- Hạn nộp: **20:00 ngày 21/10/2026, giờ Việt Nam (UTC+7)**.
- Người dùng yêu cầu ưu tiên hoàn thiện nhanh và cho phép tận dụng repository Flutter có sẵn hoặc thư viện hỗ trợ.
- Ưu tiên sử dụng thư viện, mô hình được huấn luyện sẵn và ví dụ chính thức; phần nghiệp vụ điểm danh, dữ liệu, API, phân quyền và giao diện tích hợp được triển khai cho bài cá nhân này.
- Giữ đủ các yêu cầu đã chọn: đăng ký email, đăng nhập mật khẩu + OTP, phân quyền, CRUD, QR, vị trí, đăng nhập khuôn mặt và dự báo chuyên cần.
- Hạn chế thời gian cho hoạt ảnh, bộ nhận diện thương hiệu, bản đồ tương tác và các tiện ích ngoài đề. Vị trí có thể hiển thị tọa độ/khoảng cách mà không cần tích hợp bản đồ.
- Không thêm chat, gọi video, thanh toán hoặc các chức năng ngoài phạm vi đã chốt.

### Cách tận dụng mã nguồn có sẵn

- [ ] Chỉ khảo sát starter/template hoặc ví dụ trực tiếp phục vụ chức năng cần làm; giới hạn bước chọn nền tảng để tránh mất thời gian đọc và sửa một app lớn.
- [ ] Có thể dùng starter Flutter chung khi giấy phép cho phép và build được trên SDK hiện có; không lấy nguyên một app điểm danh rồi chỉ đổi tên, màu và logo.
- [ ] Nếu một repo không build được hoặc kéo theo backend/dịch vụ khó cấu hình ở bước thử ban đầu, chuyển sang project Flutter tối giản và thư viện đã chọn.
- [ ] Ghi nguồn, phiên bản/commit và giấy phép của phần tái sử dụng trong `THIRD_PARTY_NOTICES.md`; giữ thông báo bản quyền theo giấy phép.
- [ ] Không đưa khóa API, mật khẩu email, dữ liệu khuôn mặt thật hoặc cơ sở dữ liệu chứa thông tin cá nhân lên repo.
- [ ] Giữ tên project mobile, WebAPI và cơ sở dữ liệu là `phamlehuyhoang`; các thư mục con có thể phân biệt bằng `mobile/` và `api/`.
- [ ] Trình bày rõ phần sử dụng thư viện và phần tự triển khai trong báo cáo.

Điều kiện của đề: source giống nhau có thể bị rớt môn. Giấy phép mã nguồn mở không tự thay thế yêu cầu về tính độc lập của bài tập; việc dùng starter cần tránh làm bài nộp trùng ứng dụng mẫu.

### Thư viện và nguồn kỹ thuật ưu tiên

Các lựa chọn sau đã được đối chiếu tài liệu vào ngày 21/10/2026; chưa được cài hoặc xác nhận tương thích trong project. Chốt phiên bản sau khi build thử và lưu lockfile.

| Chức năng | Nguồn ưu tiên | Phạm vi sử dụng |
| --- | --- | --- |
| Quét QR | [mobile_scanner](https://pub.dev/packages/mobile_scanner) | Quét mã bằng camera; API vẫn phải xác thực nội dung, thời hạn và quyền |
| Hiển thị QR | [qr_flutter](https://pub.dev/packages/qr_flutter) | Hiển thị mã phiên điểm danh do API cấp |
| Vị trí | [geolocator](https://pub.dev/packages/geolocator) | Xin quyền và lấy vị trí/độ chính xác; API tính và kiểm tra khoảng cách |
| Chụp khuôn mặt | [camera, publisher flutter.dev](https://pub.dev/packages/camera) | Xem trước camera và chụp ảnh phục vụ đăng ký/đối chiếu |
| Đối chiếu khuôn mặt | [OpenCV FaceDetectorYN/FaceRecognizerSF với YuNet và SFace](https://docs.opencv.org/4.x/d0/dd4/tutorial_dnn_face.html) | Phương án thử đầu tiên với mô hình có sẵn, không tự huấn luyện từ đầu; chọn cách tích hợp sau khi thử môi trường |
| Phát hiện mặt, nếu cần | [Google ML Kit Face Detection](https://developers.google.com/ml-kit/vision/face-detection) | Chỉ hỗ trợ phát hiện mặt/đặc trưng; không coi là chức năng nhận diện danh tính |

- [ ] Kiểm tra giấy phép riêng của mã thư viện và trọng số mô hình trước khi đưa vào bài.
- [ ] Thử đăng ký và đối chiếu cùng người/khác người trước khi hoàn thiện màn hình khuôn mặt.
- [ ] Không dùng kết quả phát hiện mặt, so khớp ảnh đơn giản hoặc xác thực sinh trắc học của thiết bị để tuyên bố đã nhận diện đúng tài khoản.
- [ ] Phân biệt rõ đối chiếu danh tính với kiểm tra người thật; không tuyên bố chống ảnh/video giả mạo nếu chưa có kiểm chứng.
- [ ] Nếu SFace không tích hợp được trong bước thử sớm, báo ngay trở ngại và đánh giá thư viện/mô hình đối chiếu khác; không âm thầm thay chức năng bằng mô phỏng.

### Mục tiêu nền tảng và các điều kiện phải kiểm tra sớm

- Mobile: **Flutter, ưu tiên Android và một thiết bị mục tiêu** để sớm có APK chạy được.
- Máy hiện có lệnh Flutter/Dart, .NET, Python và Node; việc thấy executable chưa chứng minh SDK hoặc mọi dependency hoạt động.
- WebAPI: ASP.NET Core; database bắt buộc PostgreSQL qua EF Core/Npgsql. Conveyor cung cấp URL truy cập API cho điện thoại. Không tự đổi sang SQLite, SQL Server, Firebase hoặc Supabase.
- Ưu tiên một API và một cơ sở dữ liệu; không tự nạp tài khoản/lớp demo. Cơ chế phân quyền và kiểm tra điểm danh đặt ở API.
- Email OTP: xác nhận sớm dịch vụ gửi email/SMTP và cấu hình bằng biến môi trường. Luồng gửi thật phải được thử trước khi đánh dấu hoàn thành.
- Không có OTP dev hoặc cơ chế bỏ qua xác thực: không trả mã về API, không ghi mã trong log, không tự điền hoặc hiện mã trên app, kể cả Development.
- Thử kết nối điện thoại tới API sớm; kiểm tra địa chỉ LAN/cấu hình mạng, camera, vị trí và vòng đời ứng dụng.
- Không coi việc chạy trên trình duyệt hoặc build APK thành công là đã kiểm thử QR/GPS/khuôn mặt trên điện thoại.

### Bộ bàn giao trước hạn

- [ ] Source Flutter, WebAPI và tài liệu trong repository `phamlehuyhoang`.
- [ ] APK Android đã cài và chạy thử trên thiết bị mục tiêu.
- [ ] Script tạo/migrate dữ liệu và dữ liệu mẫu cho cơ sở dữ liệu `phamlehuyhoang`.
- [ ] Hướng dẫn tạo tài khoản và cấp vai trò thực tế; dữ liệu giả chỉ dùng trong bộ test.
- [ ] README hướng dẫn chạy API, cấu hình URL từ điện thoại, email, mô hình khuôn mặt và build/cài APK.
- [ ] File cấu hình mẫu không chứa bí mật và `THIRD_PARTY_NOTICES.md`.
- [ ] Kịch bản trình diễn đủ yêu cầu, ảnh/video nếu môn học yêu cầu và danh sách giới hạn thực tế.
- [ ] Đối chiếu yêu cầu cách nộp và quyền truy cập repo để thầy xem được bài.

Kế hoạch không phân bổ khung giờ cho từng mục tiêu. Checklist chức năng chỉ được tích khi đã thực hiện và kiểm tra đạt.

## 9. Chỉ đạo triển khai tự chủ cho Antigravity

- Người dùng yêu cầu Antigravity đọc plan và triển khai xuyên suốt, không hỏi thêm, không dừng ở giai đoạn tư vấn hoặc chờ duyệt thiết kế.
- Thực hiện trực tiếp trong phiên Antigravity; tự chọn các chi tiết còn thiếu và ghi vào `docs/DECISIONS.md`.
- Không chia giờ hoặc tạo bảng phân bổ thời gian cho từng mục tiêu.
- Đọc và thực thi [prompt master](../../prompts/ANTIGRAVITY_MASTER_PROMPT.md), sau đó code, chạy thử, sửa lỗi, build và bàn giao.

### Stack và cấu trúc bắt buộc

- Flutter Android: `mobile/phamlehuyhoang/`, trường `name: phamlehuyhoang` trong pubspec.
- ASP.NET Core WebAPI: `api/phamlehuyhoang/phamlehuyhoang.csproj`; chọn .NET ổn định đang có, khớp major EF Core và Npgsql.
- PostgreSQL: database `phamlehuyhoang`, EF Core migrations, script dựng dữ liệu và seed có thể chạy lại.
- Conveyor: đường truy cập API từ thiết bị; URL cấu hình được qua `API_BASE_URL`, không hardcode URL tunnel.
- Ưu tiên một WebAPI chính; nếu cần tiến trình phụ đối chiếu khuôn mặt, chỉ cho API gọi nội bộ, không mở nó trực tiếp ra Internet.

### Mặc định nghiệp vụ để không phải hỏi lại

- Đăng ký công khai chỉ tạo vai trò sinh viên; admin quản lý giảng viên và phân công lớp.
- Đăng nhập mật khẩu hoặc đối chiếu khuôn mặt đều phải hoàn tất OTP trước khi nhận phiên đăng nhập đầy đủ.
- OTP mặc định 6 chữ số, hạn 5 phút, tối đa 5 lần thử, chờ 60 giây để gửi lại; cấu hình được và kiểm tra ở API.
- Giảng viên đặt địa điểm lớp, bán kính mặc định 100 m; mẫu vị trí không quá 60 giây và độ chính xác không quá 50 m; cấu hình được.
- QR có hạn mặc định 60 giây, cho phép làm mới khi phiên còn mở; đóng phiên vô hiệu mã ngay.
- Khi chốt buổi, sinh viên chưa điểm danh được ghi vắng; có mặt/đi muộn tính tham dự, vắng có phép không tính vào số vắng bị tính theo chính sách mặc định.
- Lớp cấu hình số buổi `N` và số buổi tối đa được vắng `L`; dữ liệu mẫu dùng `N=15, L=3`. Dự báo dùng công thức mục 4.
- Thời gian lưu UTC; hiển thị giờ Việt Nam. Tên project/API/database giữ nguyên `phamlehuyhoang`.

### Giới hạn tự chủ và bàn giao trung thực

- Tự xử lý lỗi và tiếp tục các phần không bị chặn; không gửi câu hỏi hoặc yêu cầu xác nhận cho các lựa chọn đã được giao.
- Không xóa dữ liệu có sẵn, không force-push và không đưa bí mật hay dữ liệu sinh trắc học thật vào Git.
- Nếu thiếu thông tin đăng nhập SMTP/PostgreSQL, quyền cài đặt hoặc quyền thao tác Conveyor, dùng cấu hình sẵn có hợp lệ trong dự án/môi trường; không bịa thông tin hoặc vượt quyền.
- Nếu vẫn bị chặn, hoàn thành các phần còn lại, ghi rõ hạng mục chưa kiểm thử và lệnh/bước cấu hình còn thiếu khi bàn giao; không đánh dấu hoàn thành giả.

## 10. Xác thực email thật và loại bỏ cơ chế vào nhanh

Chỉ đạo mới của người dùng: đăng ký nhận OTP kích hoạt; khi đăng nhập vẫn phải nhận và nhập OTP mới. Không cung cấp tài khoản thử nghiệm nhanh, OTP dev, tự điền mã hoặc fallback giả gửi thư.

- Đăng ký tạo tài khoản chưa xác minh; OTP kích hoạt chỉ xác minh email và không cấp phiên.
- Đăng nhập mật khẩu/khuôn mặt với tài khoản đã kích hoạt tạo challenge OTP đăng nhập riêng.
- Tài khoản cũ chưa xác minh phải kích hoạt email trước; không mặc định đã xác minh do có dữ liệu cũ.
- Thiếu/lỗi SMTP phải trả lỗi gửi thư (HTTP 503), không nói đã gửi hoặc cấp challenge dùng được.
- Không tự seed tài khoản/lớp mẫu; không xóa người dùng/lịch sử hiện có. Bootstrap admin từ cấu hình riêng vẫn cần xác minh email.
- OTP được lưu dạng băm, giới hạn thử/gửi lại và không dùng chéo mục đích.
- Hướng dẫn cấu hình Gmail tại [EMAIL_SETUP.md](../../EMAIL_SETUP.md); script `scripts/Configure-Email.ps1` lưu cấu hình riêng đã được gitignore.
- Đã triển khai code và kiểm tra bằng test, nhưng môi trường chưa có SMTP gửi thật; chưa được đánh dấu hoàn thành kiểm chứng thư đến Gmail.

