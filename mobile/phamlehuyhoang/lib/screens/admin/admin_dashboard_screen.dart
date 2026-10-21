import 'package:flutter/material.dart';
import '../../models/auth_models.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/current_location_card.dart';
import '../auth/login_screen.dart';
import '../student/register_face_screen.dart';
import 'manage_classes_screen.dart';
import 'manage_subjects_screen.dart';
import 'manage_users_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  UserDto? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getSavedUser();
    if (mounted) setState(() => _user = user);
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
        title: const Text('Quản trị viên — phamlehuyhoang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(0xFFFEE2E2),
                      child: Icon(Icons.admin_panel_settings, size: 32, color: AppTheme.danger),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _user?.fullName ?? 'Quản trị viên',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(_user?.email ?? '', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.danger.withAlpha(25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'VAI TRÒ: QUẢN TRỊ VIÊN HỆ THỐNG (ADMIN)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Vị trí hiện tại của Quản trị viên + Google Maps
            const CurrentLocationCard(
              title: 'Vị trí hiện tại của quản trị viên',
            ),
            const SizedBox(height: 16),

            const Text('Chức năng Quản lý Hệ thống:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _buildAdminMenuCard(
              icon: Icons.people_alt_outlined,
              color: const Color(0xFF1976D2),
              title: 'Quản lý Tài khoản & Phân quyền',
              subtitle: 'Xem, thêm mới, sửa vai trò Admin / Giảng viên / Sinh viên',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
                );
              },
            ),
            const SizedBox(height: 10),

            _buildAdminMenuCard(
              icon: Icons.menu_book_outlined,
              color: const Color(0xFF00897B),
              title: 'Quản lý Môn học (Subjects)',
              subtitle: 'Danh mục mã môn học, tên môn và số tín chỉ',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageSubjectsScreen()),
                );
              },
            ),
            const SizedBox(height: 10),

            _buildAdminMenuCard(
              icon: Icons.class_outlined,
              color: const Color(0xFFE65100),
              title: 'Quản lý Lớp học phần & Phân công',
              subtitle: 'Thiết lập lớp, N buổi học, L vắng tối đa, gán Giảng viên',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageClassesScreen()),
                );
              },
            ),
            const SizedBox(height: 10),

            _buildAdminMenuCard(
              icon: Icons.face_retouching_natural,
              color: const Color(0xFF7B1FA2),
              title: 'Đăng ký Mẫu Khuôn mặt (Mục a)',
              subtitle: 'Chụp mẫu mặt của bạn để đăng nhập nhanh cho Quản trị viên',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterFaceScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminMenuCard({
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withAlpha(25),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
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
