class AcademyPaginationController {
  final int pageSize;
  int currentPage = 0;
  bool isLoading = false;

  AcademyPaginationController({this.pageSize = 50});

  List<Map<String, dynamic>> getNextPage(List<Map<String, dynamic>> allData) {
    int start = currentPage * pageSize;
    int end = start + pageSize;
    if (start >= allData.length) return [];

    currentPage++;
    return allData.sublist(start, end > allData.length ? allData.length : end);
  }
}
