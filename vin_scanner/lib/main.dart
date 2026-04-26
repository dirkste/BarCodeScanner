import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'services/mobile_scanner_service.dart';
import 'services/scanner_service.dart';
import 'ui/scanner_screen.dart';

void main() {
  GetIt.instance.registerSingleton<ScannerService>(MobileScannerService());
  runApp(const VinScannerApp());
}

class VinScannerApp extends StatelessWidget {
  const VinScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'VIN Scanner',
      home: ScannerScreen(),
    );
  }
}
