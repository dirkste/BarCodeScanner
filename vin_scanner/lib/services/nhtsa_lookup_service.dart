import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'vehicle_lookup_service.dart';

/// Calls the NHTSA vPIC API to decode a VIN into year / make / model.
///
/// Endpoint: GET https://vpic.nhtsa.dot.gov/api/vehicles/decodevin/{VIN}?format=json
/// Free, no API key required.
class NhtsaLookupService implements VehicleLookupService {
  final http.Client _client;

  NhtsaLookupService({http.Client? client}) : _client = client ?? http.Client();

  static const _base = 'https://vpic.nhtsa.dot.gov/api/vehicles/decodevin';
  static const _timeout = Duration(seconds: 10);

  @override
  Future<VehicleInfo> lookup(String vin) async {
    final uri = Uri.parse('$_base/$vin?format=json');
    try {
      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode != 200) {
        return VehicleInfo(
          vin: vin,
          errorText: 'Server returned HTTP ${response.statusCode}',
        );
      }
      return _parse(vin, response.body);
    } on TimeoutException {
      return VehicleInfo(vin: vin, errorText: 'Request timed out');
    } on Exception catch (e) {
      return VehicleInfo(vin: vin, errorText: 'Network error: $e');
    }
  }

  VehicleInfo _parse(String vin, String body) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return VehicleInfo(vin: vin, errorText: 'Invalid response from server');
    }

    final results = json['Results'] as List<dynamic>? ?? [];
    final map = <String, String>{};
    for (final item in results) {
      final key = item['Variable'] as String? ?? '';
      final value = item['Value'] as String? ?? '';
      if (value.isNotEmpty && value != 'null') {
        map[key] = value;
      }
    }

    // NHTSA returns error code "0" for a clean decode; anything else is a problem.
    final errorCode = map['Error Code'] ?? '';
    if (errorCode != '0') {
      final errorText = map['Error Text'] ?? 'Unrecognised VIN';
      return VehicleInfo(vin: vin, errorText: errorText);
    }

    return VehicleInfo(
      vin: vin,
      year: map['Model Year'],
      make: _titleCase(map['Make']),
      model: map['Model'],
      trim: map['Trim'],
    );
  }

  String? _titleCase(String? s) {
    if (s == null || s.isEmpty) return null;
    return s
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}
