# Prompt master cho Antigravity — phamlehuyhoang

Sao chép toàn bộ nội dung dưới đây vào Antigravity, hoặc yêu cầu Antigravity đọc file này trong workspace và thực hiện ngay.

---

Bạn là kỹ sư phụ trách triển khai trọn vẹn bài tập cá nhân của Phạm Lê Huy Hoàng. Hãy **đọc kế hoạch, sau đó trực tiếp viết code, chạy thử, sửa lỗi, build và bàn giao** ứng dụng điểm danh sinh viên.

## 1. Ủy quyền thực hiện

Tôi là chủ dự án và đã chốt phạm vi. Tôi yêu cầu:
- Làm xuyên suốt trong phiên hiện tại, không dừng ở đề xuất, phân tích hay skeleton.
- **Không hỏi tôi bất cứ câu hỏi nào trong quá trình làm.** Tự quyết định chi tiết thông thường theo plan và mặc định bên dưới; ghi quyết định vào tài liệu.
- Không yêu cầu tôi duyệt lại thiết kế, kế hoạch, lựa chọn thư viện hoặc từng bước code. Tôi đã yêu cầu tiến hành triển khai.
- Không chia thời gian thành các khung giờ cho từng mục tiêu.
- Tiếp tục xử lý các phần độc lập khi có một phần bị chặn; không coi thiếu một cấu hình là lý do bỏ toàn bộ công việc.
- Không tuyên bố hoàn tất chỉ vì đã tạo file hoặc build thành công. Kiểm tra chức năng thực tế và báo đúng giới hạn.
- Nếu gặp giới hạn quyền, dữ liệu bí mật chưa có, yêu cầu xác thực do nền tảng áp đặt hoặc lỗi môi trường không thể tự giải quyết: không vượt quyền và không bịa kết quả. Làm hết phần còn làm được rồi ghi rõ blocker trong bàn giao cuối. Chỉ đạo không hỏi lại không cho phép né cơ chế an toàn của công cụ.
- Không tự lập lịch chạy sau hoặc nói sẽ tiếp tục ở một phiên khác thay cho thực hiện ngay.
- Hạn nộp được giao: **20:00 ngày 21/10/2026, Asia/Ho_Chi_Minh**. Nếu thời điểm thực hiện đã qua hạn, ghi nhận đúng thực tế và vẫn thực hiện yêu cầu; không giả định còn thời gian.

## 2. Nguồn cần đọc trước khi code

Workspace dự kiến: `D:\Ltdd\phamlehuyhoang`.
Repository: https://github.com/plhhoang2005/phamlehuyhoang.

Đọc theo thứ tự:
1. Hướng dẫn `AGENTS.md` áp dụng cho workspace, nếu có.
2. `README.md`, nếu có.
3. **`docs/superpowers/plans/2026-10-21-phamlehuyhoang-plan.md`** — đọc toàn bộ, gồm mục 9.
4. Cấu hình và mã nguồn có sẵn, kiểm tra trạng thái Git trước khi sửa.

Nếu chưa có checkout Git, lấy repo bằng quyền truy cập đã có. Workspace có thể chỉ chứa bản plan; bảo toàn file có sẵn, đối chiếu với remote trước khi đồng bộ. Không xóa thư mục hoặc ghi đè thay đổi của người dùng để làm sạch workspace. Nếu remote không truy cập được nhưng bản plan local còn, tiếp tục từ bản local và ghi trạng thái đồng bộ.

Ưu tiên quyết định mới nhất của người dùng: **bài cá nhân; tên phamlehuyhoang; Flutter; PostgreSQL; Conveyor; ba chức năng a/b/e và dự báo chuyên cần; tự triển khai không hỏi; không lập bảng chia giờ**. Các mục “cần xác nhận” trong plan là điểm ghi nhận về cách chấm, không phải cổng chờ người dùng.

## 3. Stack và tên bắt buộc

- Flutter/Dart, ưu tiên Android, giao diện tiếng Việt.
- ASP.NET Core WebAPI chạy bằng Visual Studio/Kestrel và được truy cập từ điện thoại qua Conveyor.
- PostgreSQL qua Entity Framework Core và Npgsql.
- **Conveyor là công cụ cung cấp đường truy cập/tunnel tới API, không phải framework backend hoặc cơ sở dữ liệu.**
- Tên ứng dụng/project Flutter: `phamlehuyhoang`.
- Tên file project và assembly WebAPI: `phamlehuyhoang`.
- Tên database chính: `phamlehuyhoang`.
- Chỉ một repo `phamlehuyhoang`; không tạo repo khác.
- Không tự đổi PostgreSQL sang SQLite, SQL Server, Firebase hay Supabase.
- Chọn .NET ổn định có sẵn và còn được hỗ trợ, khớp major EF Core/Npgsql; chọn package Flutter tương thích SDK thực tế rồi giữ lockfile.

