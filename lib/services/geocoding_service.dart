// lib/services/geocoding_service.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:searcademy/services/kakao_api.dart';

class GeocodingService {
  static Future<LatLng?> geocodeAddress(String address) async {
    return await KakaoLocalApi.getLatLngFromAddress(address);
  }
}
