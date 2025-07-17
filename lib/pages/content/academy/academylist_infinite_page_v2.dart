import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:searcademy/pages/widgets/appdrawer.dart';
import 'package:searcademy/pages/widgets/map_dialog.dart';
import 'package:searcademy/pages/widgets/recent_search_keywords.dart';
import 'package:searcademy/repositories/location/location_provider.dart';
import 'package:searcademy/controller/drawer_controller.dart';
import 'package:searcademy/repositories/providers/scaffoldstate_provider.dart';
import 'package:searcademy/services/api_client_service.dart'; // 추가
import 'package:searcademy/utils/error_handler.dart'; // 추가

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
  final ApiClientService _apiClient = ApiClientService(); // 추가

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

  @override
  void initState() {
    super.initState();
    initLoad();
    _scrollController.addListener(_onScroll);
  }

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
    String baseUrl;
    Map<String, String> params;
    bool isElasticsearch = false;

    if (keyword.isNotEmpty) {
      // Elasticsearch 검색 사용
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
      // MongoDB 근처 학원 조회 사용
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

    // 모듈화된 API 클라이언트 사용
    final response = await _apiClient.get(baseUrl, queryParameters: params);
    final jsonData = json.decode(response.body);

    if (isElasticsearch) {
      // Elasticsearch 응답 처리
      if (jsonData['success'] == true && jsonData['data'] != null) {
        final List<dynamic> esData = jsonData['data'];

        // ES 데이터를 MongoDB 형식으로 변환
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
      // MongoDB 응답 처리 (기존 방식)
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

      // 모듈화된 에러 처리 사용
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drawerController = ref.read(drawerControllerProvider.notifier);
    final scaffoldKey = ref.watch(scaffoldKeyProvider);

    return Scaffold(
      key: scaffoldKey,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text("학원찾기앱"),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            drawerController.openDrawer();
          },
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
          Expanded(
            child: visibleItems.isEmpty && !isLoading
                ? const Center(child: Text("검색 결과 없음"))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: visibleItems.length + 1,
                    itemBuilder: (context, index) {
                      if (index < visibleItems.length) {
                        final item = visibleItems[index];
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
                      } else {
                        return isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              )
                            : const SizedBox.shrink();
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
