import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:searcademy/services/firebase_auth_service.dart';

/// API 호출을 위한 클라이언트 서비스
class ApiClientService {
  static final ApiClientService _instance = ApiClientService._internal();
  factory ApiClientService() => _instance;
  ApiClientService._internal();

  final FirebaseAuthService _authService = FirebaseAuthService();

  /// 인증된 HTTP GET 요청
  /// API 키와 Firebase JWT 토큰을 자동으로 헤더에 추가
  Future<http.Response> get(
    String url, {
    Map<String, String>? queryParameters,
    Map<String, String>? additionalHeaders,
  }) async {
    final apiKey = dotenv.env['API_KEY'];
    if (apiKey == null) {
      throw ApiException('환경 변수 API_KEY가 설정되지 않았습니다.');
    }

    // Firebase JWT 토큰 가져오기
    final firebaseToken = await _authService.getFirebaseToken();
    if (firebaseToken == null) {
      throw AuthException('Firebase 인증이 필요합니다. 다시 로그인해주세요.');
    }

    final uri = Uri.parse(url).replace(queryParameters: queryParameters);

    final headers = {
      'x-api-key': apiKey,
      'Authorization': 'Bearer $firebaseToken',
      'Content-Type': 'application/json',
      ...?additionalHeaders,
    };

    final response = await http.get(uri, headers: headers);

    // 401 에러 처리
    if (response.statusCode == 401) {
      final errorData = json.decode(response.body);
      final errorMessage = errorData['detail'] ?? '인증이 만료되었습니다.';

      if (errorMessage.contains('로그인한지') && errorMessage.contains('지났습니다')) {
        throw ReloginRequiredException(errorMessage);
      } else {
        throw AuthException(errorMessage);
      }
    }

    // 기타 HTTP 에러 처리
    if (response.statusCode >= 400) {
      throw ApiException('API 호출 실패: ${response.statusCode}');
    }

    return response;
  }

  /// 인증된 HTTP POST 요청
  Future<http.Response> post(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? additionalHeaders,
  }) async {
    final apiKey = dotenv.env['API_KEY'];
    if (apiKey == null) {
      throw ApiException('환경 변수 API_KEY가 설정되지 않았습니다.');
    }

    final firebaseToken = await _authService.getFirebaseToken();
    if (firebaseToken == null) {
      throw AuthException('Firebase 인증이 필요합니다. 다시 로그인해주세요.');
    }

    final headers = {
      'x-api-key': apiKey,
      'Authorization': 'Bearer $firebaseToken',
      'Content-Type': 'application/json',
      ...?additionalHeaders,
    };

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body != null ? json.encode(body) : null,
    );

    if (response.statusCode == 401) {
      final errorData = json.decode(response.body);
      final errorMessage = errorData['detail'] ?? '인증이 만료되었습니다.';

      if (errorMessage.contains('로그인한지') && errorMessage.contains('지났습니다')) {
        throw ReloginRequiredException(errorMessage);
      } else {
        throw AuthException(errorMessage);
      }
    }

    if (response.statusCode >= 400) {
      throw ApiException('API 호출 실패: ${response.statusCode}');
    }

    return response;
  }
}

/// API 관련 예외 클래스들
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

class ReloginRequiredException implements Exception {
  final String message;
  ReloginRequiredException(this.message);

  @override
  String toString() => 'ReloginRequiredException: $message';
}
