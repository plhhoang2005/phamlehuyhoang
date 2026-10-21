import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_dashboard_screen.dart';
import '../lecturer/lecturer_dashboard_screen.dart';
import '../student/student_dashboard_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String ticket;
  final String message;
  final String? devOtpCode;
  final String username;

  const OtpVerificationScreen({
    super.key,
    required this.ticket,
    required this.message,
    this.devOtpCode,
    required this.username,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  late String _currentTicket;
  String? _currentDevOtp;
  final _otpCtrl = TextEditingController();

  int _expireSeconds = 300; // 5 phút
  int _resendCooldown = 60; // 60 giây
  Timer? _expireTimer;
  Timer? _resendTimer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentTicket = widget.ticket;
    _currentDevOtp = widget.devOtpCode;
    if (_currentDevOtp != null) {
      _otpCtrl.text = _currentDevOtp!;
    }
    _startTimers();
  }

  void _startTimers() {
    _expireTimer?.cancel();
    _resendTimer?.cancel();

    _expireTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_expireSeconds > 0) {
        setState(() => _expireSeconds--);
      } else {
        timer.cancel();
      }
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _expireTimer?.cancel();
    _resendTimer?.cancel();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final code = _otpCtrl.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ 6 chữ số OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await AuthService.verifyOtp(
        ticket: _currentTicket,
        code: code,
      );

      if (!mounted) return;

      Widget dashboard;
      if (res.user.role == 'Admin') {
        dashboard = const AdminDashboardScreen();
      } else if (res.user.role == 'Lecturer') {
        dashboard = const LecturerDashboardScreen();
      } else {
        dashboard = const StudentDashboardScreen();
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => dashboard),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResend() async {
    if (_resendCooldown > 0) return;

    setState(() => _isLoading = true);
    try {
      final res = await AuthService.resendOtp(ticket: _currentTicket);
      setState(() {
        _currentTicket = res.ticket;
        _currentDevOtp = res.devOtpCode;
        if (_currentDevOtp != null) {
          _otpCtrl.text = _currentDevOtp!;
        }
        _expireSeconds = 300;
        _resendCooldown = 60;
      });
      _startTimers();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTimer(int totalSecs) {
    final mins = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSecs % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xác thực OTP (Bước 2/2)')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Center(
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.mark_email_read_outlined, size: 40, color: AppTheme.success),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nhập mã xác thực 6 chữ số',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 12),

              // Dev OTP Code chip
              if (_currentDevOtp != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.warning),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.developer_mode, color: AppTheme.warning, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Mã Dev/Test: $_currentDevOtp (Tự điền)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Input field
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 12,
                ),
                decoration: const InputDecoration(
                  hintText: '------',
                  counterText: '',
                ),
              ),

              const SizedBox(height: 12),

              // Expiration timer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: Colors.black54),
                  const SizedBox(width: 4),
                  Text(
                    'Mã hết hạn sau: ${_formatTimer(_expireSeconds)}',
                    style: TextStyle(
                      color: _expireSeconds < 60 ? AppTheme.danger : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: (_isLoading || _expireSeconds <= 0) ? null : _handleVerify,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Xác thực & Vào ứng dụng'),
              ),

              const SizedBox(height: 16),

              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(
                  _resendCooldown > 0
                      ? 'Gửi lại mã ($_resendCooldown s)'
                      : 'Gửi lại mã OTP mới',
                ),
                onPressed: (_resendCooldown > 0 || _isLoading) ? null : _handleResend,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
