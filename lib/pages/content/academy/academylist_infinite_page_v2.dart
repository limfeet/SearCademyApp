// 📄 lib/pages/infinite_scroll_page_v3.dart

import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// 기존 import들
import 'package:searcademy/pages/widgets/appdrawer.dart';
import 'package:searcademy/pages/widgets/map_dialog.dart';
import 'package:searcademy/pages/widgets/recent_search_keywords.dart';
import 'package:searcademy/repositories/location/location_provider.dart';
import 'package:searcademy/controller/drawer_controller.dart';
import 'package:searcademy/repositories/providers/scaffoldstate_provider.dart';
import 'package:searcademy/services/api_client_service.dart';
import 'package:searcademy/utils/error_handler.dart';

// 광고 관련 import들 (ads 폴더에서)
import 'package:searcademy/ads/ad_manager.dart';
import 'package:searcademy/ads/utils/ad_list_helper.dart';
import 'package:searcademy/ads/widgets/banner_ad_widget.dart';

class InfiniteScrollPageV3 extends ConsumerStatefulWidget {
  const InfiniteScrollPageV3({super.key});

  @override
  ConsumerState<InfiniteScrollPageV3> createState() =>
      _InfiniteScrollPageV3State();
}

class _InfiniteScrollPageV3State extends ConsumerState<InfiniteScrollPageV3> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ApiClientService _apiClient = ApiClientService();

  List<Map<String, dynamic>> visibleItems = [];
  List<String> recentKeywords = [];

  bool isLoading = false;
  bool hasMore = true;
  int page = 1;
  final int pageSize = 50;
  double? lat;
  double? lon;
  String searchQuery = "";
  double radiusKm = 3.0;
  bool showRecent = false;

  // 광고 관련 변수들 (최소화)
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    initLoad();
    _scrollController.addListener(_onScroll);
    _loadBannerAd(); // 광고 로드
  }

  /// 광고 로드 (간소화됨)
  void _loadBannerAd() {
    _bannerAd = AdManager.instance.createBannerAd(
      onAdLoaded: (_) => setState(() => _isBannerAdReady = true),
      onAdFailedToLoad: (ad, err) {
        print('배너 광고 로드 실패: ${err.message}');
        setState(() => _isBannerAdReady = false);
        ad.dispose();
      },
    );
    _bannerAd?.load();
  }

  // ... 기존의 모든 비즈니스 로직들 (그대로 유지)
  Future<void> initLoad() async {
    final (loadedLat, loadedLon) = await ref.read(locationProvider.future);
    lat = loadedLat;
    lon = loadedLon;
    await _loadMoreItems();
  }

  Future<List<Map<String, dynamic>>> loadAcademyDataV2({
    required double lat,
    required double lon,
    double radiusKm = 3.0,
    int page = 1,
    int pageSize = 50,
    String keyword = "",
  }) async {
    // 기존 코드 그대로...
    String baseUrl;
    Map<String, String> params;
    bool isElasticsearch = false;

    if (keyword.isNotEmpty) {
      baseUrl = dotenv.env['ES_SEARCH_API_URL'] ??
          'http://localhost:18181/search/advanced';
      params = {
        'keyword': keyword,
        'lat': lat.toString(),
        'lon': lon.toString(),
        'radius_km': radiusKm.toString(),
        'limit': pageSize.toString(),
      };
      isElasticsearch = true;
    } else {
      baseUrl = dotenv.env['MONGODB_NEARBY_API_URL'] ??
          'http://localhost:18181/academies/nearbypaging';
      params = {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'radius_km': radiusKm.toString(),
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };
    }

    final response = await _apiClient.get(baseUrl, queryParameters: params);
    final jsonData = json.decode(response.body);

    if (isElasticsearch) {
      if (jsonData['success'] == true && jsonData['data'] != null) {
        final List<dynamic> esData = jsonData['data'];
        return esData.map<Map<String, dynamic>>((item) {
          return {
            'ACA_ASNUM': item['aca_asnum'],
            'ATPT_OFCDC_SC_CODE': item['atpt_ofcdc_sc_code'],
            'ACA_NM': item['aca_name'],
            'FA_RDNMA': item['address'],
            'location': {
              'type': 'Point',
              'coordinates': [item['location']['lon'], item['location']['lat']]
            }
          };
        }).toList();
      } else {
        return [];
      }
    } else {
      final List<dynamic> data = jsonData;
      return data.cast<Map<String, dynamic>>();
    }
  }

  Future<void> _loadMoreItems() async {
    if (isLoading || !hasMore || lat == null || lon == null) return;

    setState(() => isLoading = true);

    try {
      final newItems = await loadAcademyDataV2(
        lat: lat!,
        lon: lon!,
        radiusKm: radiusKm,
        page: page,
        pageSize: pageSize,
        keyword: searchQuery,
      );

      setState(() {
        visibleItems.addAll(newItems);
        isLoading = false;
        page += 1;
        if (newItems.length < pageSize) {
          hasMore = false;
        }
      });
    } catch (e) {
      print("에러: $e");
      setState(() => isLoading = false);
      if (mounted) {
        ErrorHandler.handleApiError(context, e);
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }

  void _startSearch(String query) {
    setState(() {
      searchQuery = query.trim();
      _addToRecent(searchQuery);
      page = 1;
      visibleItems.clear();
      hasMore = true;
    });
    _loadMoreItems();
  }

  void _addToRecent(String keyword) {
    if (keyword.isEmpty) return;
    recentKeywords.remove(keyword);
    recentKeywords.insert(0, keyword);
    if (recentKeywords.length > 5) {
      recentKeywords = recentKeywords.sublist(0, 5);
    }
  }

  void _changeLocation(double newLat, double newLon) {
    setState(() {
      lat = newLat;
      lon = newLon;
      page = 1;
      visibleItems.clear();
      hasMore = true;
    });
    _loadMoreItems();
  }

  final Random _random = Random();
  Color getRandomColor() {
    return Color.fromARGB(
      255,
      _random.nextInt(256),
      _random.nextInt(256),
      _random.nextInt(256),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _bannerAd?.dispose(); // 광고 정리
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drawerController = ref.read(drawerControllerProvider.notifier);
    final scaffoldKey = ref.watch(scaffoldKeyProvider);
    final totalItems =
        AdListHelper.getTotalItemCount(visibleItems.length, isLoading);

    return Scaffold(
      key: scaffoldKey,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text("학원찾기앱"),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => drawerController.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => LocationSettingDialog(
                  onLocationSelected: (latLng) {
                    print("선택된 위치: ${latLng.latitude}, ${latLng.longitude}");
                    _changeLocation(latLng.latitude, latLng.longitude);
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색 UI (기존 코드 그대로)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: '학원명 또는 주소 검색',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search, color: Colors.white70),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onTap: () => setState(() => showRecent = true),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        setState(() => showRecent = true);
                      }
                    },
                    onSubmitted: (value) {
                      _searchFocusNode.unfocus();
                      setState(() => showRecent = false);
                      _startSearch(value);
                    },
                  ),
                ),
                if (showRecent)
                  RecentSearchKeywords(
                    keywords: recentKeywords,
                    onKeywordTap: (word) {
                      _searchController.text = word;
                      _startSearch(word);
                      _searchFocusNode.unfocus();
                      setState(() => showRecent = false);
                    },
                  ),
              ],
            ),
          ),
          // 리스트 (광고 포함)
          Expanded(
            child: visibleItems.isEmpty && !isLoading
                ? const Center(child: Text("검색 결과 없음"))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: totalItems,
                    itemBuilder: (context, index) {
                      // 광고 위치 확인 (ads 폴더의 헬퍼 사용)
                      if (AdListHelper.isAdPosition(index)) {
                        return BannerAdWidget(
                          adUnitId: Platform.isAndroid
                              ? 'ca-app-pub-3940256099942544/6300978111' // Android 테스트
                              : 'ca-app-pub-3940256099942544/2934735716', // iOS 테스트
                        );
                      }

                      // 로딩 인디케이터 확인
                      if (AdListHelper.isLoadingPosition(
                          index, totalItems, isLoading)) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      // 실제 데이터 처리
                      final dataIndex = AdListHelper.getDataIndex(index);

                      if (AdListHelper.isValidDataIndex(
                          dataIndex, visibleItems.length)) {
                        final item = visibleItems[dataIndex];
                        final name = item["ACA_NM"] ?? "이름 없음";
                        final initials =
                            name.isNotEmpty ? name.substring(0, 1) : "학";

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: getRandomColor(),
                            child: Text(initials),
                          ),
                          title: Text(item["ACA_NM"] ?? "이름 없음"),
                          subtitle: Text(item["FA_RDNMA"] ?? "주소 없음"),
                          onTap: () {
                            context.push(
                                '/academyList/academyDetail/${item["ATPT_OFCDC_SC_CODE"]}/${item["ACA_ASNUM"]}');
                          },
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
