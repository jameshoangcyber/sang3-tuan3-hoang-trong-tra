Mục tiêu bài học:
1.	Sử dụng Identity để cấu hình và Xây dựng API đăng ký, đăng nhập…
2.	Nhúng API lên giao diện di động để thực hiện chức năng đăng ký đăng nhập
3.	Dùng JWT_decode để thực hiện việc giải mã token gửi về từ server để xác định người dùng, vai trò người dùng (quyền), thời gian hiệu lực của token
4.	Dùng flutter_dotenv để quản lý, tách biệt các đầu API khỏi mã nguồn từ đó giúp quản lý các API hiệu quả và dễ dàng hơn (dễ dàng cập nhật đường dẫn API)
5.	Dùng shared_preferences để lưu trữ thông tin vào máy (trong bài hướng dẫn lưu token vào máy và sử dụng token đó để ứng dụng tự động đăng nhập lại)
6.	Tạo và phân quyền  người dùng trong ứng dụng
7.	Đăng nhập tương ứng với từng quyền của người dùng

Tiếp tục bài tuần trước
Bước 1. Tạo class User trong thư mục Model
 
public class User: IdentityUser
{
    public string? Initials { get; set; }
    //User = IdentityUser + string Inititals
}

Bước 2: Cập nhật ApplicationDbContext
public class ApplicationDbContext : IdentityDbContext<User>
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options) { }
        public DbSet<Product> Products { get; set; }
        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);
            builder.Entity<User>().Property(u=>u.Initials).HasMaxLength(5);
            builder.HasDefaultSchema("identity");
        }

    }


Bước 3. Cài đặt thêm các gói cần thiết
‘Microsoft.AspNetCore.Identity.EntityFrameworkCore’ Phiên bản 8.0.3. Đây là gói giúp thực hiện các thao tác: đăng ký, đăng nhập, cập nhật thông tin User, phân quyền, mã hóa mật khẩu….
‘Microsoft.AspNetCore.Authentication.JwtBearer’ Phiên bản 8.0.3. Đây là gói giúp thực tạo các middleware, token chứa các thông tin về tài khoản, quyền…

Bước 4. Cấu hình file Program.cs
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Sang6_WebAPI.Models;
using Sang6_WebAPI.Repositories;
using System.Text;

var builder = WebApplication.CreateBuilder(args);
//Cấu hình: Dùng SQL Server làm hệ quản trị csdl cho ứng dụng
builder.Services.AddDbContext<ApplicationDbContext>(options => options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));


// Add services to the container.

builder.Services.AddControllers(); 
builder.Services.AddScoped<IProductRepository, ProductRepository>();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();


    
    
// Configure CORS: Cross-Origin Resource Sharing, được dịch là “Chia sẻ tài nguyên giữa các nguồn gốc khác nhau
builder.Services.AddCors(options =>
{
    options.AddPolicy(name: "MyAllowOrigins", policy =>
    {
        //Thay bằng địa chỉ localhost khi khởi chạy bên frontend (VSCode)
        policy.WithOrigins("http://127.0.0.1:5500", "http://localhost:5500")
        .AllowAnyHeader()
        .AllowAnyMethod();
    });
});


builder.Services.AddAuthorization();

var app = builder.Build();


// Middleware for production error handling
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/error"); // Custom error handling endpoint
    app.UseHsts(); // Enforce HTTPS in production
}
else
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
// Áp dụng CORS cho các yêu cầu đến API
app.UseCors("MyAllowOrigins");
app.UseAuthentication();
app.UseAuthorization();

app.MapIdentityApi<User>();

app.MapControllers();

app.Run();

Bước 5. Thực hiện add-migration và update-database
 
Sau khi add-migration InitialIdentityModel
 
Thực hiện lệnh update-database để ánh xạ Identity vào cơ sở dữ liệu
Trước khi ánh xạ
 
Sau khi ánh xạ
 

Bước 6. Trong thư mục controller, thêm APIController tên AuthenticateController

  

 

public class AuthenticateController : ControllerBase
{
    private readonly UserManager<User> _userManager;
    private readonly RoleManager<IdentityRole> _roleManager;
    private readonly IConfiguration _configuration;

