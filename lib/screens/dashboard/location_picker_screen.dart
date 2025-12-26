import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../models/project_model.dart';
import '../../utils/utils.dart';

class LocationPickerScreen extends StatefulWidget {
  final GeoPoint? initialLocation;
  final double? initialRadius;
  final List<GeoPoint>? initialPolygon;
  final bool isCircular;

  const LocationPickerScreen({
    super.key,
    this.initialLocation,
    this.initialRadius,
    this.initialPolygon,
    this.isCircular = true,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _searchController = TextEditingController();
  
  LatLng? _selectedLocation;
  double _radius = 100.0; // Default radius in meters
  List<LatLng> _polygonPoints = [];
  bool _isCircularMode = true;
  String _address = '';
  bool _isLoading = false;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  Set<Polygon> _polygons = {};

  @override
  void initState() {
    super.initState();
    _isCircularMode = widget.isCircular;
    _radius = widget.initialRadius ?? 100.0;
    
    if (widget.initialLocation != null) {
      _selectedLocation = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
      _updateMarkers();
      _updateShapes();
      _getAddressFromLatLng(_selectedLocation!);
    }
    
    if (widget.initialPolygon != null && widget.initialPolygon!.isNotEmpty) {
      _polygonPoints = widget.initialPolygon!
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();
      _isCircularMode = false;
      _updateShapes();
    }
    
    if (_selectedLocation == null) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _selectedLocation = LatLng(position.latitude, position.longitude);
      _updateMarkers();
      _updateShapes();
      await _getAddressFromLatLng(_selectedLocation!);
      
      final controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation!, 16),
      );
    } catch (e) {
      // Default to a location if unable to get current
      _selectedLocation = const LatLng(28.6139, 77.2090); // Default: New Delhi
      _updateMarkers();
      _updateShapes();
    }
    
