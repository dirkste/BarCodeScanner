import 'package:flutter/foundation.dart';

@immutable
class ScanResult {
  final String rawValue;
  final int elapsedMs;

  const ScanResult({required this.rawValue, required this.elapsedMs});
}

abstract class ScannerService {
  Stream<ScanResult> get results;
  void startScan();
  void stopScan();
}