    public AuthenticateController(
        UserManager<User> userManager,
        RoleManager<IdentityRole> roleManager,
        IConfiguration configuration)
    {
        _userManager = userManager;
        _roleManager = roleManager;
        _configuration = configuration;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegistrationModel model)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var userExists = await _userManager.FindByNameAsync(model.Username);
        if (userExists != null)
            return StatusCode(StatusCodes.Status400BadRequest, new { Status = false, Message = "User already exists" });

        var user = new User
        {
            UserName = model.Username,
            Email = model.Email,
            Initials = model.Initials
        };

        var result = await _userManager.CreateAsync(user, model.Password);
        if (!result.Succeeded)
            return StatusCode(StatusCodes.Status500InternalServerError, new { Status = false, Message = "User creation failed" });

        // Assign Role if Provided
        if (!string.IsNullOrEmpty(model.Role))
        {
            if (!await _roleManager.RoleExistsAsync(model.Role))
            {
                await _roleManager.CreateAsync(new IdentityRole(model.Role));
            }
            await _userManager.AddToRoleAsync(user, model.Role);
        }

        return Ok(new { Status = true, Message = "User created successfully" });
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginModel model)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var user = await _userManager.FindByNameAsync(model.Username);
        if (user == null || !await _userManager.CheckPasswordAsync(user, model.Password))
            return Unauthorized(new { Status = false, Message = "Invalid username or password" });

        var userRoles = await _userManager.GetRolesAsync(user);

        var authClaims = new List<Claim>
    {
        new Claim(ClaimTypes.Name, user.UserName),
        new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
    };

        foreach (var userRole in userRoles)
        {
            authClaims.Add(new Claim(ClaimTypes.Role, userRole));
        }

        var token = GenerateToken(authClaims);
        return Ok(new { Status = true, Message = "Logged in successfully", Token = token });
    }

    
    private string GenerateToken(IEnumerable<Claim> claims)
    {
        var jwtSettings = _configuration.GetSection("JWTKey");
        var authSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSettings["Secret"]));

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = DateTime.UtcNow.AddHours(Convert.ToDouble(jwtSettings["TokenExpiryTimeInHour"])),
            Issuer = jwtSettings["ValidIssuer"],
            Audience = jwtSettings["ValidAudience"],
            SigningCredentials = new SigningCredentials(authSigningKey, SecurityAlgorithms.HmacSha256)
        };

        var tokenHandler = new JwtSecurityTokenHandler();
        var token = tokenHandler.CreateToken(tokenDescriptor);
        return tokenHandler.WriteToken(token);
    }
}
Bước 7. Thêm các Class cần thiết
Chương trình đang báo lỗi tại LoginModel và RegistrationModel, trong thư mục Model thêm hai class có tên trên
 
public class LoginModel
{
    [Required]
    public string Username { get; set; } = string.Empty;
    [Required]
    public string Password { get; set; } = string.Empty;
}

public class RegistrationModel
{
    [Required]
    public string Username { get; set; } = string.Empty;
    [Required, EmailAddress]
    public string Email { get; set; } = string.Empty;
    [Required, MinLength(6)]
    public string Password { get; set; } = string.Empty;
    public string? Initials { get; set; }
    public string? Role { get; set; } // Optional - assign a role if needed
}
   
Bước 8. Cập nhật Programe.cs (Nhớ kiểm tra đã cài đặt gói JwtBearer chưa ???

using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Sang6_WebAPI.Models;
using Sang6_WebAPI.Repositories;
using System.Text;

var builder = WebApplication.CreateBuilder(args);
//Cấu hình: Dùng SQL Server làm hệ quản trị csdl cho ứng dụng
builder.Services.AddDbContext<ApplicationDbContext>(options => options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Register identity
builder.Services.AddIdentity<User, IdentityRole>()
    .AddEntityFrameworkStores<ApplicationDbContext>()
    .AddDefaultTokenProviders();

// Add services to the container.

builder.Services.AddControllers(); 
builder.Services.AddScoped<IProductRepository, ProductRepository>();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();


    
    
// Configure CORS: Cross-Origin Resource Sharing, được dịch là “Chia sẻ tài nguyên giữa các nguồn gốc khác nhau
builder.Services.AddCors(options =>
{
    options.AddPolicy(name: "MyAllowOrigins", policy =>
    {
        //Thay bằng địa chỉ localhost khi khởi chạy bên frontend (VSCode)
        policy.WithOrigins("http://127.0.0.1:5500", "http://localhost:5500")
        .AllowAnyHeader()
        .AllowAnyMethod();
    });
});

//Configure JWT Authentication
var jwtSettings = builder.Configuration.GetSection("JWTKey");
var key = Encoding.UTF8.GetBytes(jwtSettings["Secret"]);

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = "Bearer";
    options.DefaultChallengeScheme = "Bearer";
})
.AddJwtBearer("Bearer", options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtSettings["ValidIssuer"],
        ValidAudience = jwtSettings["ValidAudience"],
        IssuerSigningKey = new SymmetricSecurityKey(key)
    };
});

