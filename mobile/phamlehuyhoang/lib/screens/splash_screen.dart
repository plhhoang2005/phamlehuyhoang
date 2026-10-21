import 'package:flutter/material.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import 'admin/admin_dashboard_screen.dart';
import 'auth/login_screen.dart';
import 'lecturer/lecturer_dashboard_screen.dart';
import 'student/student_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 800));
    final user = await AuthService.getSavedUser();
    if (!mounted) return;

    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      _navigateToDashboard(user);
    }
  }

  void _navigateToDashboard(UserDto user) {
    Widget target;
    if (user.role == 'Admin') {
      target = const AdminDashboardScreen();
    } else if (user.role == 'Lecturer') {
      target = const LecturerDashboardScreen();
    } else {
      target = const StudentDashboardScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => target),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1976D2),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner_rounded,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 24),
            Text(
              'phamlehuyhoang',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Điểm danh QR • Vị trí • Khuôn mặt • Dự báo',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 36),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
