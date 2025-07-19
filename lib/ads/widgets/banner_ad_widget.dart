// =============================================================================
// 📄 lib/ads/widgets/banner_ad_widget.dart
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:searcademy/ads/ad_manager.dart';

class BannerAdWidget extends StatefulWidget {
  final String adUnitId;
  final AdSize adSize;

  const BannerAdWidget({
    super.key,
    this.adUnitId = '', // 기본값 제공
    this.adSize = AdSize.banner,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (_isDisposed) return;

    // 기존 광고 정리
    _bannerAd?.dispose();
    _bannerAd = null;
    _isAdLoaded = false;

    // 잠시 대기 후 새 광고 생성 (중복 방지)
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_isDisposed) return;

      // AdManager를 통해 광고 생성
      _bannerAd = AdManager.instance.createBannerAd(
        onAdLoaded: (ad) {
          if (!_isDisposed && mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          print('BannerAd failed to load: $error');
          if (!_isDisposed && mounted) {
            setState(() {
              _isAdLoaded = false;
            });
          }
        },
      );

      _bannerAd?.load();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdLoaded && _bannerAd != null && !_isDisposed) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          color: Colors.grey[50],
        ),
        height: _bannerAd!.size.height.toDouble(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: AdWidget(ad: _bannerAd!),
        ),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.ads_click, color: Colors.grey, size: 16),
            SizedBox(width: 8),
            Text(
              '광고',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
