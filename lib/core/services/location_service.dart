import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Structured geocoded address result from reverse geocoding
class GeocodedAddress {
  final double latitude;
  final double longitude;
  final String flatBuilding;
  final String areaLocality;
  final String city;
  final String state;
  final String pincode;
  final String fullDisplayName;

  const GeocodedAddress({
    required this.latitude,
    required this.longitude,
    required this.flatBuilding,
    required this.areaLocality,
    required this.city,
    required this.state,
    required this.pincode,
    required this.fullDisplayName,
  });

  /// Formatted short location title e.g. "Bhavani, Erode"
  String get shortTitle {
    if (areaLocality.isNotEmpty && city.isNotEmpty) {
      if (areaLocality.toLowerCase() == city.toLowerCase()) {
        return areaLocality;
      }
      return '$areaLocality, $city';
    } else if (areaLocality.isNotEmpty) {
      return areaLocality;
    } else if (city.isNotEmpty) {
      return city;
    }
    return 'Doorstep Location';
  }
}

/// Result of querying device GPS with explicit diagnostic status
class DeviceLocationResult {
  final Position? position;
  final String? statusMessage;
  final bool isServiceDisabled;
  final bool isPermissionDenied;

  const DeviceLocationResult({
    this.position,
    this.statusMessage,
    this.isServiceDisabled = false,
    this.isPermissionDenied = false,
  });

  bool get isSuccess => position != null;
}

/// Search prediction for search bar in map picker
class LocationSearchResult {
  final String displayName;
  final double latitude;
  final double longitude;
  final String area;
  final String pincode;

  const LocationSearchResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.area,
    required this.pincode,
  });
}

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  /// Default fallback coordinates (Bangalore center / Farm Fresh Hub)
  static const double defaultLat = 12.9716;
  static const double defaultLng = 77.5946;

  /// Open device GPS system settings toggle
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  /// Open app permissions settings in Android/iOS
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  /// High-reliability device location retriever.
  /// Combines cached last-known position with live medium/high accuracy fix
  /// so it works reliably indoors, outdoors, and across mobile network states.
  Future<DeviceLocationResult> getDeviceLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const DeviceLocationResult(
          isServiceDisabled: true,
          statusMessage: 'Location/GPS is turned off on your device.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const DeviceLocationResult(
            isPermissionDenied: true,
            statusMessage: 'Location permission denied.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const DeviceLocationResult(
          isPermissionDenied: true,
          statusMessage: 'Location permission permanently blocked in system settings.',
        );
      }

      // Step 1: Immediately fetch last known position (cached fast-path)
      Position? fallbackPosition;
      try {
        fallbackPosition = await Geolocator.getLastKnownPosition();
      } catch (e) {
        debugPrint('[LocationService] LastKnownPosition warning: $e');
      }

      // Step 2: Attempt fresh position with balanced accuracy and generous timeout
      try {
        final freshPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 12),
          ),
        );
        return DeviceLocationResult(position: freshPosition);
      } catch (e) {
        debugPrint('[LocationService] Fresh fix timed out or failed: $e');
        if (fallbackPosition != null) {
          return DeviceLocationResult(
            position: fallbackPosition,
            statusMessage: 'Using recent cached location.',
          );
        }
      }

      if (fallbackPosition != null) {
        return DeviceLocationResult(position: fallbackPosition);
      }

      return const DeviceLocationResult(
        statusMessage: 'Unable to acquire GPS fix. Please adjust pin on map.',
      );
    } catch (e) {
      debugPrint('[LocationService] Error getting device location: $e');
      return DeviceLocationResult(
        statusMessage: 'GPS error: $e',
      );
    }
  }

  /// Legacy helper for quick position acquisition
  Future<Position?> getCurrentPosition() async {
    final result = await getDeviceLocation();
    return result.position;
  }

  /// Reverse geocode latitude and longitude using OpenStreetMap Nominatim
  Future<GeocodedAddress?> reverseGeocode(double latitude, double longitude) async {
    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);

      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$latitude&lon=$longitude&addressdetails=1',
      );

      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'VegoraGroceryApp/1.0 (contact@vegora.in)');
      request.headers.set('Accept-Language', 'en-IN,en');

      final response = await request.close();
      if (response.statusCode != 200) {
        return null;
      }

      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      final address = (data['address'] as Map<String, dynamic>?) ?? {};

      // Building / Flat / Street extraction
      final houseNumber = address['house_number'] as String? ?? '';
      final road = address['road'] as String? ??
          address['pedestrian'] as String? ??
          address['street'] as String? ??
          address['building'] as String? ??
          address['commercial'] as String? ??
          '';

      String flatBuilding = '';
      if (houseNumber.isNotEmpty && road.isNotEmpty) {
        flatBuilding = 'No. $houseNumber, $road';
      } else if (road.isNotEmpty) {
        flatBuilding = road;
      } else if (houseNumber.isNotEmpty) {
        flatBuilding = 'House #$houseNumber';
      }

      // Area / Locality extraction
      final areaLocality = address['suburb'] as String? ??
          address['neighbourhood'] as String? ??
          address['quarter'] as String? ??
          address['subdistrict'] as String? ??
          address['residential'] as String? ??
          address['city_district'] as String? ??
          address['village'] as String? ??
          address['town'] as String? ??
          '';

      // City / District
      final city = address['city'] as String? ??
          address['town'] as String? ??
          address['state_district'] as String? ??
          address['county'] as String? ??
          '';

      final state = address['state'] as String? ?? 'Tamil Nadu';
      final pincode = address['postcode'] as String? ?? '';
      final fullDisplayName = data['display_name'] as String? ?? '';

      return GeocodedAddress(
        latitude: latitude,
        longitude: longitude,
        flatBuilding: flatBuilding,
        areaLocality: areaLocality,
        city: city,
        state: state,
        pincode: pincode,
        fullDisplayName: fullDisplayName,
      );
    } catch (e) {
      debugPrint('[LocationService] Reverse geocode error: $e');
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  /// Search locations by query via Nominatim
  Future<List<LocationSearchResult>> searchLocations(String query) async {
    if (query.trim().length < 2) return [];

    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 6);

      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=jsonv2&q=${Uri.encodeComponent(query)}&limit=5&addressdetails=1&countrycodes=in',
      );

      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'VegoraGroceryApp/1.0 (contact@vegora.in)');
      request.headers.set('Accept-Language', 'en-IN,en');

      final response = await request.close();
      if (response.statusCode != 200) {
        return [];
      }

      final responseBody = await response.transform(utf8.decoder).join();
      final list = jsonDecode(responseBody) as List<dynamic>;

      return list.map((item) {
        final map = item as Map<String, dynamic>;
        final address = (map['address'] as Map<String, dynamic>?) ?? {};
        final lat = double.tryParse(map['lat']?.toString() ?? '') ?? 0.0;
        final lon = double.tryParse(map['lon']?.toString() ?? '') ?? 0.0;
        final area = address['suburb'] as String? ??
            address['neighbourhood'] as String? ??
            address['city'] as String? ??
            '';
        final pin = address['postcode'] as String? ?? '';

        return LocationSearchResult(
          displayName: map['display_name'] as String? ?? '',
          latitude: lat,
          longitude: lon,
          area: area,
          pincode: pin,
        );
      }).where((res) => res.latitude != 0.0 && res.longitude != 0.0).toList();
    } catch (e) {
      debugPrint('[LocationService] Search locations error: $e');
      return [];
    } finally {
      client?.close(force: true);
    }
  }
}
