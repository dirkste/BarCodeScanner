import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:vin_scanner/services/scanner_service.dart';

class _MockScannerService implements ScannerService {
  @override
  Stream<ScanResult> get results => const Stream.empty();

  @override
  void startScan() {}

  @override
  void stopScan() {}
}

void main() {
  final getIt = GetIt.instance;

  setUp(() => getIt.reset());
  tearDown(() => getIt.reset());

  group('ScanResult', () {
    test('holds rawValue and elapsedMs', () {
      const result = ScanResult(rawValue: '1HGCM82633A123456', elapsedMs: 243);
      expect(result.rawValue, '1HGCM82633A123456');
      expect(result.elapsedMs, 243);
    });
  });

  group('ScannerService', () {
    test('can be registered with get_it and retrieved as abstract type', () {
      getIt.registerSingleton<ScannerService>(_MockScannerService());
      expect(getIt<ScannerService>(), isA<ScannerService>());
    });

    test('exposes a results stream', () {
      final service = _MockScannerService();
      expect(service.results, isA<Stream<ScanResult>>());
    });
  });
}
