import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';

import 'services/mobile_scanner_service.dart';
import 'services/nhtsa_lookup_service.dart';
import 'services/scanner_service.dart';
import 'services/vehicle_lookup_service.dart';
import 'ui/scanner_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final status = await Permission.camera.request();
  GetIt.instance.registerFactory<ScannerService>(() => MobileScannerService());
  GetIt.instance.registerLazySingleton<VehicleLookupService>(() => NhtsaLookupService());
  runApp(VinScannerApp(cameraPermissionDenied: status.isDenied || status.isPermanentlyDenied));
}

class VinScannerApp extends StatelessWidget {
  final bool cameraPermissionDenied;

  const VinScannerApp({super.key, required this.cameraPermissionDenied});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VIN Scanner',
      home: ScannerScreen(cameraPermissionDenied: cameraPermissionDenied),
    );
  }
}
