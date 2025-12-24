import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/app_theme.dart';
import '../l10n/generated/app_localizations.dart';

class LocationPickerView extends StatefulWidget {
  const LocationPickerView({super.key});

  @override
  State<LocationPickerView> createState() => _LocationPickerViewState();
}

class _LocationPickerViewState extends State<LocationPickerView> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(37.5665, 126.9780);
  String? _selectedAddress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initCurrentLocation();
  }

  Future<void> _initCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      _getAddressFromLatLng(_currentPosition);

    } catch (e) {
      debugPrint("위치 오류: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    final l10n = AppLocalizations.of(context);
    
    try {
      // Use current locale for geocoding
      final locale = Localizations.localeOf(context);
      final localeId = locale.languageCode == 'en' ? 'en_US' : 'ko_KR';
      
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
        localeIdentifier: localeId,
      );

      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        List<String?> addressParts = [
          place.administrativeArea,
          place.locality,
          place.subLocality,
        ];

        String address = addressParts
            .where((part) => part != null && part.trim().isNotEmpty)
            .toSet()
            .join(' ');

        if (address.isEmpty) {
          address = place.street ?? (l10n?.locationPickerError ?? 'Address not found');
        }

        setState(() {
          _selectedAddress = address;
          _currentPosition = position;
        });
      }
    } catch (e) {
      if (mounted) {
        debugPrint("주소 변환 오류: $e");
        setState(() {
          _selectedAddress = l10n?.locationPickerError;
          _currentPosition = position;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.locationPickerTitle),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition,
                zoom: 16,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              onCameraIdle: () async {
                if (_mapController != null) {
                  final bounds = await _mapController!.getVisibleRegion();
                  final center = LatLng(
                    (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
                    (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
                  );
                  _getAddressFromLatLng(center);
                }
              },
            ),

          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(Icons.location_on, size: 50, color: AppTheme.errorColor),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    offset: Offset(0, -2),
                  )
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedAddress ?? l10n.locationPickerSearching,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, {
                            'address': _selectedAddress,
                            'latitude': _currentPosition.latitude,
                            'longitude': _currentPosition.longitude,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                            l10n.locationPickerSelect,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white
                            )
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}