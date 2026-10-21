using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;
using phamlehuyhoang.Data;
using phamlehuyhoang.Services;

var builder = WebApplication.CreateBuilder(args);

// Đọc file cấu hình môi trường local nếu có
if (builder.Environment.IsDevelopment())
{
    var localSettings = Path.GetFullPath(Path.Combine(builder.Environment.ContentRootPath, "../../.local/api-settings.json"));
    if (File.Exists(localSettings))
    {
        builder.Configuration.AddJsonFile(localSettings, optional: true, reloadOnChange: false);
    }
}
builder.Configuration.AddEnvironmentVariables();

// 1. Cấu hình Npgsql PostgreSQL
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? Environment.GetEnvironmentVariable("DATABASE_CONNECTION_STRING")
    ?? "Host=127.0.0.1;Port=54321;Database=phamlehuyhoang;Username=phamlehuyhoang_app;Password=iZzE6paYLNiMTQ5cNx4Me3sNbQ4kyPWRUbtgXZJiDzE=";

builder.Services.AddDbContext<AppDbContext>(options =>
{
    options.UseNpgsql(connectionString);
});

// 2. Đăng ký các dịch vụ Dependency Injection
builder.Services.AddScoped<IEmailService, EmailService>();
builder.Services.AddScoped<IOtpService, OtpService>();
builder.Services.AddScoped<IFaceService, FaceService>();
builder.Services.AddScoped<IAttendanceService, AttendanceService>();
builder.Services.AddScoped<IAuthService, AuthService>();

// 3. Cấu hình JWT Bearer
var jwtSecret = builder.Configuration["Jwt:Secret"] ?? "phamlehuyhoang_SecureJwtSecretKey_2026_DotNet10_AdvancedTokenAuth_123456";
var key = Encoding.UTF8.GetBytes(jwtSecret);

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(key),
        ValidateIssuer = false,
        ValidateAudience = false,
        ClockSkew = TimeSpan.Zero
    };
});

builder.Services.AddAuthorization();

// 4. Cấu hình CORS cho Mobile & Web
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

// 5. Cấu hình Swagger với JWT Bearer
builder.Services.AddSwaggerGen(options =>
{
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        Description = "Nhập JWT token để xác thực"
    });
    options.AddSecurityRequirement(document => new OpenApiSecurityRequirement
    {
        [new OpenApiSecuritySchemeReference("Bearer", document)] = []
    });
});

var app = builder.Build();

// 6. Tự động Migrate và Seed dữ liệu mẫu khi khởi động
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
    try
    {
        logger.LogInformation("Đang kiểm tra và khởi tạo cơ sở dữ liệu PostgreSQL...");
        await DbInitializer.SeedAsync(context);
        logger.LogInformation("Khởi tạo và Seed cơ sở dữ liệu phamlehuyhoang thành công.");
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Lỗi xảy ra trong quá trình Migrate/Seed cơ sở dữ liệu.");
    }
}

app.UseCors("AllowAll");

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/health", () => Results.Ok(new
{
    status = "Healthy",
    service = "phamlehuyhoang.WebAPI",
    timestampUtc = DateTime.UtcNow
}));

app.MapControllers();

app.Run();

public partial class Program;
