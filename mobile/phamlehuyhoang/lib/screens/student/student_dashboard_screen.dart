import 'package:flutter/material.dart';
import '../../models/attendance_models.dart';
import '../../models/auth_models.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/current_location_card.dart';
import '../auth/login_screen.dart';
import 'attendance_forecast_screen.dart';
import 'forecast_simulator_screen.dart';
import 'qr_scanner_screen.dart';
import 'register_face_screen.dart';
import 'student_history_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  UserDto? _user;
  List<AttendanceForecastDto> _forecasts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = await AuthService.getSavedUser();
    try {
      final forecasts = await AttendanceService.getMyForecasts();
      if (mounted) {
        setState(() {
          _user = user;
          _forecasts = forecasts;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sinh viên — phamlehuyhoang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 30,
                              backgroundColor: Color(0xFFE3F2FD),
                              child: Icon(Icons.person, size: 36, color: AppTheme.primary),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _user?.fullName ?? 'Sinh viên',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'MSSV: ${_user?.studentCode ?? "Chưa có"}',
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        _user?.hasFaceRegistered == true ? Icons.check_circle : Icons.warning_amber,
                                        size: 16,
                                        color: _user?.hasFaceRegistered == true ? AppTheme.success : AppTheme.warning,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _user?.hasFaceRegistered == true ? 'Đã có mẫu khuôn mặt' : 'Chưa đăng ký khuôn mặt',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _user?.hasFaceRegistered == true ? AppTheme.success : AppTheme.warning,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Vị trí người dùng hiện tại + Google Maps
                    const CurrentLocationCard(
                      title: 'Vị trí hiện tại của sinh viên',
                    ),
                    const SizedBox(height: 12),

                    // Quick QR Check-in Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1976D2), Color(0xFF0288D1)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withAlpha(60),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
                              SizedBox(width: 10),
                              Text(
                                'Điểm danh buổi học',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Quét mã QR từ màn hình Giảng viên và tự động gửi vị trí GPS của bạn (Mục e & b).',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.primary,
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('BẬT QUÉT QR + GỬI TỌA ĐỘ'),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                              );
                              _loadData();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Menu tính năng chính
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.trending_up_rounded,
                            color: const Color(0xFF2E7D32),
                            title: 'Dự báo chuyên cần',
                            subtitle: 'Công thức & Cảnh báo',
                            onTap: () {
                              if (_forecasts.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AttendanceForecastScreen(forecast: _forecasts.first),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Chưa có dữ liệu lớp học phần')),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.history_edu_rounded,
                            color: const Color(0xFFE65100),
                            title: 'Lịch sử điểm danh',
                            subtitle: 'Xem các buổi học',
                            onTap: () {
                              if (_forecasts.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StudentHistoryScreen(forecast: _forecasts.first),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Face registration card
                    _buildActionCard(
                      icon: Icons.face_retouching_natural,
                      color: const Color(0xFF7B1FA2),
                      title: 'Đăng ký / Cập nhật Mẫu Khuôn mặt (Mục a)',
                      subtitle: 'Chụp mẫu mặt của bạn để đăng nhập nhanh không cần mật khẩu',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterFaceScreen()),
                        );
                        _loadData();
                      },
                    ),
                    const SizedBox(height: 12),

                    // Demo Simulator card
                    _buildActionCard(
                      icon: Icons.psychology_outlined,
                      color: const Color(0xFF0284C7),
                      title: '🎮 Demo Động cơ Dự báo Cấm thi (Mục c)',
                      subtitle: 'Thử nghiệm kịch bản What-If: An toàn, Sát nút, Hết lượt & Cấm thi',
                      onTap: () {
                        final f = _forecasts.isNotEmpty ? _forecasts.first : null;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ForecastSimulatorScreen(
                              initialN: f?.n ?? 15,
                              initialM: f?.m ?? 8,
                              initialA: f?.a ?? 2,
                              initialL: f?.l ?? 3,
                              subjectName: f?.subjectName,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      'Tóm tắt chuyên cần các lớp học phần:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    if (_forecasts.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: Text('Bạn chưa được ghi danh vào lớp học phần nào'),
                          ),
                        ),
                      )
                    else
                      ..._forecasts.map((f) => Card(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AttendanceForecastScreen(forecast: f),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            f.subjectName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: f.isLimitExceeded
                                                ? AppTheme.danger.withAlpha(30)
                                                : AppTheme.success.withAlpha(30),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            f.isLimitExceeded ? 'VƯỢT GIỚI HẠN' : 'HỢP LỆ',
                                            style: TextStyle(
                                              color: f.isLimitExceeded ? AppTheme.danger : AppTheme.success,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text('Mã lớp: ${f.classCode}', style: const TextStyle(color: Colors.black54)),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text('Số buổi đã vắng: ${f.a} / ${f.l} tối đa'),
                                        ),
                                        Text(
                                          f.currentPercentage != null
                                              ? '${f.currentPercentage!.toStringAsFixed(1)}%'
                                              : 'Chưa chốt',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Còn được vắng: ${f.remainingAbsencesAllowed} buổi',
                                      style: TextStyle(
                                        color: f.remainingAbsencesAllowed == 0 ? AppTheme.danger : Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withAlpha(30),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}
