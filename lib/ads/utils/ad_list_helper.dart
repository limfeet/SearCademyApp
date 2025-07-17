// =============================================================================
// 📄 lib/ads/utils/ad_list_helper.dart
// =============================================================================

import 'package:searcademy/ads/ad_config.dart';

class AdListHelper {
  /// 광고 위치인지 확인
  static bool isAdPosition(int index) {
    return index == 0 || (index > 0 && index % AdConfig.adInterval == 0);
  }

  /// 실제 데이터 인덱스 계산
  static int getDataIndex(int listIndex) {
    if (listIndex == 0) return -1; // 첫 번째는 광고

    final adCount = (listIndex / AdConfig.adInterval).floor();
    return listIndex - adCount - 1;
  }

  /// 전체 아이템 개수 계산 (데이터 + 광고 + 로딩)
  static int getTotalItemCount(int dataCount, bool isLoading) {
    if (dataCount == 0) return 0;

    final adCount = (dataCount / 5).ceil() + 1; // 최초 광고 포함
    return dataCount + adCount + (isLoading ? 1 : 0);
  }

  /// 로딩 인디케이터 위치인지 확인
  static bool isLoadingPosition(int index, int totalItems, bool isLoading) {
    return isLoading && index == totalItems - 1;
  }

  /// 데이터 범위 유효성 검사
  static bool isValidDataIndex(int dataIndex, int dataCount) {
    return dataIndex >= 0 && dataIndex < dataCount;
  }
}