builder.Services.AddAuthorization();

var app = builder.Build();

//Tạo ra các Role trong ứng dụng để sau này thực hiện phân quyền
using (var scope = app.Services.CreateScope())
{
    var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();
    var roles = new[] { "Admin", "User" };
    foreach (var role in roles)
    {
        if (!await roleManager.RoleExistsAsync(role))
        {
            await roleManager.CreateAsync(new IdentityRole(role));
        }
    }
}

// Middleware for production error handling
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/error"); // Custom error handling endpoint
    app.UseHsts(); // Enforce HTTPS in production
}
else
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
// Áp dụng CORS cho các yêu cầu đến API
app.UseCors("MyAllowOrigins");
app.UseAuthentication();
app.UseAuthorization();

//Người dùng đã tự config Identity user nên bỏ phần này
//app.MapIdentityApi<User>();

app.MapControllers();

app.Run();

Bước 9. Cập nhật lại file appsetting.json
{
  
  //Cấu hình thông tin khóa mã hóa JWT
  "JWTKey": {, 
    "Secret": "AReallyLongSecretKeyForYourJWTTokenSigning!", //Khóa bí mật để khóa và giải khóa token
    "ValidIssuer": "YourIssuer", //Thông tin người phát hành
    "ValidAudience": "YourAudience",//Ứng dụng nhận được token này
    "TokenExpiryTimeInHour": "1"//Thời gian hiệu lực của token
  },
  "ConnectionStrings": {
    "DefaultConnection": "Server=MY-PC\\MRHUNG189;Database=testAPI;Trusted_Connection=True;TrustServerCertificate=True"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}

Bước 10. Debug chương trình và đăng ký tài khoản, đăng nhập
 

Tiến hành đăng ký và đăng nhập thử
{
  "username": "manhhung3",
  "email": "manhhung3@gmail.com",
  "password": "Manhhung@123",
  "initials": "hung3",
  "role": "User"
}
Đăng ký thành công
 
Đăng nhập thành công
 
Bước 11. Giải mã token để lấy thông tin từ token
Tiến hành decode JWT xem mã token trả về gồm những gì bằng cách vào trang https://jwt.io/ để kiểm tra thử đoạn mã token nhận trên
 
Thông tin nhận về khi đăng nhập thành công là một token và bên trong bao gồm các thông tin như: tên đăng nhập, ID của token, thời gian bắt đầu của token, thời gian hết hạn….
Qua bên android studio để tiến hành gắn các API vào trong giao diện
Bước 1. Cài đặt jwt_decoder để giải mã kết quả token trả về
flutter pub add jwt_decoder
Bước 2. 
Nhận thấy một ứng dụng sẽ có rất nhiều đường link dẫn tới các API khác nhau nên việc cấu hình đường dẫn đến API cho từng giao diện rất phức tạp và mất thời gian  tạo ra class để quản lý việc truy cập các API cho dễ dàng (đây không phải là phương pháp bảo mật tốt nhất)
a.	Cài đặt flutter_dotenv: flutter pub add flutter_dotenv
b.	trong thư mục lib tạo thư mục config và file config_url.dart 
 
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config_URL {
  static String get baseUrl {
    final url = dotenv.env['BASE_URL'];
    if (url == null) {
      print("BASE_URL is not set in the .env file. Using default URL.");
      //đường dẫn API nếu không đọc được URL trong file .env
      return "https://longashgrape36.conveyor.cloud/api/";
    }
    return url;
  }
}

c.	tạo file .env (đồng cấp với thư mục lib)và khai báo trong pubspec.yaml
 
Nội dung file .env
//khai báo các đường dẫn tới API, database...
//không upload file này lên github
BASE_URL=https://littlegoldbike52.conveyor.cloud/api/

Khai báo trong pubspec.yaml
 
Bước 3. 
Tạo file auth_service.dart trong thư mục services
	Cấu trúc thư mục lib và file .env trong chương trình
 
class AuthService {
  // đường dẫn tới API login
  String get apiUrl => "${Config_URL.baseUrl}Authenticate/login";

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        //Lấy thông tin tên đăng nhập và password
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        bool status = data['status'];
        if (!status) {
          return {"success": false, "message": data['message']};
        }
        //lấy token trả về
        String token = data['token'];
        // Decode token để lấy các thông tin đăng nhập: tên đăng nhập, role...
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

        // Lưu token vào SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('jwt_token', token);  // Lưu token

        return {
          "success": true,
          "token": token,
          "decodedToken": decodedToken,
        };
      } else {
        // If status code is not 200, treat it as login failure
        return {"success": false, "message": "Failed to login: ${response.statusCode}"};
      }
    } catch (e) {
      // Handle network or parsing errors
      return {"success": false, "message": "Network error: $e"};
    }
  }
}

