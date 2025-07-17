// =============================================================================
// 📄 lib/ads/widgets/interstitial_ad_helper.dart
// =============================================================================

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:searcademy/ads/ad_manager.dart';

class InterstitialAdHelper {
  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;

  void loadAd() {
    AdManager.instance.loadInterstitialAd(
      onAdLoaded: (ad) {
        _interstitialAd = ad;
        _isAdReady = true;

        ad.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _isAdReady = false;
            loadAd(); // 새 광고 미리 로드
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            _isAdReady = false;
            loadAd(); // 재시도
          },
        );
      },
      onAdFailedToLoad: (error) {
        print('전면 광고 로드 실패: ${error.message}');
        _isAdReady = false;
      },
    );
  }

  void showAd() {
    if (_isAdReady && _interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      print('전면 광고가 준비되지 않음');
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
  }

  bool get isReady => _isAdReady;
}