    setState(() => _isLoading = false);
  }

  void _updateMarkers() {
    if (_selectedLocation == null) return;
    
    _markers = {
      Marker(
        markerId: const MarkerId('selected'),
        position: _selectedLocation!,
        draggable: true,
        onDragEnd: (newPosition) async {
          _selectedLocation = newPosition;
          _updateMarkers();
          _updateShapes();
          await _getAddressFromLatLng(newPosition);
        },
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };
    
    // Add polygon point markers
    if (!_isCircularMode) {
      for (int i = 0; i < _polygonPoints.length; i++) {
        _markers.add(
          Marker(
            markerId: MarkerId('polygon_$i'),
            position: _polygonPoints[i],
            draggable: true,
            onDragEnd: (newPosition) {
              setState(() {
                _polygonPoints[i] = newPosition;
                _updateShapes();
              });
            },
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      }
    }
    
    setState(() {});
  }

  void _updateShapes() {
    if (_isCircularMode && _selectedLocation != null) {
      _circles = {
        Circle(
          circleId: const CircleId('boundary'),
          center: _selectedLocation!,
          radius: _radius,
          fillColor: AppTheme.primaryColor.withOpacity(0.3),
          strokeColor: AppTheme.primaryColor,
          strokeWidth: 2,
        ),
      };
      _polygons = {};
    } else if (!_isCircularMode && _polygonPoints.length >= 3) {
      _polygons = {
        Polygon(
          polygonId: const PolygonId('boundary'),
          points: _polygonPoints,
          fillColor: AppTheme.primaryColor.withOpacity(0.3),
          strokeColor: AppTheme.primaryColor,
          strokeWidth: 2,
        ),
      };
      _circles = {};
    } else {
      _circles = {};
      _polygons = {};
    }
    setState(() {});
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode,
          place.country,
        ].where((p) => p != null && p.isNotEmpty).toList();
        
        setState(() {
          _address = parts.join(', ');
        });
      }
    } catch (e) {
      setState(() {
        _address = 'Unable to get address';
      });
    }
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        _selectedLocation = LatLng(location.latitude, location.longitude);
        _updateMarkers();
        _updateShapes();
        await _getAddressFromLatLng(_selectedLocation!);

        final controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLocation!, 16),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location not found')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _onMapTap(LatLng position) {
    if (_isCircularMode) {
      setState(() {
        _selectedLocation = position;
        _updateMarkers();
        _updateShapes();
      });
      _getAddressFromLatLng(position);
    } else {
      setState(() {
        _polygonPoints.add(position);
        if (_selectedLocation == null && _polygonPoints.isNotEmpty) {
          _selectedLocation = _polygonPoints.first;
        }
        _updateMarkers();
        _updateShapes();
      });
      if (_selectedLocation != null) {
        _getAddressFromLatLng(_selectedLocation!);
      }
    }
  }

  void _clearPolygon() {
    setState(() {
      _polygonPoints.clear();
      _updateMarkers();
      _updateShapes();
    });
  }

  void _undoLastPoint() {
    if (_polygonPoints.isNotEmpty) {
      setState(() {
        _polygonPoints.removeLast();
        _updateMarkers();
        _updateShapes();
      });
    }
  }

  void _confirmSelection() {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
      return;
    }

    if (!_isCircularMode && _polygonPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 3 points for polygon boundary')),
      );
      return;
    }

    final center = GeoPoint(
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
    );

    List<GeoPoint>? polygonGeoPoints;
    if (!_isCircularMode) {
      polygonGeoPoints = _polygonPoints
          .map((p) => GeoPoint(latitude: p.latitude, longitude: p.longitude))
          .toList();
    }

    final boundary = LocationBoundary(
      center: center,
      radiusInMeters: _radius,
      polygonPoints: polygonGeoPoints,
      isCircular: _isCircularMode,
    );

    Navigator.pop(context, {
      'boundary': boundary,
      'address': _address,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _confirmSelection,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation ?? const LatLng(28.6139, 77.2090),
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _controller.complete(controller);
            },
            onTap: _onMapTap,
            markers: _markers,
            circles: _circles,
            polygons: _polygons,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          
          // Search bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search location...',
                          border: InputBorder.none,
                          icon: Icon(Icons.search),
                        ),
                        onSubmitted: (_) => _searchLocation(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _searchLocation,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Controls panel
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Address display
                    if (_address.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.location_on, 
                            size: 18, 
                            color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _address,
                              style: const TextStyle(fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    // Boundary type toggle
                    Row(
                      children: [
                        const Text('Boundary Type:'),
                        const SizedBox(width: 12),
                        ChoiceChip(
                          label: const Text('Circle'),
                          selected: _isCircularMode,
                          onSelected: (selected) {
                            setState(() {
                              _isCircularMode = true;
                              _updateShapes();
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Polygon'),
                          selected: !_isCircularMode,
                          onSelected: (selected) {
                            setState(() {
                              _isCircularMode = false;
                              _updateShapes();
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Circular mode controls
                    if (_isCircularMode) ...[
                      Row(
                        children: [
                          const Text('Radius: '),
                          Expanded(
                            child: Slider(
                              value: _radius,
                              min: 50,
                              max: 1000,
                              divisions: 19,
                              label: '${_radius.round()}m',
                              onChanged: (value) {
                                setState(() {
                                  _radius = value;
                                  _updateShapes();
                                });
                              },
                            ),
                          ),
                          Text('${_radius.round()}m'),
                        ],
                      ),
                    ],
                    
                    // Polygon mode controls
                    if (!_isCircularMode) ...[
                      Text('Tap on map to add boundary points (${_polygonPoints.length} points)'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: _polygonPoints.isNotEmpty 
                                ? _undoLastPoint 
                                : null,
                            icon: const Icon(Icons.undo),
                            label: const Text('Undo'),
                          ),
                          TextButton.icon(
                            onPressed: _polygonPoints.isNotEmpty 
                                ? _clearPolygon 
                                : null,
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear'),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 8),
                    
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: _getCurrentLocation,
                          icon: const Icon(Icons.my_location),
                          label: const Text('Current Location'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _confirmSelection,
                          icon: const Icon(Icons.check),
                          label: const Text('Confirm'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
