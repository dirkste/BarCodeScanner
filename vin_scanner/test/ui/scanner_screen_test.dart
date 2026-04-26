import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vin_scanner/services/scanner_service.dart';
import 'package:vin_scanner/ui/scanner_screen.dart';

class _FakeScannerService implements ScannerService {
  final _controller = StreamController<ScanResult>();

  @override
  Stream<ScanResult> get results => _controller.stream;

  @override
  void startScan() {}

  @override
  void stopScan() {}

  void emit(ScanResult result) => _controller.add(result);

  void dispose() => _controller.close();
}

/// Fake camera widget — avoids real hardware in unit tests.
Widget _fakeCamera(void Function(BarcodeCapture) _) => const SizedBox.expand(
      child: ColoredBox(color: Colors.black),
    );

void main() {
  final getIt = GetIt.instance;
  late _FakeScannerService fakeService;

  setUp(() async {
    await getIt.reset();
    fakeService = _FakeScannerService();
    getIt.registerSingleton<ScannerService>(fakeService);
  });

  tearDown(() async {
    fakeService.dispose();
    await getIt.reset();
  });

  group('ScannerScreen', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ScannerScreen(cameraBuilder: _fakeCamera),
      ));
      expect(find.byType(ScannerScreen), findsOneWidget);
    });

    testWidgets('displays rawValue after scan result', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ScannerScreen(cameraBuilder: _fakeCamera),
      ));

      await tester.tap(find.text('Start Scan'));
      await tester.pump();

      fakeService.emit(const ScanResult(rawValue: '1HGCM82633A123456', elapsedMs: 243));
      await tester.pump();

      expect(find.text('1HGCM82633A123456'), findsOneWidget);
    });

    testWidgets('displays elapsedMs after scan result', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ScannerScreen(cameraBuilder: _fakeCamera),
      ));

      await tester.tap(find.text('Start Scan'));
      await tester.pump();

      fakeService.emit(const ScanResult(rawValue: '1HGCM82633A123456', elapsedMs: 243));
      await tester.pump();

      expect(find.textContaining('243'), findsOneWidget);
    });

    testWidgets('shows permission denied message when camera access is denied', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: ScannerScreen(cameraPermissionDenied: true),
      ));
      expect(find.textContaining('permission'), findsOneWidget);
    });

    testWidgets('shows Start Scan button before scanning begins', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ScannerScreen(cameraBuilder: _fakeCamera),
      ));
      expect(find.text('Start Scan'), findsOneWidget);
    });

    testWidgets('shows hint after 10 seconds of no result', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ScannerScreen(cameraBuilder: _fakeCamera),
      ));

      await tester.tap(find.text('Start Scan'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 10));

      expect(find.textContaining('No VIN detected yet'), findsOneWidget);
    });
  });
}
