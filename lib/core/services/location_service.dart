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

  /// Formatted short location title e.g. "Whitefield, Bengaluru"
  String get shortTitle {
    if (areaLocality.isNotEmpty && city.isNotEmpty) {
      return '$areaLocality, $city';
    } else if (areaLocality.isNotEmpty) {
      return areaLocality;
    } else if (city.isNotEmpty) {
      return city;
    }
    return 'Pinpoint Location';
  }
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

  /// Request permission and obtain current high-accuracy device GPS position.
  /// Gracefully catches errors or permission rejections and returns null.
  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] Location services are disabled.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[LocationService] Location permissions denied.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Location permissions permanently denied.');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return position;
    } catch (e) {
      debugPrint('[LocationService] Error getting current position: $e');
      return null;
    }
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
          'Bengaluru';

      final state = address['state'] as String? ?? 'Karnataka';
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
