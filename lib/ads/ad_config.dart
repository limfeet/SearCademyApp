// =============================================================================
// 📄 lib/ads/ad_config.dart
// =============================================================================

import 'dart:io';

class AdConfig {
  // 테스트 광고 ID들
  static const String _testBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIOS = 'ca-app-pub-3940256099942544/2934735716';
  static const String _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIOS =
      'ca-app-pub-3940256099942544/4411468910';

  // 실제 광고 ID들 (배포시 사용)
  static const String _prodBannerAndroid =
      'ca-app-pub-YOUR_REAL_ID/banner_android';
  static const String _prodBannerIOS = 'ca-app-pub-YOUR_REAL_ID/banner_ios';
  static const String _prodInterstitialAndroid =
      'ca-app-pub-YOUR_REAL_ID/interstitial_android';
  static const String _prodInterstitialIOS =
      'ca-app-pub-YOUR_REAL_ID/interstitial_ios';

  // 테스트 모드 플래그
  static const bool isTestMode = true; // 배포시 false로 변경

  // 배너 광고 ID
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return isTestMode ? _testBannerAndroid : _prodBannerAndroid;
    } else {
      return isTestMode ? _testBannerIOS : _prodBannerIOS;
    }
  }

  // 전면 광고 ID
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return isTestMode ? _testInterstitialAndroid : _prodInterstitialAndroid;
    } else {
      return isTestMode ? _testInterstitialIOS : _prodInterstitialIOS;
    }
  }

  // 광고 설정
  static const int adInterval = 6; // 6개마다 광고 (최초 1개 + 5개 아이템마다)
  static const Duration adLoadTimeout = Duration(seconds: 10);
}
