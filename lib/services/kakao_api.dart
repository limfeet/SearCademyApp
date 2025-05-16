// lib/kakao/kakao_local_api.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class KakaoLocalApi {
  static final _apiKey = dotenv.env['KAKAO_REST_API_KEY'];

  /// 주소 → 좌표 변환
  static Future<LatLng?> getLatLngFromAddress(String address) async {
    final url = Uri.parse(
      'https://dapi.kakao.com/v2/local/search/address.json?query=${Uri.encodeComponent(address)}',
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'KakaoAK $_apiKey',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final documents = json['documents'] as List;

      if (documents.isNotEmpty) {
        final first = documents[0];
        final lat = double.parse(first['y']);
        final lng = double.parse(first['x']);
        return LatLng(lat, lng);
      }
    }

    return null;
  }
}
