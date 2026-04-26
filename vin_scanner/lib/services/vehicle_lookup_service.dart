import 'package:flutter/foundation.dart';

/// Vehicle details returned from a VIN lookup.
@immutable
class VehicleInfo {
  final String vin;
  final String? year;
  final String? make;
  final String? model;
  final String? trim;

  /// Non-null when the lookup failed or the VIN was unrecognised.
  final String? errorText;

  const VehicleInfo({
    required this.vin,
    this.year,
    this.make,
    this.model,
    this.trim,
    this.errorText,
  });

  bool get hasError => errorText != null;

  /// True when all key fields are present and there is no error.
  bool get isComplete => !hasError && year != null && make != null && model != null;

  @override
  String toString() => hasError
      ? 'VehicleInfo(vin=$vin, error=$errorText)'
      : 'VehicleInfo(vin=$vin, $year $make $model${trim != null ? " $trim" : ""})';
}

/// Looks up vehicle details for a decoded VIN.
abstract class VehicleLookupService {
  Future<VehicleInfo> lookup(String vin);
}
