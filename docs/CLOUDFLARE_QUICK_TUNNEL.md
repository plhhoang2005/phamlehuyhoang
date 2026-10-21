# Cloudflare Quick Tunnel cho phamlehuyhoang

## Chạy

Giữ PostgreSQL và WebAPI hoạt động. Tại thư mục repository:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/Start-Backend.ps1
```

Mở terminal khác:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/Start-Cloudflare.ps1
```

Script kiểm tra API tại http://127.0.0.1:5000/health rồi chạy cloudflared nền, ẩn cửa sổ helper. Client portable chính thức phiên bản 2026.10.2 được lưu trong .local/tools, kiểm tra SHA256 trước khi thực thi; không cần cài dịch vụ Windows hoặc tài khoản Cloudflare. Nếu tunnel của project đang chạy, script trả lại URL hiện có thay vì tạo tunnel mới.

URL, PID, thời điểm tiến trình bắt đầu và đường dẫn log nằm trong `.local/quick-tunnel.json` đã được gitignore. Đọc URL đang dùng:

```powershell
(Get-Content .local/quick-tunnel.json -Raw | ConvertFrom-Json).Url
```

## Cấu hình ứng dụng

Màn hình Đăng nhập → bánh răng Cài đặt máy chủ → dán URL HTTPS được script in ra → Lưu. Chỉ nhập URL gốc, không thêm /api, /health hay /swagger. Không cần build lại APK.

Trên máy hoặc điện thoại khác, mở URL đó thêm `/health`; phải nhận JSON có `status: Healthy` và `service: phamlehuyhoang.WebAPI`. Trang gốc không có giao diện web; HTTP 404 tại `/` không có nghĩa API đã dừng.

## Dừng

```powershell
powershell -ExecutionPolicy Bypass -File scripts/Stop-Cloudflare.ps1
```

Script chỉ dừng tiến trình khớp PID, executable và thời điểm khởi động đã lưu của project; không dừng các tunnel khác. WebAPI và PostgreSQL vẫn chạy.

## Điều kiện để giữ kết nối

- Máy tính có mạng và không tắt/ngủ; WebAPI, PostgreSQL và cloudflared vẫn chạy.
- Tunnel đã mở chạy nền và không phụ thuộc cửa sổ terminal bật tunnel. API hiện chạy riêng, cần giữ tiến trình API hoạt động.
- Không tự khởi động sau khi reboot. Chạy lại backend rồi script tunnel sau khi bật máy.
- URL thay đổi khi tạo Quick Tunnel mới. Phải cập nhật URL trong app và gửi lại cho người kiểm tra. Không đưa URL tạm vào mặc định của mã nguồn/APK.
- SMTP là cấu hình độc lập. Tunnel không thay thế tài khoản gửi OTP; xem [EMAIL_SETUP.md](EMAIL_SETUP.md).
- Quick Tunnel công khai API qua HTTPS. Các API nghiệp vụ vẫn yêu cầu xác thực/phân quyền của ứng dụng.

Theo [tài liệu Cloudflare](https://developers.cloudflare.com/tunnel/get-started/quick-tunnels/), Quick Tunnel dành cho thử nghiệm/phát triển, không có cam kết uptime và dừng truy cập khi cloudflared dừng. Đây không phải dịch vụ lưu trữ API độc lập với máy tính.

## Kiểm chứng triển khai ngày 21/10/2026

- Cloudflared 2026.10.2 được tải từ kho phát hành chính thức Cloudflare; SHA256: `12C7C887F8AAAB779AEF1DFA9B60673530A5ADB88ECC55DD6DF8F56E0B70F199`.
- URL HTTPS thực tế đã trả HTTP 200 với JSON Healthy.
- GET /api/users qua tunnel không có JWT trả HTTP 401 như dự kiến.
- Chạy lại Start-Cloudflare.ps1 đã tái sử dụng đúng tiến trình và URL đang chạy.
- Chưa cấu hình SMTP/BootstrapAdmin thật tại thời điểm kiểm tra; chưa chứng minh luồng OTP hoạt động qua tunnel.
