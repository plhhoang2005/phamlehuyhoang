import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'otp_verification_screen.dart';

class FaceLoginScreen extends StatefulWidget {
  const FaceLoginScreen({super.key});

  @override
  State<FaceLoginScreen> createState() => _FaceLoginScreenState();
}

class _FaceLoginScreenState extends State<FaceLoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _picker = ImagePicker();
  XFile? _capturedImage;
  String? _imageBase64;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _takePhoto(ImageSource source) async {
    try {
      final photo = await _picker.pickImage(
        source: source,
        maxWidth: 480,
        maxHeight: 480,
        imageQuality: 85,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _capturedImage = photo;
          _imageBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi camera: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  Future<void> _handleFaceLogin() async {
    final username = _usernameCtrl.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng nhập tên đăng nhập để đối chiếu khuôn mặt 1:1',
          ),
        ),
      );
      return;
    }

    if (_imageBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chụp ảnh khuôn mặt trước khi bấm xác thực'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await AuthService.faceLogin(
        username: username,
        imageBase64: _imageBase64!,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            ticket: res.ticket,
            message: res.message,
            isActivation: res.isActivation,
            expiresInSeconds: res.expiresInSeconds,
            username: username,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.danger,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập Khuôn mặt (Mục a)')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Đối chiếu Khuôn mặt 1:1',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Chụp khuôn mặt của bạn để đối chiếu với mẫu đã đăng ký của tài khoản. Luồng xác thực 2 lớp (Khuôn mặt + OTP) theo đúng yêu cầu đề bài.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên đăng nhập tài khoản *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 20),

              // Vùng hiển thị ảnh chụp / camera preview
              Center(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primary, width: 3),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _capturedImage != null
                      ? (kIsWeb
                            ? Image.network(
                                _capturedImage!.path,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(_capturedImage!.path),
                                fit: BoxFit.cover,
                              ))
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.face_unlock_rounded,
                              size: 70,
                              color: Colors.black45,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Chưa có ảnh mặt',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Nút chụp / chọn ảnh
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Chụp Camera'),
                      onPressed: () => _takePhoto(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Thư viện ảnh'),
                      onPressed: () => _takePhoto(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleFaceLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Xác thực Khuôn mặt & Nhận OTP'),
              ),
              const SizedBox(height: 16),

              TextButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Quay lại đăng nhập Mật khẩu + OTP'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
