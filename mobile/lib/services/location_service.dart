import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class DeviceIdentity {
  const DeviceIdentity({
    required this.id,
    required this.model,
    required this.platform,
  });

  final String id;
  final String model;
  final String platform;
}

class LocationFix {
  const LocationFix({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.isMocked,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final bool isMocked;
  final DateTime timestamp;
}

class LocationService {
  Future<LocationFix> currentFix() async {
    final permission = await Permission.locationWhenInUse.request();
    if (!permission.isGranted) {
      throw StateError('Location permission is required for attendance.');
    }

    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw StateError('Please enable GPS to continue.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 20),
      ),
    );

    return LocationFix(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      isMocked: position.isMocked,
      timestamp: position.timestamp,
    );
  }
}

class DeviceService {
  Future<DeviceIdentity> currentDevice() async {
    final plugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await plugin.androidInfo;
      return DeviceIdentity(
        id: info.id,
        model: '${info.brand} ${info.model}',
        platform: 'android',
      );
    }
    final info = await plugin.iosInfo;
    return DeviceIdentity(
      id: info.identifierForVendor ?? info.name,
      model: info.utsname.machine,
      platform: 'ios',
    );
  }
}
