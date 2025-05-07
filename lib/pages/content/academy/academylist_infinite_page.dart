import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:searcademy/controller/pagination_controller.dart';
import 'package:searcademy/services/academy_service.dart';

class InfiniteScrollPage extends StatefulWidget {
  const InfiniteScrollPage({super.key});

  @override
  State<InfiniteScrollPage> createState() =>
      _InfiniteScrollPageState(); // 리턴 타입 명시
}

class _InfiniteScrollPageState extends State<InfiniteScrollPage> {
  late AcademyPaginationController _pager;
  List<Map<String, dynamic>> allData = [];
  List<Map<String, dynamic>> visibleItems = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  List<String> recentKeywords = [];
  final FocusNode _searchFocusNode = FocusNode();
  bool _showRecent = false;

  @override
  void initState() {
    super.initState();
    _pager = AcademyPaginationController(pageSize: 50);
    loadData();
    _scrollController.addListener(_onScroll);
  }

  Future<void> loadData() async {
    allData = await loadAcademyData();
    _loadMoreItems();
  }

  void _loadMoreItems() {
    if (_pager.isLoading) return;
    setState(() => _pager.isLoading = true);

    Future.delayed(Duration(milliseconds: 300), () {
      // ✅ 검색어에 맞는 데이터로 필터링
      final filteredData = _searchQuery.isEmpty
          ? allData
          : allData.where((item) {
              final name = (item["학원명"] ?? "").toString().toLowerCase();
              final address = (item["도로명주소"] ?? "").toString().toLowerCase();
              return name.contains(_searchQuery.toLowerCase()) ||
                  address.contains(_searchQuery.toLowerCase());
            }).toList();

      // ✅ 그 필터링된 데이터 기준으로 페이징
      final nextItems = _pager.getNextPage(filteredData);
      setState(() {
        if (nextItems.isNotEmpty) {
          visibleItems.addAll(nextItems);
        }
        _pager.isLoading = false; // ✅ 무조건 호출해줘야 함
      });
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }

  void _addToRecent(String keyword) {
    if (keyword.isEmpty) return;
    recentKeywords.remove(keyword); // 중복 제거
    recentKeywords.insert(0, keyword); // 가장 앞에 추가
    if (recentKeywords.length > 5) {
      recentKeywords = recentKeywords.sublist(0, 5); // 최대 5개
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('무한 스크롤 학원 리스트')),
      body: Column(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  focusNode: _searchFocusNode,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '학원명 또는 주소 검색',
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: Colors.white70),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onTap: () {
                    setState(() {
                      _showRecent = true;
                    });
                  },
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim();
                      _pager = AcademyPaginationController(pageSize: 50);
                      visibleItems.clear();
                      _loadMoreItems();
                    });
                  },
                  onSubmitted: (value) {
                    _addToRecent(value.trim());
                    _searchFocusNode.unfocus();
                    setState(() => _showRecent = false);
                  },
                ),
              ),
            ),
          ),
          if (_showRecent && recentKeywords.isNotEmpty)
            Container(
              color: Colors.grey[900],
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("최근 검색어", style: TextStyle(color: Colors.white70)),
                  ...recentKeywords.map((word) => ListTile(
                        title:
                            Text(word, style: TextStyle(color: Colors.white)),
                        onTap: () {
                          _searchController.text = word;
                          _searchQuery = word;
                          _addToRecent(word);
                          _pager = AcademyPaginationController(pageSize: 50);
                          visibleItems.clear();
                          _loadMoreItems();
                          setState(() => _showRecent = false);
                          _searchFocusNode.unfocus();
                        },
                      )),
                ],
              ),
            ),
          Expanded(
            child: visibleItems.isEmpty && !_pager.isLoading
                ? Center(
                    child: Text(
                      '검색 결과가 없습니다.',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: visibleItems.length + 1,
                    itemBuilder: (context, index) {
                      if (index < visibleItems.length) {
                        final item = visibleItems[index];
                        return ListTile(
                          title: Text(item["학원명"] ?? "이름 없음"),
                          subtitle: Text(item["도로명주소"] ?? "주소 없음"),
                          trailing: IconButton(
                            icon: Icon(Icons.arrow_forward),
                            onPressed: () {
                              // 화살표 클릭 시 상세 페이지로 이동
                              context.push(
                                  '/academyList/academyListDetail/${item["학원지정번호"]}');
                            },
                          ),
                          onTap: () {
                            // 다른 액션을 추가할 수 있는 공간 (예: 리스트 아이템 전체 클릭 시 다른 동작)
                            // 예시로 리스트 전체 클릭 시 다른 행동 추가 가능
                            print('리스트 아이템 클릭됨');
                          },
                        );
                      } else {
                        return _pager.isLoading
                            ? Padding(
                                padding: const EdgeInsets.all(16.0),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              )
                            : SizedBox.shrink();
                      }
                    },
                  ),
          )
        ],
      ),
    );
  }
}
