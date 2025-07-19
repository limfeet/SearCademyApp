// =============================================================================
// 📄 lib/ads/ad_manager.dart
// =============================================================================

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_config.dart';

class AdManager {
  static AdManager? _instance;
  static AdManager get instance => _instance ??= AdManager._();

  AdManager._();

  // 광고 인스턴스 관리용 맵
  final Map<String, BannerAd> _bannerAds = {};
  final Map<String, InterstitialAd> _interstitialAds = {};
  int _adCounter = 0;

  // 광고 SDK 초기화
  static Future<void> initialize() async {
    // 기존 광고 인스턴스가 있다면 모두 정리
    if (_instance != null) {
      _instance!.disposeAllAds();
    }

    await MobileAds.instance.initialize();
    print('Google Mobile Ads SDK 초기화 완료');
  }

  // 모든 광고 정리
  void disposeAllAds() {
    print(
        '광고 정리 시작 - 배너: ${_bannerAds.length}, 전면: ${_interstitialAds.length}');

    for (var ad in _bannerAds.values) {
      try {
        ad.dispose();
      } catch (e) {
        print('배너 광고 정리 중 오류: $e');
      }
    }
    _bannerAds.clear();

    for (var ad in _interstitialAds.values) {
      try {
        ad.dispose();
      } catch (e) {
        print('전면 광고 정리 중 오류: $e');
      }
    }
    _interstitialAds.clear();

    // 카운터도 리셋
    _adCounter = 0;

    print('모든 광고 인스턴스 정리 완료');
  }

  // 배너 광고 생성
  BannerAd createBannerAd({
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    // 고유 ID 생성
    _adCounter++;
    final adId =
        'banner_${_adCounter}_${DateTime.now().millisecondsSinceEpoch}';

    // 기존 광고가 있다면 정리
    if (_bannerAds.containsKey(adId)) {
      _bannerAds[adId]?.dispose();
      _bannerAds.remove(adId);
    }

    final bannerAd = BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('배너 광고 로드 성공: $adId');
          onAdLoaded(ad);
        },
        onAdFailedToLoad: (ad, error) {
          print('배너 광고 로드 실패: $adId, $error');
          ad.dispose();
          _bannerAds.remove(adId);
          onAdFailedToLoad(ad, error);
        },
        onAdOpened: (ad) => print('배너 광고 열림'),
        onAdClosed: (ad) => print('배너 광고 닫힘'),
      ),
    );

    _bannerAds[adId] = bannerAd;
    return bannerAd;
  }

  // 전면 광고 생성
  void loadInterstitialAd({
    required Function(InterstitialAd) onAdLoaded,
    required Function(LoadAdError) onAdFailedToLoad,
  }) {
    // 고유 ID 생성
    _adCounter++;
    final adId =
        'interstitial_${_adCounter}_${DateTime.now().millisecondsSinceEpoch}';

    // 기존 광고가 있다면 정리
    if (_interstitialAds.containsKey(adId)) {
      _interstitialAds[adId]?.dispose();
      _interstitialAds.remove(adId);
    }

    InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('전면 광고 로드 성공: $adId');
          _interstitialAds[adId] = ad;
          onAdLoaded(ad);
        },
        onAdFailedToLoad: (error) {
          print('전면 광고 로드 실패: $adId, $error');
          _interstitialAds.remove(adId);
          onAdFailedToLoad(error);
        },
      ),
    );
  }

  // 특정 광고 제거 (내부 관리용)
  void _removeBannerAd(BannerAd ad) {
    _bannerAds.removeWhere((key, value) => value == ad);
  }

  void _removeInterstitialAd(InterstitialAd ad) {
    _interstitialAds.removeWhere((key, value) => value == ad);
  }
}
