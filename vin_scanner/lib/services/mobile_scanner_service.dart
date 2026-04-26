import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'scanner_service.dart';

class MobileScannerService implements ScannerService {
  final _controller = StreamController<ScanResult>.broadcast();
  DateTime? _scanStartTime;
  bool _hasResult = false;
  bool _disposed = false;

  final _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    cameraResolution: const Size(1920, 1080),
    formats: [BarcodeFormat.code128, BarcodeFormat.code39],
  );

  @override
  Stream<ScanResult> get results => _controller.stream;

  /// Returns the camera preview widget. The service owns construction so the
  /// UI layer has no dependency on mobile_scanner types.
  @override
  Widget buildPreview() {
    return MobileScanner(
      controller: _cameraController,
      fit: BoxFit.cover,
      onDetect: onBarcodeDetected,
    );
  }

  @override
  void startScan() {
    _scanStartTime = DateTime.now();
    _hasResult = false;
  }

  @override
  void stopScan() {
    _scanStartTime = null;
    _hasResult = false;
  }

  @override
  void toggleTorch() {
    _cameraController.toggleTorch();
  }

  // Matches a 17-char VIN anywhere within a raw barcode value.
  // Door jamb stickers (e.g. FCA/Stellantis) prefix the VIN with 'I' per
  // industry convention — extracting a substring handles that transparently.
  static final _vinPattern = RegExp(r'[A-HJ-NPR-Z0-9]{17}');

  void onBarcodeDetected(BarcodeCapture capture) {
    if (kDebugMode) debugPrint('[SCAN_DEBUG] onDetect fired: ${capture.barcodes.length} barcode(s) in frame');

    if (_hasResult) { if (kDebugMode) debugPrint('[SCAN_DEBUG] ignored — result already captured'); return; }
    if (_scanStartTime == null) { if (kDebugMode) debugPrint('[SCAN_DEBUG] ignored — startScan not called'); return; }

    for (final b in capture.barcodes) {
      if (kDebugMode) debugPrint('[SCAN_DEBUG] barcode: format=${b.format}, raw=${b.rawValue}');
    }

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) continue;

      final match = _vinPattern.firstMatch(raw);
      if (match == null) {
        if (kDebugMode) debugPrint('[SCAN_DEBUG] rejected — no VIN found in: $raw');
        continue;
      }

      final vin = match.group(0)!;
      if (kDebugMode) debugPrint('[SCAN_DEBUG] accepted VIN: $vin (from raw: $raw)');

      _hasResult = true;
      final elapsed = DateTime.now().difference(_scanStartTime!).inMilliseconds;
      if (kDebugMode) debugPrint('[SCAN_PERF] decoded in ${elapsed}ms');
      _controller.add(ScanResult(rawValue: vin, elapsedMs: elapsed));
      return;
    }
  }

  // Test hook — allows unit tests to simulate a decode without a real camera.
  @visibleForTesting
  void simulateDecode(String rawValue) {
    onBarcodeDetected(
      BarcodeCapture(
        barcodes: [Barcode(rawValue: rawValue)],
      ),
    );
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _cameraController.dispose();
    _controller.close();
  }
}
