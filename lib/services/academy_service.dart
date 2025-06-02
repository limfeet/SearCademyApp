import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

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

  // academyId와 일치하는 학원만 찾기
  final dynamic academyDetail = jsonList.firstWhere(
    (academy) => academy['학원지정번호'].toString().trim() == academyId.trim(),
    orElse: () => null, // 없으면 null 반환
  );
  if (academyDetail == null) {
    return null; // academyId에 해당하는 학원이 없으면 null 반환
  }
  return academyDetail as Map<String, dynamic>; // 타입 변환
}

Future<List<Map<String, dynamic>>> loadAcademyDataV2({
  required double lat,
  required double lon,
  double radiusKm = 3.0,
  int page = 1,
  int pageSize = 50,
}) async {
  final baseUrl = dotenv.env['ES_NEARBY_REST_API_URL'];
  if (baseUrl == null) {
    throw Exception('환경 변수 ES_NEARBY_REST_API_URL이 설정되지 않았습니다.');
  }

  final uri = Uri.parse(baseUrl).replace(queryParameters: {
    'lat': lat.toString(),
    'lon': lon.toString(),
    'radius_km': radiusKm.toString(),
    'page': page.toString(),
    'page_size': pageSize.toString(),
  });

  final response = await http.get(uri);

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('근처 학원 불러오기 실패');
  }
}