Bước 4. 
Cập nhật thêm chức năng đăng ký và đăng nhập trong auth.dart

class Auth {
  static final AuthService _authService = AuthService();
  static final ApiClient _apiClient = ApiClient();

  // Đăng nhập
  static Future<Map<String, dynamic>> login(String username, String password) async {
    var result = await _authService.login(username, password);
    return result; // returns a map with {success: bool, token: string?, role: string?, message: string?}
  }

  // Đăng ký tài khoản mới
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String initials,
    required String role,
  }) async {
    // Tạo body để gửi lên API
    Map<String, dynamic> body = {
      "username": username,
      "email": email,
      "password": password,
      "initials": initials,
      "role": role,
    };

    // Gọi API đăng ký thông qua ApiClient
    try {
      var response = await _apiClient.post('Authenticate/register', body: body);

      // Xử lý kết quả từ API
      if (response.statusCode == 200) {
        // Chuyển đổi body JSON từ API thành Map
        var result = jsonDecode(response.body);
        return result;
      } else {
        return {
          'success': false,
          'message': 'Đăng ký thất bại, vui lòng thử lại.'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}'
      };
    }
  }
}


Bước 5. 
Tạo class api_client trong thư mục services gọi các giao thức của API (Get/Post/Put/Delete)
class ApiClient {
  final String baseUrl;

  ApiClient({String? baseUrl})
      : baseUrl = baseUrl ?? Config_URL.baseUrl;

  Future<http.Response> get(String endpoint, {Map<String, String>? headers}) {
    return http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(headers),
    );
  }

  Future<http.Response> post(String endpoint, {Map<String, String>? headers, dynamic body}) {
    return http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(headers),
      body: jsonEncode(body),
    );
  }

  // Các phương thức PUT, DELETE nếu cần
  Future<http.Response> put(String endpoint, {Map<String, String>? headers, dynamic body}) {
    return http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(headers),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> delete(String endpoint, {Map<String, String>? headers}) {
    return http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(headers),
    );
  }

  Map<String, String> _buildHeaders(Map<String, String>? headers) {
    return {
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
    };
  }
}

