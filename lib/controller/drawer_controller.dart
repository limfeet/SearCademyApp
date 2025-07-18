import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:searcademy/repositories/providers/navi_index_provider.dart';

// 개선된 DrawerController - 각 탭별로 독립적인 드로어 컨트롤
class DrawerController extends StateNotifier<bool> {
  DrawerController() : super(false);

  // 특정 스캐폴드 키를 사용하여 드로어 열기
  void openDrawer({GlobalKey<ScaffoldState>? scaffoldKey}) {
    if (scaffoldKey?.currentState != null) {
      scaffoldKey!.currentState!.openDrawer();
      state = true;
    }
  }

  // 특정 스캐폴드 키를 사용하여 드로어 닫기
  void closeDrawer({GlobalKey<ScaffoldState>? scaffoldKey}) {
    if (scaffoldKey?.currentState != null &&
        (scaffoldKey!.currentState!.isDrawerOpen)) {
      scaffoldKey.currentState!.closeDrawer();
      state = false;
    }
  }

  // 드로어 토글
  void toggleDrawer({GlobalKey<ScaffoldState>? scaffoldKey}) {
    if (scaffoldKey?.currentState != null) {
      if (scaffoldKey!.currentState!.isDrawerOpen) {
        closeDrawer(scaffoldKey: scaffoldKey);
      } else {
        openDrawer(scaffoldKey: scaffoldKey);
      }
    }
  }

  // 드로어 상태 업데이트 (드로어가 자동으로 닫힐 때 상태 동기화용)
  void updateDrawerState(bool isOpen) {
    state = isOpen;
  }
}

// 전역 DrawerController Provider (기존 호환성용)
final drawerControllerProvider =
    StateNotifierProvider<DrawerController, bool>((ref) {
  return DrawerController();
});

// 각 탭별 독립적인 DrawerController Provider들
final searchDrawerControllerProvider =
    StateNotifierProvider<DrawerController, bool>((ref) {
  return DrawerController();
});

final settingsDrawerControllerProvider =
    StateNotifierProvider<DrawerController, bool>((ref) {
  return DrawerController();
});

// 탭별 DrawerController를 쉽게 가져오는 헬퍼 Provider
final currentTabDrawerControllerProvider = Provider<DrawerController>((ref) {
  final navIndex = ref.watch(navIndexProvider);

  switch (navIndex) {
    case 0: // Search 탭
      return ref.read(searchDrawerControllerProvider.notifier);
    case 1: // Settings 탭
      return ref.read(settingsDrawerControllerProvider.notifier);
    default:
      return ref.read(drawerControllerProvider.notifier);
  }
});
