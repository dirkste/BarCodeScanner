import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:vin_scanner/main.dart';
import 'package:vin_scanner/services/scanner_service.dart';

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

void main() {
  setUp(() async {
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<ScannerService>(_FakeScannerService());
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

