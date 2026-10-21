import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/location_service.dart';
import '../theme/app_theme.dart';

/// Widget hiển thị vị trí người dùng hiện tại kèm tên địa điểm chi tiết
/// và nút mở trực tiếp trên Google Maps.
class CurrentLocationCard extends StatefulWidget {
  final String title;
  final bool autoFetch;
  final VoidCallback? onLocationUpdated;

  const CurrentLocationCard({
    super.key,
    this.title = 'Vị trí hiện tại của bạn',
    this.autoFetch = true,
    this.onLocationUpdated,
  });

  @override
  State<CurrentLocationCard> createState() => _CurrentLocationCardState();
}

class _CurrentLocationCardState extends State<CurrentLocationCard> {
  bool _isLoading = false;
  Position? _position;
  String? _address;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.autoFetch) {
      _fetchLocation();
    }
  }

  Future<void> _fetchLocation() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pos = await LocationService.getCurrentLocation(strict: false);
      final addr = await LocationService.getAddressFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (!mounted) return;
      setState(() {
        _position = pos;
        _address = addr;
        _isLoading = false;
      });
      widget.onLocationUpdated?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.my_location, color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 20),
                  tooltip: 'Cập nhật lại vị trí',
                  onPressed: _isLoading ? null : _fetchLocation,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Content
            if (_isLoading && _position == null) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Đang lấy tín hiệu GPS & tra tên địa điểm...',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ] else if (_errorMessage != null && _position == null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.warning.withAlpha(80)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Thử lại'),
                        onPressed: _fetchLocation,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_position != null) ...[
              // Địa chỉ chi tiết
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFFE53935),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _address ?? 'Đang xác định tên địa chỉ...',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    // Tọa độ & sai số GPS
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildBadge(
                          icon: Icons.navigation_outlined,
                          text: '${_position!.latitude.toStringAsFixed(6)}, ${_position!.longitude.toStringAsFixed(6)}',
                        ),
                        _buildBadge(
                          icon: Icons.gps_fixed,
                          text: 'Sai số: ±${_position!.accuracy.toStringAsFixed(1)}m',
                          color: _position!.accuracy <= 50 ? AppTheme.success : AppTheme.warning,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Nút mở Google Maps trực tiếp
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 1,
                ),
                icon: const Icon(Icons.map, size: 20),
                label: const Text(
                  'MỞ XEM TRỰC TIẾP TRÊN GOOGLE MAPS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () async {
                  final ok = await LocationService.openGoogleMaps(
                    _position!.latitude,
                    _position!.longitude,
                    label: 'Vị trí hiện tại của tôi',
                  );
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Không thể mở Google Maps.')),
                    );
                  }
                },
              ),
            ] else ...[
              OutlinedButton.icon(
                icon: const Icon(Icons.my_location),
                label: const Text('LẤY VỊ TRÍ HIỆN TẠI & XEM GOOGLE MAPS'),
                onPressed: _fetchLocation,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String text,
    Color color = Colors.black54,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
