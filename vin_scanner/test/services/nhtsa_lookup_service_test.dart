import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vin_scanner/services/nhtsa_lookup_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns a mock HTTP client that always responds with [body] and [statusCode].
http.Client _mockClient(String body, {int statusCode = 200}) {
  return MockClient((_) async => http.Response(body, statusCode));
}

String _nhtsaJson({
  String errorCode = '0',
  String errorText = '',
  String year = '2015',
  String make = 'CHRYSLER',
  String model = 'Town & Country',
  String trim = 'Touring',
}) {
  return jsonEncode({
    'Results': [
      {'Variable': 'Error Code', 'Value': errorCode},
      {'Variable': 'Error Text', 'Value': errorText},
      {'Variable': 'Model Year', 'Value': year},
      {'Variable': 'Make', 'Value': make},
      {'Variable': 'Model', 'Value': model},
      {'Variable': 'Trim', 'Value': trim},
    ],
  });
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('NhtsaLookupService', () {
    test('returns VehicleInfo with year/make/model on clean decode', () async {
      final service = NhtsaLookupService(
        client: _mockClient(_nhtsaJson(year: '2015', make: 'CHRYSLER', model: 'Town & Country', trim: 'Touring')),
      );
      final info = await service.lookup('2C4RDGCG0FR805928');

      expect(info.vin, '2C4RDGCG0FR805928');
      expect(info.hasError, isFalse);
      expect(info.year, '2015');
      expect(info.make, 'Chrysler'); // title-cased
      expect(info.model, 'Town & Country');
      expect(info.trim, 'Touring');
      expect(info.isComplete, isTrue);
    });

    test('title-cases make field', () async {
      final service = NhtsaLookupService(
        client: _mockClient(_nhtsaJson(make: 'RAM')),
      );
      final info = await service.lookup('3C6UR5JJ3HG590897');
      expect(info.make, 'Ram');
    });

    test('returns error when NHTSA error code is non-zero', () async {
      final service = NhtsaLookupService(
        client: _mockClient(_nhtsaJson(errorCode: '11', errorText: 'Manufacturer is not registered')),
      );
      final info = await service.lookup('00000000000000000');
      expect(info.hasError, isTrue);
      expect(info.errorText, contains('not registered'));
    });

    test('returns error on HTTP 500', () async {
      final service = NhtsaLookupService(
        client: _mockClient('', statusCode: 500),
      );
      final info = await service.lookup('2C4RDGCG0FR805928');
      expect(info.hasError, isTrue);
      expect(info.errorText, contains('500'));
    });

    test('returns error on network exception', () async {
      final service = NhtsaLookupService(
        client: MockClient((_) async => throw Exception('No network')),
      );
      final info = await service.lookup('2C4RDGCG0FR805928');
      expect(info.hasError, isTrue);
      expect(info.errorText, contains('Network error'));
    });

    test('returns error on malformed JSON', () async {
      final service = NhtsaLookupService(client: _mockClient('not json'));
      final info = await service.lookup('2C4RDGCG0FR805928');
      expect(info.hasError, isTrue);
      expect(info.errorText, contains('Invalid response'));
    });

    test('isComplete is false when make is missing', () async {
      final service = NhtsaLookupService(
        client: _mockClient(jsonEncode({
          'Results': [
            {'Variable': 'Error Code', 'Value': '0'},
            {'Variable': 'Model Year', 'Value': '2015'},
            {'Variable': 'Model', 'Value': 'Town & Country'},
          ],
        })),
      );
      final info = await service.lookup('2C4RDGCG0FR805928');
      expect(info.isComplete, isFalse);
    });
  });
}
