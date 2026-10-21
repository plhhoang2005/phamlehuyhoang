import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/attendance_models.dart';
import '../../models/class_models.dart';
import '../../services/attendance_service.dart';
import '../../theme/app_theme.dart';

class OpenQrScreen extends StatefulWidget {
  final ClassSessionDto session;
  final CourseClassDto courseClass;

  const OpenQrScreen({super.key, required this.session, required this.courseClass});

  @override
  State<OpenQrScreen> createState() => _OpenQrScreenState();
}

class _OpenQrScreenState extends State<OpenQrScreen> {
  QrSessionDto? _qrSession;
  int _remainingSeconds = 60;
  Timer? _countdownTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _openNewQrSession();
  }

  Future<void> _openNewQrSession() async {
    setState(() => _isLoading = true);
    _countdownTimer?.cancel();
    try {
      final qr = await AttendanceService.openQrSession(widget.session.id, lifetimeSeconds: 60);
      setState(() {
        _qrSession = qr;
        _remainingSeconds = qr.remainingSeconds > 0 ? qr.remainingSeconds : 60;
        _isLoading = false;
      });
      _startTimer();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi mở QR: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleCloseSession() async {
    _countdownTimer?.cancel();
    try {
      await AttendanceService.closeQrSession(widget.session.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đóng phiên điểm danh QR')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.danger),
      );
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('QR — Buổi ${widget.session.sessionNumber}')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.session.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.session.roomName} • Bán kính: ${widget.session.radiusMeters.toStringAsFixed(0)} mét',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 24),

                    // QR Display Box
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _qrSession != null && _remainingSeconds > 0
                            ? QrImageView(
                                data: _qrSession!.qrToken,
                                version: QrVersions.auto,
                                size: 240,
                              )
                            : Container(
                                width: 240,
                                height: 240,
                                color: const Color(0xFFF1F5F9),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.timer_off, size: 60, color: AppTheme.danger),
                                    SizedBox(height: 8),
                                    Text('Mã QR đã hết hạn',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.danger)),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Countdown timer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer,
                          color: _remainingSeconds <= 10 ? AppTheme.danger : AppTheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _remainingSeconds > 0 ? 'Hiệu lực còn: $_remainingSeconds giây' : 'Đã hết hạn',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _remainingSeconds <= 10 ? AppTheme.danger : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Nút làm mới QR
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Làm mới Mã QR (Tự động gia hạn)'),
                      onPressed: _openNewQrSession,
                    ),
                    const SizedBox(height: 12),

                    // Nút đóng phiên
                    OutlinedButton.icon(
                      icon: const Icon(Icons.close, color: AppTheme.danger),
                      label: const Text('Đóng phiên điểm danh ngay', style: TextStyle(color: AppTheme.danger)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.danger)),
                      onPressed: _handleCloseSession,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
