// firebase_service.dart
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:searcademy/firebase_options.dart';
// main.dart 또는 firebase_service.dart 안에 import
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// 백그라운드 메시지 핸들러 (최상위 함수여야 함)
@pragma('vm:entry-point') // ← 이거 추가
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint("백그라운드 메시지 처리: ${message.messageId}");
  // 필요에 따라 백그라운드에서 알림 처리 로직 구현
}

// 알림 데이터에서 타입을 추출하는 유틸리티 함수
String? _getMessageType(RemoteMessage message) {
  if (message.data.containsKey('type')) {
    return message.data['type'] as String?;
  }
  if (message.notification?.title?.contains('공지') == true) {
    return 'notice';
  }
  // 다른 알림 종류에 대한 규칙 추가 가능
  return null;
}

// 공지 알림 처리 핸들러
void _handleNoticeMessage(RemoteMessage message) {
  debugPrint(
      '공지 알림 처리: ${message.notification?.title}, ${message.notification?.body}, 데이터: ${message.data}');
  // 공지 알림 관련 UI 업데이트 또는 로컬 알림 표시 등
}

// 일반 알림 처리 핸들러
void _handleGeneralMessage(RemoteMessage message) {
  debugPrint(
      '일반 알림 처리: ${message.notification?.title}, ${message.notification?.body}, 데이터: ${message.data}');
  // 일반 알림 처리 로직
}

class FirebaseService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final Map<String?, Function(RemoteMessage)> _messageHandlers = {
    'notice': _handleNoticeMessage,
    null: _handleGeneralMessage, // 기본 핸들러
    // 다른 알림 타입에 대한 핸들러 추가
  };
  static late FirebaseAnalytics analytics;

  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await requestNotificationPermission();
    await initializeNotificationChannel();
    analytics = FirebaseAnalytics.instance;
    debugPrint('Firebase 앱이 초기화되었습니다.');
    // 백그라운드 메시지 핸들러 설정
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("포그라운드 메시지 수신: ${message.messageId}");
      debugPrint("포그라운드에서 받은 알림 (전체 메시지): $message");
      final AndroidNotification? android = message.notification?.android;
      if (android != null) {
        debugPrint("포그라운드에서 받은 알림 (안드로이드): ${android.channelId}");
      }
      if (message.notification != null) {
        debugPrint("포그라운드에서 받은 알림 (제목): ${message.notification?.title}");
        debugPrint("포그라운드에서 받은 알림 (본문): ${message.notification?.body}");
      }
      final type = _getMessageType(message);
      if (_messageHandlers.containsKey(type)) {
        _messageHandlers[type]!(message);
      } else {
        _messageHandlers[null]!(message); // 등록되지 않은 타입은 기본 핸들러로
      }
    });

    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      debugPrint("앱이 종료된 상태에서 메시지 처리: ${message?.messageId}");
      if (message != null) {
        final type = _getMessageType(message);
        if (_messageHandlers.containsKey(type)) {
          _messageHandlers[type]!(message);
        } else {
          _messageHandlers[null]!(message);
        }
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("앱이 열릴 때 메시지 처리: ${message.messageId}");
      final type = _getMessageType(message);
      if (_messageHandlers.containsKey(type)) {
        _messageHandlers[type]!(message);
      } else {
        _messageHandlers[null]!(message);
      }
    });
  }

  static Future<String?> getFCMToken() async {
    try {
      // 시뮬레이터에서는 APNs 토큰 없음 → FCM 토큰도 못 받음
      if (kIsWeb) {
        debugPrint('웹 환경에서는 FCM 사용 불가');
        return null;
      }

      if (Platform.isIOS) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          debugPrint('시뮬레이터 또는 APNs 미설정 상태 - FCM 토큰 요청 생략');
          return null;
        }
      }

      String? token = await _messaging.getToken();
      debugPrint("FCM Token: $token");
      return token;
    } catch (e) {
      debugPrint('FCM 토큰 요청 중 오류 발생: $e');
      return null;
    }
  }

  // 특정 토픽 구독
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('토픽 "$topic"을 구독했습니다.');
    } catch (e) {
      debugPrint('토픽 "$topic" 구독에 실패했습니다: $e');
    }
  }

  // 특정 토픽 구독 해제
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('토픽 "$topic" 구독을 해제했습니다.');
    } catch (e) {
      debugPrint('토픽 "$topic" 구독 해제에 실패했습니다: $e');
    }
  }

  // 앱 시작 시 호출 (initializeFirebase 내부에 넣어도 됨)
  static Future<void> initializeNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'default_channel', // ⚠️ 이 이름은 AndroidManifest.xml에 지정한 채널과 같아야 함
      '기본 알림 채널',
      description: '일반 알림을 위한 기본 채널입니다.',
      importance: Importance.high,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    debugPrint('✅ 알림 채널 default_channel 생성 완료');
  }

  // 필요에 따라 다른 FCM 관련 기능 (예: 특정 토픽 구독/해제)을 추가할 수 있습니다.
  static Future<void> requestNotificationPermission() async {
    if (!Platform.isAndroid) return;

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 33) {
      final status = await Permission.notification.status;
      if (status.isDenied || status.isRestricted) {
        final result = await Permission.notification.request();
        if (result.isGranted) {
          debugPrint("🔔 알림 권한 허용됨");
        } else {
          debugPrint("❌ 알림 권한 거부됨");
          // 안내 팝업 등 추가 가능
        }
      } else {
        debugPrint("✅ 이미 권한 있음");
      }
    } else {
      debugPrint("이 기기는 Android 13 미만입니다. 알림 권한 요청 생략.");
    }
  }

  static Future<void> logScreenView({required String screenName}) async {
    await analytics.logScreenView(
      screenName: screenName,
      screenClass: screenName,
    );
  }
}
