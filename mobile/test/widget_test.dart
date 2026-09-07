import 'package:flutter_test/flutter_test.dart';
import 'package:ar_messenger/core/utils/geo.dart';

void main() {
  test('geofence distance is inside 150 meters for nearby coordinates', () {
    final meters = distanceMeters(
      lat1: 25.2048,
      lon1: 55.2708,
      lat2: 25.2050,
      lon2: 55.2709,
    );
    expect(meters < 150, isTrue);
  });

  test('far office is outside the radius', () {
    final meters = distanceMeters(
      lat1: 25.2048,
      lon1: 55.2708,
      lat2: 25.3463,
      lon2: 55.4209,
    );
    expect(meters > 150, isTrue);
  });
}
