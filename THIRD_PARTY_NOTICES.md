# Thông báo bản quyền phần mềm bên thứ ba (Third-Party Notices)

Dự án `phamlehuyhoang` sử dụng các thư viện mã nguồn mở sau đây:

---

## 1. Ứng dụng Di động (Flutter / Dart)

### mobile_scanner
- **Phiên bản:** ^7.4.2
- **Tác giả / Nguồn:** https://pub.dev/packages/mobile_scanner (GitHub: juliansteenbakker/mobile_scanner)
- **Giấy phép:** Apache-2.0
- **Mục đích:** Quét mã QR điểm danh qua camera trên Android/iOS.

### qr_flutter
- **Phiên bản:** ^4.1.0
- **Tác giả / Nguồn:** https://pub.dev/packages/qr_flutter (GitHub: lLuke/qr.flutter)
- **Giấy phép:** BSD-3-Clause
- **Mục đích:** Hiển thị mã QR động theo phiên của Giảng viên.

### geolocator
- **Phiên bản:** ^14.1.2
- **Tác giả / Nguồn:** https://pub.dev/packages/geolocator (Baseflow)
- **Giấy phép:** MIT
- **Mục đích:** Thu thập tọa độ GPS và độ chính xác (accuracy) khi điểm danh.

### camera & image_picker
- **Phiên bản:** camera ^0.12.1, image_picker ^1.2.4
- **Tác giả / Nguồn:** flutter.dev (Google LLC)
- **Giấy phép:** BSD-3-Clause & Apache-2.0
- **Mục đích:** Thu nhận ảnh khuôn mặt phục vụ đăng ký và đối chiếu sinh trắc học.

### http
- **Phiên bản:** ^1.6.0
- **Tác giả / Nguồn:** dart.dev
- **Giấy phép:** BSD-3-Clause
- **Mục đích:** Client gửi nhận HTTP/REST tới WebAPI.

### shared_preferences
- **Phiên bản:** ^2.5.6
- **Tác giả / Nguồn:** flutter.dev
- **Giấy phép:** BSD-3-Clause
- **Mục đích:** Lưu trữ cục bộ JWT token và thông tin phiên đăng nhập.

---

## 2. Máy chủ WebAPI (ASP.NET Core / C# / .NET 10)

### Npgsql.EntityFrameworkCore.PostgreSQL
- **Phiên bản:** 10.0.0
- **Tác giả / Nguồn:** The Npgsql Development Team (https://www.npgsql.org/)
- **Giấy phép:** PostgreSQL License (tương đương MIT / BSD)
- **Mục đích:** Provider ORM EF Core cho cơ sở dữ liệu PostgreSQL 18.

### Microsoft.AspNetCore.Authentication.JwtBearer
- **Phiên bản:** 10.0.8
- **Tác giả / Nguồn:** Microsoft Corporation
- **Giấy phép:** MIT
- **Mục đích:** Middleware xác thực JSON Web Token (JWT).

### MailKit & MimeKit
- **Phiên bản:** 4.18.1
- **Tác giả / Nguồn:** Jeffrey Stedfast (https://github.com/jstedfast/MailKit)
- **Giấy phép:** MIT
- **Mục đích:** Adapter gửi email OTP qua giao thức SMTP.

### SixLabors.ImageSharp
- **Phiên bản:** 3.1.7
- **Tác giả / Nguồn:** Six Labors
- **Giấy phép:** Six Labors Split License (cho phép nghiên cứu giáo dục phi thương mại)
- **Mục đích:** Xử lý và chuẩn hóa ảnh khuôn mặt 112x112 sang vector đặc trưng.

### Swashbuckle.AspNetCore & Microsoft.OpenApi
- **Phiên bản:** Swashbuckle 10.0.1, Microsoft.OpenApi 2.7.5
- **Tác giả / Nguồn:** Domaindrivendev / Microsoft Corporation
- **Giấy phép:** MIT
- **Mục đích:** Tạo tài liệu OpenAPI và giao diện Swagger UI thử nghiệm API.

---

## 3. Thuật toán & Mô hình tham chiếu
- **Công thức Haversine:** Đại số lượng giác hình cầu tính khoảng cách cung tròn lớn giữa hai cặp tọa độ địa lý dựa trên bán kính trái đất R = 6,371,000 m.
- **OpenCV SFace & YuNet Specification:** Tham chiếu chuẩn kích thước chuẩn 112x112 và ngưỡng tương đồng Cosine (Cosine Similarity Threshold = 0.60) cho bài toán đối chiếu 1:1 khuôn mặt.
