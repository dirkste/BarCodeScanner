import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:vin_scanner/main.dart';
import 'package:vin_scanner/services/scanner_service.dart';
import 'package:vin_scanner/services/vehicle_lookup_service.dart';

class _FakeScannerService implements ScannerService {
  @override
  Stream<ScanResult> get results => const Stream.empty();

  @override
  Widget buildPreview() => const SizedBox.shrink();

  @override
  void startScan() {}

  @override
  void stopScan() {}

  @override
  void toggleTorch() {}

  @override
  void dispose() {}
}

class _FakeLookupService implements VehicleLookupService {
  @override
  Future<VehicleInfo> lookup(String vin) async =>
      VehicleInfo(vin: vin, year: '2015', make: 'Chrysler', model: 'Town & Country');
}

void main() {
  setUp(() async {
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<ScannerService>(_FakeScannerService());
    GetIt.instance.registerSingleton<VehicleLookupService>(_FakeLookupService());
  });

  tearDown(() async => GetIt.instance.reset());

  group('VinScannerApp', () {
    testWidgets('shows scanner screen when permission granted', (tester) async {
      await tester.pumpWidget(
        const VinScannerApp(cameraPermissionDenied: false),
      );
      // Start Scan button is the ready-state UI — confirms scanner screen loaded
      expect(find.text('Start Scan'), findsOneWidget);
    });

    testWidgets('shows permission denied message when camera access is denied', (tester) async {
      await tester.pumpWidget(
        const VinScannerApp(cameraPermissionDenied: true),
      );
      expect(find.textContaining('permission'), findsOneWidget);
    });
  });
}

