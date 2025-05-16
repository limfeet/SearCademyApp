import 'dart:convert';
import 'package:flutter/services.dart';

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