Bước 6. 
Cập nhật giao diện đăng nhập
Lưu thông tin đăng nhập (Token) vào ứng dụng để lần sau đăng nhập nếu token còn hạn thì không cần phải đăng nhập lại bằng cách dùng shared_preferences  
Chạy câu lệnh trong terminal: flutter pub add shared_preferences

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'package:fb_interface/utils/auth.dart';
import 'package:fb_interface/screens/admin_screen.dart';
import 'package:fb_interface/screens/main_screen.dart';
import 'package:fb_interface/screens/registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _checkToken(); // Kiểm tra token khi mở màn hình
  }

  // Kiểm tra token trong SharedPreferences
  Future<void> _checkToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    if (token != null) {
      // Nếu token tồn tại, chuyển hướng đến MainScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  // Hàm xử lý đăng nhập
  Future<void> _handleLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ thông tin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Gọi Auth.login để xử lý đăng nhập
    Map<String, dynamic> result = await Auth.login(
      _usernameController.text,
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // Lưu token vào SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', result['token']); // Lưu token

      String role = result['role'] ?? 'User'; // Lấy vai trò người dùng

      if (role == 'Admin') {
        Navigator.pushReplacement(
          context,
          //Nếu người dùng là admin thì chuyển đến trang admin
          MaterialPageRoute(builder: (context) => const AdminScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          //nếu không phải là admin thì chuyển đến trang MainScreen
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
        //có thể xử lý thêm nếu không phải loại người dùng nào thì chuyển đến trang lỗi
      }
    } else {
      // Hiển thị thông báo lỗi
      String errorMessage = result['message'] ?? 'Tên đăng nhập hoặc mật khẩu không đúng';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 60),
                Text(
                  'facebook',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _usernameController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Số điện thoại hoặc email',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Mật khẩu',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text(
                      'Đăng nhập',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Thêm điều hướng đến màn hình đăng ký
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Chưa có tài khoản? "),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                        );
                      },
                      child: const Text(
                        'Đăng ký ngay',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Bước 7. 
Tạo giao diện admin để khi người dùng đăng nhập với role=Admin thì vào trang này
import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Implement logout logic here if needed.
              // For example, navigate back to the login screen or
              // clear stored credentials.
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Welcome, Admin!',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}

Bước 8. Tạo giao diện đăng ký
 
Giao diện đăng ký: 
import 'package:flutter/material.dart';
import 'package:fb_interface/utils/auth.dart';  

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _initialsController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleRegister() async {
    // Kiểm tra các trường nhập liệu
    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _initialsController.text.isEmpty ||
        _roleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ thông tin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Gọi phương thức register từ Auth class
    Map<String, dynamic> result = await Auth.register(
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      initials: _initialsController.text,
      role: _roleController.text,
    );

    setState(() => _isLoading = false);

    // Xử lý kết quả trả về từ API
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      // Sau khi đăng ký thành công, quay lại trang đăng nhập
      Navigator.pop(context);
    } else {
      String errorMessage = result['message'] ?? 'Đăng ký thất bại';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Text(
                  'Đăng ký tài khoản',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _usernameController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    hintText: 'Tên người dùng',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Mật khẩu',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _initialsController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    hintText: 'Ký tự viết tắt',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _roleController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    hintText: 'Vai trò (Admin/User)',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text(
                      'Đăng ký',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Đã có tài khoản? "),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Quay lại màn hình đăng nhập
                      },
                      child: const Text(
                        'Đăng nhập',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


Bước 9. cập nhật lại hàm main
Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

Kết quả chương trình
1.	Giao diện đăng nhập

2.	Giao diện đăng ký


3.	Đăng ký thành công

4.	Đăng nhập thành công vào trang HomeScreen + MarketScreen…

5.	Thoát ứng dụng ra chương trình tự đăng nhập lại (Đã lưu token trong ứng dụng và token còn thời hạn để đăng nhập)
Bài tập về nhà (cá nhân – lấy điểm kiểm tra tại lớp) tuần sau thầy Hùng chấm
1.	Thêm chức năng đăng xuất (xóa token khỏi SharePreference là xong)
2.	Lỗi khi đăng nhập (Tài khoản Admin vẫn đang vào giao diện User), tài khoản nào cho vào đúng giao diện đó (code lại trên giao diện LoginScreen)
3.	Đăng nhập thành công admin nhưng khi thoát ứng dụng và vào lại thì chương trình vào nhầm trang của User (MainScreen), cần chỉnh sửa lại cho đúng
4.	Phân quyền cho chức năng lấy danh sách sản phẩm
5.	Tích hợp smarth_auth vào (lấy điểm cộng hoặc gỡ lại một cột điểm nào đó bị vắng/thấp)
6.	Mỗi sản phẩm thuộc 1 danh mục sản phẩm (Thêm thuộc tính danh mục trong class Product)
7.	Admin có quyền: Thêm/ xóa/ sửa danh mục sản phẩm
8.	Xóa danh mục sản phẩm thì các sản phẩm sẽ không thuộc danh mục nào cả
https://pub.dev/packages/smart_auth




