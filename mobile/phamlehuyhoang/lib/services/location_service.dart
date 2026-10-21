import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException('Dịch vụ định vị GPS trên thiết bị đang tắt. Vui lòng bật GPS.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException('Ứng dụng bị từ chối quyền truy cập vị trí GPS.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException('Quyền truy cập vị trí bị từ chối vĩnh viễn. Vui lòng cấp quyền trong Cài đặt ứng dụng.');
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      // Thử fallback sang vị trí gần nhất nếu timeout
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
      throw LocationException('Không thể lấy tọa độ vị trí hiện tại: $e');
    }
  }
}

class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => message;
}
