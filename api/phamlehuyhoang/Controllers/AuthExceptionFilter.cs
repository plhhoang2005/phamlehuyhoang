using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using phamlehuyhoang.Services;

namespace phamlehuyhoang.Controllers;

public sealed class AuthExceptionFilter(ILogger<AuthExceptionFilter> logger) : IExceptionFilter
{
    public void OnException(ExceptionContext context)
    {
        var (status, message) = context.Exception switch
        {
            EmailDeliveryException error => (503, error.Message),
            UnauthorizedAccessException error => (401, error.Message),
            InvalidOperationException error => (400, error.Message),
            _ => (500, "Không thể xử lý yêu cầu xác thực. Vui lòng thử lại sau.")
        };
        if (status == 500) logger.LogError("Xử lý xác thực thất bại ({ErrorType}).", context.Exception.GetType().Name);
        context.Result = new ObjectResult(new { message }) { StatusCode = status };
        context.ExceptionHandled = true;
    }
}
