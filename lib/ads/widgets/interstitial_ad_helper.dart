// =============================================================================
// 📄 lib/ads/widgets/interstitial_ad_helper.dart
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:searcademy/ads/ad_manager.dart';

class InterstitialAdHelper {
  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;
  bool _isDisposed = false;

  InterstitialAdHelper() {
    // 초기화 시 기존 광고 정리
    _cleanupAd();
  }

  void _cleanupAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdReady = false;
  }

  void loadAd() {
    if (_isDisposed) return;

    // 기존 광고 정리
    _cleanupAd();

    AdManager.instance.loadInterstitialAd(
      onAdLoaded: (ad) {
        if (_isDisposed) {
          ad.dispose();
          return;
        }

        _interstitialAd = ad;
        _isAdReady = true;

        ad.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            debugPrint('전면 광고 닫힘');
            ad.dispose();
            _isAdReady = false;
            _interstitialAd = null;

            // 새 광고 미리 로드 (딜레이 추가)
            if (!_isDisposed) {
              Future.delayed(const Duration(seconds: 1), () {
                if (!_isDisposed) {
                  loadAd();
                }
              });
            }
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            debugPrint('전면 광고 표시 실패: $error');
            ad.dispose();
            _isAdReady = false;
            _interstitialAd = null;

            // 재시도
            if (!_isDisposed) {
              Future.delayed(const Duration(seconds: 2), () {
                if (!_isDisposed) {
                  loadAd();
                }
              });
            }
          },
          onAdShowedFullScreenContent: (ad) {
            debugPrint('전면 광고 표시됨');
          },
        );
      },
      onAdFailedToLoad: (error) {
        debugPrint('전면 광고 로드 실패: ${error.message}');
        _isAdReady = false;
        _interstitialAd = null;
      },
    );
  }

  void showAd() {
    if (_isAdReady && _interstitialAd != null && !_isDisposed) {
      _interstitialAd!.show();
    } else {
      debugPrint('전면 광고가 준비되지 않음');
    }
  }

  void dispose() {
    _isDisposed = true;
    _cleanupAd();
  }

  bool get isReady => _isAdReady && !_isDisposed;
}
