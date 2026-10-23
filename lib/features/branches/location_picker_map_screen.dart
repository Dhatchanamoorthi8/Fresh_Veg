import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/location_service.dart';

/// Result returned when user confirms their delivery location on the map
class SelectedLocationResult {
  final double latitude;
  final double longitude;
  final String flatBuilding;
  final String areaLocality;
  final String city;
  final String state;
  final String pincode;
  final String fullDisplayName;

  const SelectedLocationResult({
    required this.latitude,
    required this.longitude,
    required this.flatBuilding,
    required this.areaLocality,
    required this.city,
    required this.state,
    required this.pincode,
    required this.fullDisplayName,
  });
}

class LocationPickerMapScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialTitle;

  const LocationPickerMapScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialTitle,
  });

  @override
  State<LocationPickerMapScreen> createState() => _LocationPickerMapScreenState();
}

class _LocationPickerMapScreenState extends State<LocationPickerMapScreen>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late LatLng _currentCenter;

  bool _isLocating = false;
  bool _isGeocoding = false;
  bool _isMapMoving = false;

  GeocodedAddress? _currentAddress;
  Timer? _geocodeDebounceTimer;

  // Search overlay state
  final TextEditingController _searchController = TextEditingController();
  List<LocationSearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;

  late final AnimationController _pinAnimController;
  late final Animation<double> _pinElevationAnim;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    final initLat = widget.initialLatitude ?? LocationService.defaultLat;
    final initLng = widget.initialLongitude ?? LocationService.defaultLng;
    _currentCenter = LatLng(initLat, initLng);

    _pinAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _pinElevationAnim = Tween<double>(begin: 0.0, end: -12.0).animate(
      CurvedAnimation(parent: _pinAnimController, curve: Curves.easeOutCubic),
    );

    // Initial reverse geocode
    _triggerReverseGeocode(_currentCenter);
  }

  @override
  void dispose() {
    _geocodeDebounceTimer?.cancel();
    _pinAnimController.dispose();
    _searchController.dispose();
    // Do NOT call _mapController.dispose() - FlutterMap manages internal MapInheritedModel
    super.dispose();
  }

  void _triggerReverseGeocode(LatLng target) {
    _geocodeDebounceTimer?.cancel();
    _geocodeDebounceTimer = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      setState(() => _isGeocoding = true);

      final result = await LocationService.instance.reverseGeocode(
        target.latitude,
        target.longitude,
      );

      if (!mounted) return;
      setState(() {
        _isGeocoding = false;
        _currentAddress = result;
      });
    });
  }

  void _onCameraMoved(LatLng newCenter, bool hasGesture) {
    _currentCenter = newCenter;
    if (hasGesture) {
      if (_showSearchResults) {
        setState(() => _showSearchResults = false);
      }
      FocusScope.of(context).unfocus();
      if (!_isMapMoving) {
        setState(() => _isMapMoving = true);
        _pinAnimController.forward();
      }
      _triggerReverseGeocode(newCenter);
    }
  }

  void _onCameraIdle() {
    if (_isMapMoving) {
      setState(() => _isMapMoving = false);
      _pinAnimController.reverse();
    }
  }

  Future<void> _locateUserGps() async {
    setState(() => _isLocating = true);
    final result = await LocationService.instance.getDeviceLocation();
    if (!mounted) return;
    setState(() => _isLocating = false);

    if (result.isSuccess && result.position != null) {
      final target = LatLng(result.position!.latitude, result.position!.longitude);
      _currentCenter = target;
      _mapController.move(target, 17.5);
      _triggerReverseGeocode(target);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📍 Exact GPS location detected! Move pin to adjust if needed.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (result.isServiceDisabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Device GPS is turned off. Please turn on Location.'),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Settings',
            textColor: Colors.amber,
            onPressed: () => LocationService.instance.openLocationSettings(),
          ),
        ),
      );
    } else if (result.isPermissionDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Location permission is needed to locate you.'),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Enable',
            textColor: Colors.amber,
            onPressed: () => LocationService.instance.openAppSettings(),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.statusMessage ??
                'GPS service unavailable. You can drag the map to select your exact location.',
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onSearchChanged(String query) {
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    Timer(const Duration(milliseconds: 350), () async {
      if (!mounted || _searchController.text.trim() != query.trim()) return;
      setState(() => _isSearching = true);
      final results = await LocationService.instance.searchLocations(query);
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searchResults = results;
        _showSearchResults = results.isNotEmpty;
      });
    });
  }

  void _selectSearchResult(LocationSearchResult res) {
    FocusScope.of(context).unfocus();
    final target = LatLng(res.latitude, res.longitude);
    _currentCenter = target;
    _mapController.move(target, 17.0);
    _triggerReverseGeocode(target);
    setState(() {
      _showSearchResults = false;
      _searchController.clear();
    });
  }

  void _confirmAndReturn() {
    final res = SelectedLocationResult(
      latitude: _currentCenter.latitude,
      longitude: _currentCenter.longitude,
      flatBuilding: _currentAddress?.flatBuilding ?? '',
      areaLocality: _currentAddress?.areaLocality ?? '',
      city: _currentAddress?.city ?? 'Bengaluru',
      state: _currentAddress?.state ?? 'Karnataka',
      pincode: _currentAddress?.pincode ?? '',
      fullDisplayName: _currentAddress?.fullDisplayName ??
          '${_currentCenter.latitude.toStringAsFixed(5)}, ${_currentCenter.longitude.toStringAsFixed(5)}',
    );
    Navigator.of(context).pop(res);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Interactive OpenStreetMap Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 16.5,
              minZoom: 4.0,
              maxZoom: 19.0,
              onPositionChanged: (camera, hasGesture) {
                _onCameraMoved(camera.center, hasGesture);
              },
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  _onCameraIdle();
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.vegora.vegetable_shop',
                maxNativeZoom: 19,
                subdomains: const ['a', 'b', 'c'],
              ),
            ],
          ),

          // 2. Fixed Center Pin with Elevation & Pulse Dot
          Center(
            child: AnimatedBuilder(
              animation: _pinAnimController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _pinElevationAnim.value - 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Location Pin Label Tooltip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Delivering to',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Custom High-Quality Pin Icon
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 46,
                            color: AppColors.primary,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          const Positioned(
                            top: 10,
                            child: Icon(
                              Icons.shopping_bag_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      // Ground Anchor Shadow / Ripple
                      Transform.translate(
                        offset: const Offset(0, -2),
                        child: Container(
                          width: _isMapMoving ? 14 : 10,
                          height: _isMapMoving ? 5 : 4,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(
                              alpha: _isMapMoving ? 0.25 : 0.45,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 3. Top Navigation & Search Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Back Button
                      Material(
                        color: Colors.white,
                        elevation: 3,
                        borderRadius: BorderRadius.circular(24),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => Navigator.of(context).pop(),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              size: 22,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Search Input Field
                      Expanded(
                        child: Material(
                          color: Colors.white,
                          elevation: 3,
                          borderRadius: BorderRadius.circular(24),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Search apartment, street, area...',
                              hintStyle: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              suffixIcon: _isSearching
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    )
                                  : _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.clear_rounded,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {
                                              _searchResults = [];
                                              _showSearchResults = false;
                                            });
                                          },
                                        )
                                      : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Search Auto-Suggest Dropdown
                  if (_showSearchResults)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: Material(
                        color: Colors.white,
                        elevation: 4,
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _searchResults.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, indent: 44),
                        itemBuilder: (context, index) {
                          final item = _searchResults[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.location_on_outlined,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            title: Text(
                              item.area.isNotEmpty
                                  ? item.area
                                  : item.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              item.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            onTap: () => _selectSearchResult(item),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Floating Action Controls (GPS Recenter + Zoom Buttons)
          Positioned(
            right: 16,
            bottom: 250,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Zoom In
                Material(
                  color: Colors.white,
                  elevation: 3,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      final currentZoom = _mapController.camera.zoom;
                      _mapController.move(_currentCenter, currentZoom + 1);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.add, size: 20, color: AppColors.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Zoom Out
                Material(
                  color: Colors.white,
                  elevation: 3,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      final currentZoom = _mapController.camera.zoom;
                      _mapController.move(_currentCenter, currentZoom - 1);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.remove, size: 20, color: AppColors.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Recenter GPS Button
                Material(
                  color: Colors.white,
                  elevation: 4,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _isLocating ? null : _locateUserGps,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _isLocating
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(
                              Icons.my_location_rounded,
                              size: 22,
                              color: AppColors.primary,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 5. Instruction Pill when Dragging Map
          Positioned(
            left: 0,
            right: 0,
            bottom: 236,
            child: Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isMapMoving ? 1.0 : 0.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Pan map to adjust exact doorstep',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 6. Bottom Address Confirmation Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderDark,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header status badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.pin_drop_rounded,
                              size: 13,
                              color: AppColors.primaryDark,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isGeocoding
                                  ? 'IDENTIFYING DOORSTEP...'
                                  : 'SELECTED DELIVERY LOCATION',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (_isGeocoding)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Location Title
                  Text(
                    _currentAddress?.shortTitle ??
                        widget.initialTitle ??
                        'Selected Location',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Full Address Description
                  Text(
                    _currentAddress?.fullDisplayName.isNotEmpty == true
                        ? _currentAddress!.fullDisplayName
                        : 'Move the map to set your delivery pin position accurately.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // GPS Coordinates Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.gps_fixed_rounded,
                          size: 12,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_currentCenter.latitude.toStringAsFixed(6)}° N, ${_currentCenter.longitude.toStringAsFixed(6)}° E',
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (_currentAddress?.pincode.isNotEmpty == true) ...[
                          const SizedBox(width: 8),
                          Text(
                            '• PIN: ${_currentAddress!.pincode}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirmation Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _confirmAndReturn,
                      icon: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Text(
                        'Confirm Location & Fill Address',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