Cấu trúc mục tiêu:
```text
mobile/phamlehuyhoang/                 # pubspec name: phamlehuyhoang
api/phamlehuyhoang/phamlehuyhoang.csproj
api/phamlehuyhoang/Migrations/
tests/                                # test API/nghiệp vụ khi phù hợp
database/                             # SQL dựng/migrate/seed không chứa dữ liệu thật
scripts/                              # chạy, kiểm tra, đóng gói bằng PowerShell
docs/DECISIONS.md
docs/SETUP.md
docs/DEMO.md
docs/VERIFICATION.md
docs/HANDOVER.md
THIRD_PARTY_NOTICES.md
README.md
```
Giữ cấu trúc có sẵn nếu đã có code hoạt động; không tái cấu trúc vô ích.

Tài liệu tham chiếu: [Conveyor](https://conveyor.cloud/Help/Setup_remote_connection_Visual_Studio_IIS_Express), [Npgsql EF Core](https://www.npgsql.org/efcore/).


## 4. Mục tiêu sản phẩm

Làm một ứng dụng thật với ba vai trò:
- **Admin:** quản lý tài khoản, môn học, lớp học phần, thành viên và phân công giảng viên.
- **Giảng viên:** quản lý lớp được giao, buổi học, mở/đóng phiên QR, địa điểm/bán kính, xem/chốt/điều chỉnh kết quả có lịch sử.
- **Sinh viên:** đăng ký, đăng nhập, đăng ký khuôn mặt, xem lớp, quét QR + gửi vị trí, lịch sử và dự báo chuyên cần.

Hoàn thành toàn bộ CRUD và luồng trong plan; không chỉ dựng các màn hình chứa dữ liệu tĩnh. Kiểm tra quyền tại API theo cả vai trò và đối tượng, không chỉ ẩn nút trên UI.

Luồng chính: admin tạo lớp → giảng viên mở buổi/phiên QR → sinh viên đăng nhập/quét QR/gửi vị trí → API xét điều kiện và ghi nhận → giảng viên chốt buổi → sinh viên xem lịch sử và dự báo.

## 5. Tài khoản, OTP và phiên đăng nhập

- Đăng ký qua email, username duy nhất, email duy nhất; xác minh email nếu triển khai theo plan.
- Đăng ký công khai luôn là Student; client không được tự chọn Admin/Lecturer.
- Luồng bắt buộc: username + password → tạo challenge OTP → xác nhận OTP → mới cấp phiên truy cập API nghiệp vụ.
- Đăng nhập khuôn mặt: username + ảnh hiện tại → đối chiếu mẫu của đúng tài khoản → OTP → cấp phiên. Dùng đối chiếu 1:1, không cần tìm người trên toàn bộ tập dữ liệu.
- Mật khẩu dùng ASP.NET Core Identity/PasswordHasher hoặc giải pháp chuẩn tương đương; không tự băm yếu, không lưu plaintext.
- OTP 6 chữ số tạo bằng nguồn ngẫu nhiên bảo mật; mặc định 5 phút, tối đa 5 lần thử, gửi lại sau 60 giây. Challenge có purpose/tài khoản, chỉ dùng một lần; gửi lại vô hiệu mã cũ; kiểm tra và tiêu thụ ở API một cách nhất quán.
- Cần kiểm soát tần suất gửi/thử OTP và đối chiếu mặt; không để endpoint gửi email bị lạm dụng.
- Dùng SMTP/provider thật có cấu hình; lấy secret từ env/user-secrets hoặc cấu hình hợp lệ sẵn có trong dự án. Không tìm bí mật ở dự án/tài khoản không liên quan.
- Nếu chưa có thông tin gửi email, hoàn thành email adapter, cấu hình mẫu và test; chế độ dev phải ghi nhãn rõ. Không hiển thị OTP trên app rồi tuyên bố đã gửi email thật.
- Token/challenge trước OTP không được dùng gọi API nghiệp vụ.
- Đăng xuất, hết hạn phiên và lưu token trên thiết bị bằng cơ chế thích hợp; không ghi token vào log.
- Tạo bootstrap admin có kiểm soát; seed chỉ dùng dữ liệu giả cho Development, không mở endpoint nâng quyền công khai.

## 6. QR + vị trí khi điểm danh

- Giảng viên chỉ được mở phiên thuộc lớp được phân công.
- QR chứa mã phiên/challenge ngẫu nhiên hoặc token được bảo vệ, có hạn mặc định 60 giây; có thể làm mới khi phiên mở.
- Đóng phiên phải khiến QR không còn được chấp nhận ngay, kể cả token chưa hết hạn.
- Sinh viên dùng camera quét QR, lấy vị trí tại thao tác điểm danh rồi gửi đến API.
- Bán kính mặc định 100 m, cho phép giảng viên cấu hình; vị trí tối đa 60 giây, độ chính xác tối đa 50 m theo mặc định. Các ngưỡng cấu hình được.
- API kiểm tra tọa độ hữu hạn và đúng miền, thời gian hợp lệ kể cả tương lai bất thường, độ chính xác, mã QR, thành viên lớp, trạng thái phiên, khoảng cách và điều kiện trùng.
- API tự tính khoảng cách, không tin distance/inRange/success do client tự gửi.
- Một sinh viên chỉ có một bản ghi cho một buổi: ràng buộc unique trong PostgreSQL và xử lý transaction/concurrency. Quét/bấm/gửi đồng thời không tạo hai kết quả hoặc lỗi 500.
- Giải phóng/khởi tạo camera đúng khi rời trang hoặc ứng dụng chuyển trạng thái.
- Xử lý không cấp quyền, tắt GPS, timeout/mất mạng, vị trí không đạt; không hiện thành công nếu API chưa lưu.
- Không xin định vị nền nếu không cần. Không tuyên bố GPS chống giả vị trí hoàn toàn.

## 7. Đăng ký và đối chiếu khuôn mặt thực sự

- Chỉ người đã đăng nhập và có quyền mới được tạo/thay mẫu khuôn mặt của chính mình; bảo vệ thao tác thay mẫu phù hợp.
- Ưu tiên camera + mô hình nhận diện đã huấn luyện sẵn, như YuNet/SFace qua OpenCV; kiểm tra nhanh khả năng chạy trên môi trường ngay từ đầu.
- Phải có đối chiếu embedding/đặc trưng nhận dạng thật. ML Kit Face Detection chỉ phát hiện mặt; local_auth xác thực sinh trắc học thiết bị không tự chứng minh ai là sinh viên đã đăng ký.
- Chọn phương án tích hợp đơn giản, chạy được với ASP.NET Core. Nếu cần sidecar Python cho OpenCV, chỉ bind loopback và để WebAPI gọi; tài liệu/scripts phải khởi chạy đủ thành phần. PostgreSQL vẫn là database chính.
- Không tự huấn luyện mô hình từ đầu, không đưa vào project nhiều framework AI cùng lúc nếu không cần.
- Kiểm tra không có mặt, nhiều mặt, ảnh không đọc được, ảnh quá lớn, ảnh mờ/thiếu sáng, không khớp và lỗi mô hình.
- Chọn ngưỡng từ tài liệu rồi kiểm tra cùng người/khác người; ghi kết quả, không copy số accuracy benchmark làm accuracy của app.
- Thử biện pháp người thật nếu khả thi; ghi rõ chống ảnh/video tới mức nào. Không tự nhận đã có liveness hoàn chỉnh khi chỉ so khớp ảnh.
- Lưu và truy cập dữ liệu sinh trắc học có bảo vệ; không xuất mẫu/embedding ra endpoint công khai và không commit ảnh thật hoặc embedding của người thật.
- Có đăng nhập password + OTP dự phòng khi nhận diện/camera lỗi. Không thay chức năng khuôn mặt bằng nút bấm luôn thành công.

## 8. Chuyên cần và quy tắc mặc định

Dùng công thức trong mục 4 của plan:
- N: số buổi chính thức không tính buổi hủy; M: số buổi đã chốt; A: số buổi bị tính vắng; L: số buổi được vắng tối đa.
- Hiện tại: (M-A)/M × 100% nếu M>0.
- Nếu vắng buổi tiếp theo: (M-A)/(M+1) × 100%, chỉ khi M<N.
- Còn có thể vắng: min(N-M, max(0,L-A)).
- M=0 hiện “Chưa có dữ liệu”; A>L hiện rõ vượt giới hạn; M=N không đưa giả định còn buổi tiếp theo.
- Ví dụ bắt buộc: N=15, M=8, A=2, L=3 → còn 1 buổi, hiện tại 75%, nếu vắng tiếp khoảng 66,67%.
- Có mặt/đi muộn tính tham dự theo mặc định; vắng có phép không tăng A. Nêu rõ cách tính và chính sách trên màn hình/tài liệu.
- Khi chốt buổi, sinh viên hợp lệ chưa có kết quả được ghi vắng. Thời điểm tham gia/rời lớp và buổi hủy không được làm báo cáo sai.
- Ngăn sửa N/L thành dữ liệu mâu thuẫn với lịch sử; không silently clamp làm che lỗi dữ liệu.
- Chỉnh kết quả có lịch sử người sửa, thời điểm, lý do; dự báo cập nhật theo dữ liệu chính thức.

## 9. PostgreSQL, API và Conveyor

- EF Core migrations, PostgreSQL constraints/indexes và seed có thể chạy lại; API không dùng dữ liệu in-memory thay database thật.
- Đọc connection string qua env/user-secrets; có file cấu hình mẫu không chứa password thật.
- Kiểm tra PostgreSQL đang có trước. Có thể dùng container local nếu Docker đã sẵn sàng và không đụng dữ liệu cũ. Không reset/drop database hiện hữu để tiện phát triển.
- Dùng tài khoản database tối thiểu đủ quyền theo môi trường; không mở cổng PostgreSQL ra Internet qua Conveyor.
- API hỗ trợ validation, lỗi thống nhất, OpenAPI và health check không lộ secret.
- Lưu thời gian UTC, hiển thị giờ Việt Nam; nhất quán với timestamp của Npgsql.
- Tạo launch profile Visual Studio/Kestrel để Conveyor nhận API theo tài liệu.
- URL API cấu hình bằng `--dart-define=API_BASE_URL=...`; có hướng dẫn thay URL Conveyor khi URL đổi. Mọi request/upload ảnh đều đi qua cấu hình này.
- Kiểm tra API local trước, rồi đường truy cập Conveyor và từ thiết bị nếu công cụ/thiết bị sẵn có.
- Không hardcode URL Conveyor, localhost điện thoại hoặc địa chỉ máy cá nhân vào mã nghiệp vụ.
- Không vô hiệu kiểm tra TLS toàn cục hoặc cài chứng chỉ/root CA âm thầm. Cấu hình HTTPS đúng theo Conveyor; nếu thiếu quyền thao tác UI/chứng chỉ, ghi đúng bước còn thiếu.
- Không đổi hệ thống firewall/mạng rộng hơn nhu cầu để che lỗi kết nối.

## 10. Thư viện, giao diện và phạm vi

Ưu tiên:
- mobile_scanner: quét QR.
- qr_flutter: hiển thị QR.
- geolocator: vị trí.
- camera: chụp khuôn mặt.
- Một HTTP client, một cách quản lý state/router vừa đủ, secure storage phù hợp.
- EF Core/Npgsql và thư viện email/nhận diện cần thiết.

Có thể dùng repo starter hoặc ví dụ chính thức có giấy phép phù hợp. Không sao chép nguyên app điểm danh rồi đổi tên: thầy quy định source giống nhau có thể rớt môn. Ghi nguồn, license, phiên bản/commit, mô hình và phần chỉnh sửa trong THIRD_PARTY_NOTICES.md. Không có license rõ thì không dùng mã đó làm nền.

UI cần thống nhất Material, dễ đọc, dùng được trên điện thoại nhỏ, có loading/empty/error/success, tránh overflow. Dashboard từng vai trò, CRUD và lịch sử/dự báo phải có đường điều hướng thật. Không thêm các tính năng ngoài đề để trì hoãn phần bắt buộc.

## 11. Cách tiến hành ngay

1. Khảo sát repo, SDK Flutter/Android/.NET, PostgreSQL, thiết bị và cấu hình Conveyor/email hiện có. Không dùng việc khảo sát làm điểm dừng.
2. Viết ngắn các quyết định vào docs/DECISIONS.md, tạo checklist triển khai từ plan và tự thực hiện. Không gửi câu hỏi chờ duyệt.
3. Thử sớm build mobile/API, kết nối PostgreSQL, camera/face engine và email; giữ scope đủ đơn giản.
4. Triển khai từng phần có thể kiểm tra: schema/auth/roles → CRUD → phiên/QR/vị trí → khuôn mặt + OTP → dự báo → hoàn thiện UI và tích hợp.
5. Gặp lỗi: đọc nguyên nhân, sửa, chạy lại kiểm tra liên quan; đổi thư viện tương thích khi có căn cứ. Không im lặng bỏ chức năng.
6. Cập nhật checklist trong plan chỉ khi đã có bằng chứng chạy/kiểm tra; giữ nguyên những mục chưa đạt.
7. Rà soát secrets và file build/dữ liệu trước khi commit. Commit các thay đổi đúng phạm vi, push lên repo đã chỉ định nếu có quyền; không force-push, không ghi đè lịch sử hoặc sửa repo khác.
8. Tiếp tục đến khi có bộ bàn giao thực tế. Nếu hết khả năng xử lý blocker bằng quyền/công cụ hiện có, hoàn tất phần còn lại và bàn giao rõ trạng thái.

Nếu dùng skills/workflow, yêu cầu trực tiếp này đã cho phép triển khai và tự chọn chi tiết: không biến các bước duyệt thông thường thành câu hỏi lặp lại. Vẫn tuân thủ cơ chế quyền và giới hạn thực tế của nền tảng.

## 12. Kiểm chứng bắt buộc

Chạy kiểm tra có giá trị và lưu lệnh/kết quả vào docs/VERIFICATION.md:
- flutter analyze; flutter test cho nghiệp vụ/UI quan trọng; flutter build apk.
- dotnet build và dotnet test theo solution/project thực tế.
- Kiểm tra migration và truy vấn với PostgreSQL thật; test không được phá database/dữ liệu có sẵn.
- OTP sai/hết hạn/dùng lại/gửi lại/thử quá giới hạn; trước OTP không truy cập được nghiệp vụ.
- Student không tự nâng quyền; Lecturer không truy cập lớp khác; ID của người khác bị từ chối.
- QR hết hạn/đóng phiên/mã sai, ngoài vùng, sai tọa độ, vị trí cũ, không cấp quyền, timeout.
- Gửi điểm danh trùng/đồng thời và chốt buổi không tạo bản ghi sai.
- Khuôn mặt đăng ký/đăng nhập cùng người, khác người, không có/nhiều mặt và đường fallback.
- Chuyên cần theo ví dụ và các biên M=0, M=N, A>L, buổi hủy/có phép.
- Luồng admin → lecturer → student với dữ liệu thật từ API, và luồng qua Conveyor nếu truy cập được.
- Cài và chạy APK trên thiết bị/emulator mục tiêu nếu có. Nếu không có thiết bị hoặc chưa thao tác camera/GPS thật, đánh dấu chưa kiểm thử; không mô tả test mock thành test thiết bị.

Không cần viết test cho mọi đoạn hiển thị đơn giản; tập trung auth, phân quyền, concurrency, quy tắc điểm danh và công thức.

## 13. Bộ bàn giao cuối cùng

- Source Flutter + ASP.NET Core WebAPI + migrations/scripts PostgreSQL trong repo.
- APK và đường dẫn file thực tế, kèm checksum nếu tạo được.
- README hướng dẫn khởi chạy; .env/config mẫu; scripts phù hợp Windows/PowerShell.
- Tài liệu cấu hình PostgreSQL, SMTP, face model và Conveyor/URL cho điện thoại.
- Dữ liệu/tài khoản mẫu dành riêng môi trường Development, không chứa thông tin thật.
- THIRD_PARTY_NOTICES.md, DECISIONS.md, DEMO.md, VERIFICATION.md, HANDOVER.md.
- Kịch bản trình diễn đủ ba vai trò, QR/GPS, đăng nhập khuôn mặt + OTP và dự báo.
- Tổng kết: đã làm gì; kiểm tra nào pass/fail/chưa chạy; APK ở đâu; commit/push tới đâu; blocker còn lại và bước khắc phục chính xác.
- Không viết “hoàn thiện 100%” nếu còn email, PostgreSQL, nhận diện, Conveyor hoặc test thiết bị chưa chạy thật.

**Bắt đầu đọc plan và thực hiện code ngay. Không trả lời chỉ bằng kế hoạch hoặc yêu cầu tôi xác nhận.**
