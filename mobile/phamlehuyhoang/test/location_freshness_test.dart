// ignore_for_file: depend_on_referenced_packages
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:phamlehuyhoang/services/location_service.dart';

class _Gps extends GeolocatorPlatform {
  Position? current;
  Position? cached;
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;
  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    if (current == null) throw TimeoutException('GPS unavailable');
    return current!;
  }

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async => cached;
}

Position _position(Duration age, {bool mocked = false}) => Position(
  latitude: 10.7,
  longitude: 106.6,
  timestamp: DateTime.now().subtract(age),
  accuracy: 10,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
  isMocked: mocked,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final original = GeolocatorPlatform.instance;
  late _Gps gps;
  setUp(() {
    gps = _Gps();
    GeolocatorPlatform.instance = gps;
  });
  tearDown(() => GeolocatorPlatform.instance = original);
  test('GPS timeout cannot reuse an hours-old cached location', () async {
    gps.cached = _position(const Duration(hours: 3));
    await expectLater(
      LocationService.getCurrentLocation(),
      throwsA(isA<LocationException>()),
    );
  });
  test('recent cached GPS keeps the actual measurement timestamp', () async {
    gps.cached = _position(const Duration(seconds: 10));
    final result = await LocationService.getCurrentLocation();
    expect(result.timestamp, gps.cached!.timestamp);
  });
  test(
    'stale current fix is rejected even if plugin returns it successfully',
    () async {
      gps.current = _position(const Duration(minutes: 10));
      await expectLater(
        LocationService.getCurrentLocation(),
        throwsA(isA<LocationException>()),
      );
    },
  );
  test('mocked location is not accepted for attendance', () async {
    gps.current = _position(Duration.zero, mocked: true);
    await expectLater(
      LocationService.getCurrentLocation(),
      throwsA(isA<LocationException>()),
    );
  });
}
