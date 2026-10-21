// ignore_for_file: implementation_imports, depend_on_referenced_packages
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:phamlehuyhoang/screens/student/qr_scanner_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Camera extends MobileScannerPlatform {
  @override
  Stream<BarcodeCapture?> get barcodesStream => const Stream.empty();
  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();
  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();
  @override
  Widget buildCameraView() => const SizedBox.expand();
  @override
  Future<MobileScannerViewAttributes> start(StartOptions options) async =>
      const MobileScannerViewAttributes(
        cameraDirection: CameraFacing.back,
        currentTorchMode: TorchState.off,
        size: Size(640, 480),
      );
  @override
  Future<void> stop() async {}
  @override
  Future<void> updateScanWindow(Rect? window) async {}
  @override
  Future<void> dispose() async {}
}

class _Gps extends GeolocatorPlatform {
  final measuredAt = DateTime.now().subtract(const Duration(seconds: 10));
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;
  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async => Position(
    latitude: 10.7,
    longitude: 106.6,
    timestamp: measuredAt,
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'repeat detections cannot submit again while result dialog is open',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'custom_api_base_url': 'https://attendance.example',
      });
      final originalCamera = MobileScannerPlatform.instance;
      final originalGps = GeolocatorPlatform.instance;
      final gps = _Gps();
      MobileScannerPlatform.instance = _Camera();
      GeolocatorPlatform.instance = gps;
      var submits = 0;
      DateTime? captureTime;
      try {
        await http.runWithClient(
          () async {
            await tester.pumpWidget(const MaterialApp(home: QrScannerScreen()));
            await tester.pumpAndSettle();
            final onDetect = tester
                .widget<MobileScanner>(find.byType(MobileScanner))
                .onDetect!;
            const capture = BarcodeCapture(
              barcodes: [Barcode(rawValue: 'qr-token')],
            );
            onDetect(capture);
            await tester.pump();
            await tester.pump(const Duration(seconds: 1));
            expect(find.byType(AlertDialog), findsOneWidget);
            onDetect(capture);
            onDetect(capture);
            await tester.pump();
            await tester.pump(const Duration(seconds: 1));
            expect(submits, 1);
            expect(find.byType(AlertDialog), findsOneWidget);
            expect(captureTime, gps.measuredAt.toUtc());
            expect(find.byTooltip('Nhập token thủ công'), findsNothing);
            await tester.pumpWidget(const SizedBox());
            await tester.pumpAndSettle();
          },
          () => MockClient((request) async {
            submits++;
            captureTime = DateTime.parse(
              jsonDecode(request.body)['clientTimestampUtc'],
            );
            return http.Response(
              jsonEncode({
                'success': true,
                'message': 'Đã lưu điểm danh',
                'status': 1,
                'distanceMeters': 3,
                'checkedInAtUtc': DateTime.now().toUtc().toIso8601String(),
              }),
              200,
            );
          }),
        );
      } finally {
        MobileScannerPlatform.instance = originalCamera;
        GeolocatorPlatform.instance = originalGps;
      }
    },
  );
}
