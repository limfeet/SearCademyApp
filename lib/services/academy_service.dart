import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // 추가

// 커스텀 API URL을 가져오는 헬퍼 함수 (추가)
Future<String> _getActiveApiBaseUrl() async {
  final prefs = await SharedPreferences.getInstance();
  final isEnabled = prefs.getBool('custom_api_enabled') ?? false;

  if (isEnabled) {
    final customUrl = prefs.getString('custom_api_url') ?? '';
    if (customUrl.isNotEmpty) {
      return customUrl;
    }
  }

  // 기본값 반환
  return dotenv.env['ES_NEARBY_REST_API_URL'] ??
      'https://academy-api-service-tokyo-998204324830.asia-northeast1.run.app';
}

Future<List<Map<String, dynamic>>> loadAcademyData() async {
  final String jsonString =
      await rootBundle.loadString('assets/data_combined.json');
  final List<dynamic> jsonList = json.decode(jsonString);
  return jsonList.cast<Map<String, dynamic>>();
}

// 학원 상세 페이지에서 데이터를 가져오는 함수
Future<Map<String, dynamic>?> loadAcademyDetailData(String academyId) async {
  final String jsonString =
      await rootBundle.loadString('assets/data_combined.json');
  final List<dynamic> jsonList = json.decode(jsonString);

  final dynamic academyDetail = jsonList.firstWhere(
    (academy) => academy['학원지정번호'].toString().trim() == academyId.trim(),
    orElse: () => null,
  );
  if (academyDetail == null) {
    return null;
  }
  return academyDetail as Map<String, dynamic>;
}

Future<List<Map<String, dynamic>>> loadAcademyDataV2({
  required double lat,
  required double lon,
  double radiusKm = 3.0,
  int page = 1,
  int pageSize = 50,
}) async {
  // 변경: 커스텀 API URL 사용
  final baseUrl = await _getActiveApiBaseUrl();
  final apiKey = dotenv.env['API_KEY'];

  final uri =
      Uri.parse('$baseUrl/academies/nearbypaging').replace(queryParameters: {
    'lat': lat.toString(),
    'lon': lon.toString(),
    'radius_km': radiusKm.toString(),
    'page': page.toString(),
    'page_size': pageSize.toString(),
  });

  final headers = <String, String>{
    'Accept': 'application/json',
  };

  if (apiKey != null) {
    headers['x-api-key'] = apiKey;
  }

  // 디버깅용 로깅 추가
  print('🔥 API 호출 정보:');
  print('URL: $uri');
  print('Headers: $headers');

  final response = await http.get(uri, headers: headers);

  // 응답 로깅 추가
  print('Response status: ${response.statusCode}');
  print(
      'Response body (first 200 chars): ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');

  if (response.statusCode == 200) {
    try {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      print('JSON 파싱 에러: $e');
      print('Full response body: ${response.body}');
      throw Exception('JSON 파싱 실패: $e');
    }
  } else {
    throw Exception('근처 학원 불러오기 실패: ${response.statusCode} - ${response.body}');
  }
}
