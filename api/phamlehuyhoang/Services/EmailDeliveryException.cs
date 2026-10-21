namespace phamlehuyhoang.Services;

public sealed class EmailDeliveryException : InvalidOperationException
{
    public EmailDeliveryException() : base("Máy chủ chưa gửi được email xác thực. Tài khoản chưa thể được xác thực. Vui lòng thử lại sau hoặc liên hệ quản trị viên cấu hình dịch vụ email.") { }
}
