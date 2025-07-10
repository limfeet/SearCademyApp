import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:searcademy/pages/widgets/appdrawer.dart';
import 'package:searcademy/pages/widgets/map_dialog.dart';
import 'package:searcademy/pages/widgets/recent_search_keywords.dart';
import 'package:searcademy/repositories/location/location_provider.dart';
import 'package:searcademy/controller/drawer_controller.dart';
import 'package:searcademy/repositories/providers/scaffoldstate_provider.dart';

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
    final baseUrl = dotenv.env['ES_NEARBY_REST_API_URL'];
    final apiKey = dotenv.env['API_KEY']; // 추가
    if (baseUrl == null) {
      throw Exception('환경 변수 ES_NEARBY_REST_API_URL이 설정되지 않았습니다.');
    }
    if (apiKey == null) {
      // 추가
      throw Exception('환경 변수 API_KEY가 설정되지 않았습니다.');
    }
    final params = {
      'lat': lat.toString(),
      'lon': lon.toString(),
      'radius_km': radiusKm.toString(),
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    if (keyword.isNotEmpty) {
      params['keyword'] = keyword;
    }

    final uri = Uri.parse(baseUrl).replace(queryParameters: params);
    final response = await http.get(
      uri,
      headers: {
        // 추가
        'x-api-key': apiKey,
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('근처 학원 불러오기 실패');
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
