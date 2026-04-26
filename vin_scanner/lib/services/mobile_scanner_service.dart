import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'scanner_service.dart';

class MobileScannerService implements ScannerService {
  final _controller = StreamController<ScanResult>.broadcast();
  DateTime? _scanStartTime;
  bool _hasResult = false;

  @override
  Stream<ScanResult> get results => _controller.stream;

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

  void onBarcodeDetected(BarcodeCapture capture) {
    debugPrint('[SCAN_DEBUG] onDetect fired: ${capture.barcodes.length} barcode(s) in frame');

    if (_hasResult) { debugPrint('[SCAN_DEBUG] ignored — result already captured'); return; }
    if (_scanStartTime == null) { debugPrint('[SCAN_DEBUG] ignored — startScan not called'); return; }

    final barcode = capture.barcodes.firstOrNull;
    final raw = barcode?.rawValue;
    debugPrint('[SCAN_DEBUG] first barcode: format=${barcode?.format}, raw=$raw');

    if (raw == null || raw.isEmpty) { debugPrint('[SCAN_DEBUG] rejected — null or empty raw value'); return; }

    _hasResult = true;
    final elapsed = DateTime.now().difference(_scanStartTime!).inMilliseconds;
    final result = ScanResult(rawValue: raw, elapsedMs: elapsed);

    debugPrint('[SCAN_PERF] decoded in ${elapsed}ms');
    _controller.add(result);
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

  void dispose() {
    _controller.close();
  }
}
