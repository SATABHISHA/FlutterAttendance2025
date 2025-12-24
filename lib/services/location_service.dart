import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position> getCurrentPosition() async {
    final hasPermission = await checkLocationPermission();
    if (!hasPermission) {
      throw LocationException('Location permission not granted');
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      throw LocationException('Failed to get current position: $e');
    }
  }

  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        List<String> addressParts = [
          if (place.street?.isNotEmpty ?? false) place.street!,
          if (place.subLocality?.isNotEmpty ?? false) place.subLocality!,
          if (place.locality?.isNotEmpty ?? false) place.locality!,
          if (place.administrativeArea?.isNotEmpty ?? false) place.administrativeArea!,
          if (place.postalCode?.isNotEmpty ?? false) place.postalCode!,
          if (place.country?.isNotEmpty ?? false) place.country!,
        ];
        return addressParts.join(', ');
      }
      return 'Unknown location';
    } catch (e) {
      return 'Unable to get address';
    }
  }

  Future<String?> getCountryFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        return placemarks.first.country;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<LocationData> getFullLocationData() async {
    final position = await getCurrentPosition();
    final address = await getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );
    final country = await getCountryFromCoordinates(
      position.latitude,
      position.longitude,
    );

    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      address: address,
      country: country,
      timezone: DateTime.now().timeZoneName,
    );
  }
}

class LocationData {
  final double latitude;
  final double longitude;
  final String address;
  final String? country;
  final String? timezone;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.country,
    this.timezone,
  });
}

class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => message;
}
