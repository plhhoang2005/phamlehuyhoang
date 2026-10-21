import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationService {
  static Future<Position> getCurrentLocation({bool strict = true}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
        'Dịch vụ định vị GPS trên thiết bị đang tắt. Vui lòng bật GPS.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException(
          'Ứng dụng bị từ chối quyền truy cập vị trí GPS.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Quyền truy cập vị trí bị từ chối vĩnh viễn. Vui lòng cấp quyền trong Cài đặt ứng dụng.',
      );
    }

    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      final last = await Geolocator.getLastKnownPosition();
      if (last == null) {
        throw LocationException(
          'Không thể lấy vị trí hiện tại. Vui lòng ra nơi thông thoáng và thử lại.',
        );
      }
      position = last;
    }

    if (strict) {
      final age = DateTime.now().toUtc().difference(position.timestamp.toUtc());
      if (position.isMocked ||
          age > const Duration(seconds: 60) ||
          age < const Duration(seconds: -30)) {
        throw LocationException(
          'Vị trí GPS không hợp lệ hoặc đã cũ. Vui lòng bật định vị chính xác và thử lại.',
        );
      }
      if (!position.accuracy.isFinite ||
          position.accuracy < 0 ||
          position.accuracy > 50) {
        throw LocationException(
          'GPS chưa đủ chính xác (cần sai số tối đa 50 mét). Vui lòng thử lại.',
        );
      }
    }
    return position;
  }

  /// Tra cứu tên địa điểm / địa chỉ từ vĩ độ và kinh độ (Reverse Geocoding)
  static Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await Geocoding().placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[];
        if (p.name != null && p.name!.isNotEmpty && p.name != p.street) {
          parts.add(p.name!);
        }
        if (p.street != null && p.street!.isNotEmpty) {
          parts.add(p.street!);
        }
        if (p.subLocality != null &&
            p.subLocality!.isNotEmpty &&
            !parts.contains(p.subLocality)) {
          parts.add(p.subLocality!);
        }
        if (p.subAdministrativeArea != null &&
            p.subAdministrativeArea!.isNotEmpty) {
          parts.add(p.subAdministrativeArea!);
        }
        if (p.administrativeArea != null &&
            p.administrativeArea!.isNotEmpty) {
          parts.add(p.administrativeArea!);
        }
        if (p.country != null && p.country!.isNotEmpty) {
          parts.add(p.country!);
        }
        if (parts.isNotEmpty) return parts.join(', ');
      }
    } catch (_) {
      // Bỏ qua nếu ngoại tuyến hoặc dịch vụ chưa phản hồi
    }
    return 'Tọa độ: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  /// Mở vị trí trực tiếp trên Google Maps
  static Future<bool> openGoogleMaps(
    double latitude,
    double longitude, {
    String? label,
  }) async {
    final query = label != null && label.isNotEmpty
        ? Uri.encodeComponent('$latitude,$longitude ($label)')
        : '$latitude,$longitude';

    final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    final geoUri = Uri.parse('geo:$latitude,$longitude?q=$query');

    try {
      if (await canLaunchUrl(geoUri)) {
        final ok = await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        if (ok) return true;
      }
    } catch (_) {}

    try {
      if (await canLaunchUrl(webUri)) {
        final ok = await launchUrl(webUri, mode: LaunchMode.externalApplication);
        if (ok) return true;
      }
    } catch (_) {}

    try {
      return await launchUrl(webUri, mode: LaunchMode.platformDefault);
    } catch (_) {
      return false;
    }
  }
}

class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => message;
}
