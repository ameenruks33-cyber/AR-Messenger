import 'dart:math';

double distanceMeters({
  required double lat1,
  required double lon1,
  required double lat2,
  required double lon2,
}) {
  const earthRadius = 6371000.0;
  final dLat = _toRad(lat2 - lat1);
  final dLon = _toRad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadius * c;
}

double _toRad(double deg) => deg * pi / 180;

double speedKmh({
  required double meters,
  required Duration duration,
}) {
  if (duration.inSeconds <= 0) return 0;
  return (meters / duration.inSeconds) * 3.6;
}
