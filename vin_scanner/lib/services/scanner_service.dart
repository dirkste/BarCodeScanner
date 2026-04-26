import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

@immutable
class ScanResult {
  final String rawValue;
  final int elapsedMs;

  const ScanResult({required this.rawValue, required this.elapsedMs});
}

abstract class ScannerService {
  Stream<ScanResult> get results;

  /// Returns the camera preview widget. The service owns widget construction
  /// so the UI layer never needs to import any scanner library directly.
  Widget buildPreview();

  void startScan();
  void stopScan();
  void toggleTorch();
  void dispose();
}
