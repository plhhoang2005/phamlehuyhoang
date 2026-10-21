import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
  final MobileScannerController _scannerController = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _isProcessing = false;
  bool _completed = false;
  Position? _lastPosition;
  String? _resolvedAddress;
  Position? _livePosition;
  String? _liveAddress;

  @override
  void initState() {
    super.initState();
    _fetchLiveLocation();
  }

  Future<void> _fetchLiveLocation() async {
    try {
      final pos = await LocationService.getCurrentLocation(strict: false);
      final addr = await LocationService.getAddressFromCoordinates(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _livePosition = pos;
          _liveAddress = addr;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleQrDetected(String qrToken) async {
    if (_isProcessing || _completed || !mounted) return;
    setState(() => _isProcessing = true);

    try {
      await _scannerController.stop();
      if (!mounted) return;
      // 1. Lấy vị trí GPS hiện tại
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 12),
              Text('Đang lấy vị trí GPS và đối chiếu khoảng cách...'),
            ],
          ),
          duration: Duration(seconds: 4),
        ),
      );

      final position = await LocationService.getCurrentLocation();
      _lastPosition = position;
      try {
        _resolvedAddress = await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
      } catch (_) {
        _resolvedAddress = _liveAddress;
      }

      // 2. Gửi lên máy chủ kiểm tra
      final result = await AttendanceService.checkIn(
        qrToken: qrToken.trim(),
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        capturedAt: position.timestamp,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      final closeScanner = await _showResultDialog(result);
      if (closeScanner == true && mounted) {
        _completed = true;
        if (Navigator.canPop(context)) Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      await _showErrorDialog(e.toString());
    } finally {
      if (mounted && !_completed) {
        setState(() => _isProcessing = false);
        try {
          await _scannerController.start();
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Không thể mở lại camera. Vui lòng quay lại màn hình quét QR.',
                ),
              ),
            );
          }
        }
      }
    }
  }

  Future<bool?> _showResultDialog(CheckInResultDto result) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          result.success ? Icons.check_circle : Icons.error,
          size: 56,
          color: result.success ? AppTheme.success : AppTheme.danger,
        ),
        title: Text(
          result.success ? 'Điểm danh Thành công!' : 'Điểm danh Thất bại',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.message, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            if (result.distanceMeters != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: result.success ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: result.success ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          result.success ? Icons.check_circle : Icons.warning_amber_rounded,
                          size: 18,
                          color: result.success ? AppTheme.success : AppTheme.danger,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Khoảng cách: ${result.distanceMeters!.toStringAsFixed(1)} mét',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: result.success ? const Color(0xFF166534) : AppTheme.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_lastPosition != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Sai số GPS: ±${_lastPosition!.accuracy.toStringAsFixed(1)}m (Tín hiệu vệ tinh thật)',
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                    if (_resolvedAddress != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Vị trí: $_resolvedAddress',
                        style: const TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (result.status != null)
              Text(
                'Trạng thái: ${result.status!.label}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            if (_lastPosition != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.map, size: 16),
                  label: const Text('Xem vị trí quét trên Google Maps', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    LocationService.openGoogleMaps(
                      _lastPosition!.latitude,
                      _lastPosition!.longitude,
                      label: 'Vị trí điểm danh của sinh viên',
                    );
                  },
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx, result.success);
            },
            child: Text(result.success ? 'Đóng' : 'Thử lại'),
          ),
        ],
      ),
    );
  }

  Future<void> _showErrorDialog(String error) {
    return showDialog<void>(
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

          // Vị trí người dùng hiện tại (Overlay)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(200),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.my_location, color: Colors.lightGreenAccent, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _liveAddress ?? 'Đang tải vị trí người dùng...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_livePosition != null)
                          Text(
                            'Tọa độ: ${_livePosition!.latitude.toStringAsFixed(5)}, ${_livePosition!.longitude.toStringAsFixed(5)} (±${_livePosition!.accuracy.toStringAsFixed(1)}m)',
                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                      ],
                    ),
                  ),
                  if (_livePosition != null)
                    IconButton(
                      icon: const Icon(Icons.map, color: Colors.lightBlueAccent, size: 22),
                      tooltip: 'Mở xem trực tiếp trên Google Maps',
                      onPressed: () {
                        LocationService.openGoogleMaps(
                          _livePosition!.latitude,
                          _livePosition!.longitude,
                          label: 'Vị trí hiện tại của tôi',
                        );
                      },
                    ),
                ],
              ),
            ),
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
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
