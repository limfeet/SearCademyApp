import 'package:firebase_auth/firebase_auth.dart';

/// Firebase JWT 토큰 관리 서비스
class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  /// 현재 사용자의 JWT 토큰 가져오기
  /// 자동으로 갱신된 최신 토큰을 반환
  Future<String?> getFirebaseToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return await user.getIdToken(true); // 강제 갱신
      }
      return null;
    } catch (e) {
      print('Firebase 토큰 가져오기 실패: $e');
      return null;
    }
  }

  /// 사용자 로그인 상태 확인
  bool isUserLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }

  /// 현재 사용자 정보 가져오기
  User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  /// 로그아웃
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}
