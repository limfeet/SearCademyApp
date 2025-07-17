import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:searcademy/services/api_client_service.dart';

/// 에러 처리를 위한 유틸리티 클래스
class ErrorHandler {
  /// API 에러를 처리하고 적절한 다이얼로그 표시
  static void handleApiError(BuildContext context, dynamic error) {
    if (error is ReloginRequiredException) {
      _showReloginDialog(context, error.message);
    } else if (error is AuthException) {
      _showAuthErrorDialog(context, error.message);
    } else if (error is ApiException) {
      _showGeneralErrorDialog(context, error.message);
    } else {
      _showGeneralErrorDialog(
          context, '알 수 없는 오류가 발생했습니다: ${error.toString()}');
    }
  }

  /// 재로그인 필요 다이얼로그
  static void _showReloginDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('재로그인 필요'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 8),
            const Text(
              '보안을 위해 다시 로그인해주세요.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 로그인 화면으로 이동
              context.go('/auth/signin');
            },
            child: const Text('로그인하기'),
          ),
        ],
      ),
    );
  }

  /// 일반 인증 에러 다이얼로그
  static void _showAuthErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('인증 오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/auth/signin');
            },
            child: const Text('로그인하기'),
          ),
        ],
      ),
    );
  }

  /// 일반 에러 다이얼로그
  static void _showGeneralErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 스낵바로 간단한 에러 메시지 표시
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: '확인',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
