import 'package:flutter_test/flutter_test.dart';
import 'package:vin_scanner/services/mobile_scanner_service.dart';
import 'package:vin_scanner/services/scanner_service.dart';

void main() {
  group('MobileScannerService', () {
    test('implements ScannerService', () {
      final service = MobileScannerService();
      expect(service, isA<ScannerService>());
    });

    test('exposes a results stream', () {
      final service = MobileScannerService();
      expect(service.results, isA<Stream<ScanResult>>());
    });

    test('emits ScanResult with elapsedMs >= 0 after startScan', () async {
      final service = MobileScannerService();
      service.startScan();

      // Subscribe before emitting — broadcast streams don't replay events.
      final resultFuture = service.results.first;
      service.simulateDecode('1HGCM82633A123456');

      final result = await resultFuture;
      expect(result.rawValue, '1HGCM82633A123456');
      expect(result.elapsedMs, greaterThanOrEqualTo(0));
    });

    test('elapsedMs is measured from startScan call', () async {
      final service = MobileScannerService();
      service.startScan();
      await Future.delayed(const Duration(milliseconds: 50));

      final resultFuture = service.results.first;
      service.simulateDecode('2T1BURHE0JC043821'); // valid 17-char VIN
      final result = await resultFuture;
      expect(result.elapsedMs, greaterThanOrEqualTo(50));
    });

    test('ignores subsequent decodes after first result until startScan called again', () async {
      final service = MobileScannerService();
      service.startScan();

      final resultFuture = service.results.first;
      service.simulateDecode('1HGCM82633A123456'); // valid VIN — accepted
      service.simulateDecode('2T1BURHE0JC043821'); // valid VIN — ignored, first already captured

      final result = await resultFuture;
      expect(result.rawValue, '1HGCM82633A123456');
    });

    test('strips industry-standard I prefix from VIN barcode', () async {
      final service = MobileScannerService();
      service.startScan();

      final resultFuture = service.results.first;
      service.simulateDecode('I1HGCM82633A123456'); // I-prefixed — VIN extracted

      final result = await resultFuture;
      expect(result.rawValue, '1HGCM82633A123456');
    });

    test('rejects barcodes with no 17-char VIN sequence', () async {
      final service = MobileScannerService();
      service.startScan();

      final resultFuture = service.results.first;
      service.simulateDecode('12345');              // too short — rejected
      service.simulateDecode('LT275/70R18');        // tire size — rejected
      service.simulateDecode('1HGCM82633A123456'); // valid VIN — accepted

      final result = await resultFuture;
      expect(result.rawValue, '1HGCM82633A123456');
    });
  });
}
