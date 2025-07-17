// =============================================================================
// 📄 lib/ads/ad_manager.dart
// =============================================================================

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_config.dart';

class AdManager {
  static AdManager? _instance;
  static AdManager get instance => _instance ??= AdManager._();

  AdManager._();

  // 광고 SDK 초기화
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  // 배너 광고 생성
  BannerAd createBannerAd({
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
        onAdOpened: (ad) => print('배너 광고 열림'),
        onAdClosed: (ad) => print('배너 광고 닫힘'),
      ),
    );
  }

  // 전면 광고 생성
  void loadInterstitialAd({
    required Function(InterstitialAd) onAdLoaded,
    required Function(LoadAdError) onAdFailedToLoad,
  }) {
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    );
  }
}
