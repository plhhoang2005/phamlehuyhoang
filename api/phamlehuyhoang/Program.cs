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
foreach (var name in new[] { "Host", "Port", "User", "Password" })
{
    var value = Environment.GetEnvironmentVariable("SMTP_" + name.ToUpperInvariant());
    if (!string.IsNullOrWhiteSpace(value)) builder.Configuration["Smtp:" + name] = value;
}

// 1. Cấu hình Npgsql PostgreSQL
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? Environment.GetEnvironmentVariable("DATABASE_CONNECTION_STRING")
    ?? throw new InvalidOperationException("Chưa cấu hình kết nối PostgreSQL.");

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
var jwtSecret = builder.Configuration["Jwt:Secret"]
    ?? throw new InvalidOperationException("Chưa cấu hình khóa xác thực Jwt:Secret.");
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
    options.Events = new JwtBearerEvents
    {
        OnTokenValidated = async ctx =>
        {
            var id = ctx.Principal?.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            var db = ctx.HttpContext.RequestServices.GetRequiredService<AppDbContext>();
            var user = Guid.TryParse(id, out var userId)
                ? await db.Users.AsNoTracking().SingleOrDefaultAsync(u => u.Id == userId)
                : null;
            if (!AccountTokenValidator.MatchesCurrentAccount(user, ctx.Principal))
                ctx.Fail("Tài khoản hoặc quyền truy cập đã thay đổi. Vui lòng đăng nhập lại.");
        }
    };
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

// 6. Migrate dữ liệu và khởi tạo quản trị viên thật nếu được cấu hình.
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
    try
    {
        logger.LogInformation("Đang kiểm tra và khởi tạo cơ sở dữ liệu PostgreSQL...");
        await DbInitializer.InitializeAsync(context, builder.Configuration);
        logger.LogInformation("Cơ sở dữ liệu phamlehuyhoang đã sẵn sàng.");
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Lỗi xảy ra trong quá trình khởi tạo cơ sở dữ liệu.");
        throw;
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
