import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:vin_scanner/services/scanner_service.dart';
import 'package:vin_scanner/ui/scanner_screen.dart';

class _FakeScannerService implements ScannerService {
  final _controller = StreamController<ScanResult>.broadcast();

  @override
  Stream<ScanResult> get results => _controller.stream;

  /// Returns a plain coloured box — no real camera needed in tests.
  @override
  Widget buildPreview() => const SizedBox.expand(
        child: ColoredBox(color: Colors.black),
      );

  @override
  void startScan() {}

  @override
  void stopScan() {}

  @override
  void toggleTorch() {}

  void emit(ScanResult result) => _controller.add(result);

  @override
  void dispose() { if (!_controller.isClosed) _controller.close(); }
}

/// Wraps a [_FakeScannerService] and counts [toggleTorch] calls.
class _CountingTorchService implements ScannerService {
  final _FakeScannerService _inner;
  final VoidCallback _onToggle;

  _CountingTorchService(this._inner, this._onToggle);

  @override
  Stream<ScanResult> get results => _inner.results;

  @override
  Widget buildPreview() => _inner.buildPreview();

  @override
  void startScan() => _inner.startScan();

  @override
  void stopScan() => _inner.stopScan();

  @override
  void toggleTorch() { _onToggle(); _inner.toggleTorch(); }

  @override
  void dispose() {}
}

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
      await tester.pumpWidget(const MaterialApp(
        home: ScannerScreen(),
      ));
      expect(find.byType(ScannerScreen), findsOneWidget);
    });

    testWidgets('displays rawValue after scan result', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: ScannerScreen(),
      ));

      await tester.tap(find.text('Start Scan'));
      await tester.pump();

      fakeService.emit(const ScanResult(rawValue: '1HGCM82633A123456', elapsedMs: 243));
      await tester.pump();

      expect(find.text('1HGCM82633A123456'), findsOneWidget);
    });

    testWidgets('displays elapsedMs after scan result', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: ScannerScreen(),
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
      await tester.pumpWidget(const MaterialApp(
        home: ScannerScreen(),
      ));
      expect(find.text('Start Scan'), findsOneWidget);
    });

    testWidgets('shows hint after 10 seconds of no result', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: ScannerScreen(),
      ));

      await tester.tap(find.text('Start Scan'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 10));

      expect(find.textContaining('No VIN detected yet'), findsOneWidget);
    });

    testWidgets('torch button is always enabled', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ScannerScreen()));

      // Before scan
      final torchBefore = tester.widget<IconButton>(find.byType(IconButton));
      expect(torchBefore.onPressed, isNotNull);

      // During scan
      await tester.tap(find.text('Start Scan'));
      await tester.pump();
      final torchDuring = tester.widget<IconButton>(find.byType(IconButton));
      expect(torchDuring.onPressed, isNotNull);
    });

    testWidgets('torch is turned off when scan result arrives', (tester) async {
      int toggleTorchCalls = 0;
      // Override toggleTorch to count calls
      final countingService = _CountingTorchService(fakeService, () => toggleTorchCalls++);
      await getIt.reset();
      getIt.registerSingleton<ScannerService>(countingService);

      await tester.pumpWidget(const MaterialApp(home: ScannerScreen()));

      // Turn torch on manually
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(toggleTorchCalls, 1); // torch turned on

      // Start scan then emit result
      await tester.tap(find.text('Start Scan'));
      await tester.pump();
      fakeService.emit(const ScanResult(rawValue: '1HGCM82633A123456', elapsedMs: 100));
      await tester.pump();

      // Torch should have been turned off automatically
      expect(toggleTorchCalls, 2);
      // Icon should show torch-off
      expect(find.byIcon(Icons.flashlight_off), findsOneWidget);
    });

    testWidgets('Cancel button stops scanning and shows Start Scan again', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ScannerScreen()));

      await tester.tap(find.text('Start Scan'));
      await tester.pump();
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(find.text('Start Scan'), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);
    });
  });
}
