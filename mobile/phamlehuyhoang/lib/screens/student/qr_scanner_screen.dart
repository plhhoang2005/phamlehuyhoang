import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/attendance_models.dart';
import '../../services/attendance_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;
  final _manualTokenCtrl = TextEditingController();

  @override
  void dispose() {
    _scannerController.dispose();
    _manualTokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleQrDetected(String qrToken) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // 1. Lấy vị trí GPS hiện tại
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              SizedBox(width: 12),
              Text('Đang lấy vị trí GPS và đối chiếu khoảng cách...'),
            ],
          ),
          duration: Duration(seconds: 4),
        ),
      );

      final position = await LocationService.getCurrentLocation();

      // 2. Gửi lên máy chủ kiểm tra
      final result = await AttendanceService.checkIn(
        qrToken: qrToken.trim(),
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );

      if (!mounted) return;
      _showResultDialog(result);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showResultDialog(CheckInResultDto result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          result.success ? Icons.check_circle : Icons.error,
          size: 56,
          color: result.success ? AppTheme.success : AppTheme.danger,
        ),
        title: Text(result.success ? 'Điểm danh Thành công!' : 'Điểm danh Thất bại'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.message, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            if (result.distanceMeters != null)
              Text('Khoảng cách tới phòng học: ${result.distanceMeters!.toStringAsFixed(1)} mét'),
            if (result.status != null)
              Text('Trạng thái: ${result.status!.label}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Quay về dashboard
            },
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning, size: 48, color: AppTheme.danger),
        title: const Text('Lỗi điểm danh'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  void _showManualInputDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nhập mã QR thủ công (AVD/Test)'),
        content: TextField(
          controller: _manualTokenCtrl,
          decoration: const InputDecoration(
            labelText: 'Mã QR Token',
            hintText: 'DEMO-QR-... hoặc token',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              final token = _manualTokenCtrl.text.trim();
              Navigator.pop(ctx);
              if (token.isNotEmpty) {
                _handleQrDetected(token);
              }
            },
            child: const Text('Gửi điểm danh'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét mã QR điểm danh'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: 'Bật/Tắt đèn Flash',
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            tooltip: 'Đổi Camera',
            onPressed: () => _scannerController.switchCamera(),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard),
            tooltip: 'Nhập token thủ công',
            onPressed: _showManualInputDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? rawValue = barcode.rawValue;
                if (rawValue != null && rawValue.isNotEmpty) {
                  _handleQrDetected(rawValue);
                  break;
                }
              }
            },
          ),

          // Khung ngắm
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Hướng dẫn
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(180),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Hướng camera vào mã QR của Giảng viên. Tọa độ GPS sẽ tự động được gửi kèm để xác thực bán kính.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Đang xử lý điểm danh & tọa độ GPS...',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
