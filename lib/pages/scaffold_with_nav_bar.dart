import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:searcademy/controller/drawer_controller.dart';
import 'package:searcademy/repositories/providers/navi_index_provider.dart';
import 'package:searcademy/repositories/providers/scaffoldstate_provider.dart';

class ScaffoldWithNavBar extends ConsumerWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    Key? key,
  }) : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
          //BottomNavigationBarItem(icon: Icon(Icons.last_page), label: 'Todos'),
          //BottomNavigationBarItem(
          //    icon: Icon(Icons.account_circle), label: 'Weather'),
        ],
        currentIndex: navigationShell.currentIndex,
        onTap: (int index) => _onTap(context, ref, index),
      ),
    );
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref, int index) async {
    ref.read(navIndexProvider.notifier).state = index;

    // 현재 활성화된 탭의 스캐폴드 키를 가져옴
    final currentTabScaffoldKey = _getCurrentTabScaffoldKey(ref);

    // 드로어가 열려있는지 확인하고 닫기
    if (currentTabScaffoldKey?.currentState?.isDrawerOpen ?? false) {
      print('Drawer 열려있음 - 탭 ${navigationShell.currentIndex}!');
      currentTabScaffoldKey?.currentState?.closeDrawer();
      await Future.delayed(const Duration(milliseconds: 300));
    } else {
      print('Drawer 닫혀있음 - 탭 ${navigationShell.currentIndex}!');
    }

    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  // 현재 탭에 따라 적절한 스캐폴드 키를 반환
  GlobalKey<ScaffoldState>? _getCurrentTabScaffoldKey(WidgetRef ref) {
    final currentIndex = navigationShell.currentIndex;

    switch (currentIndex) {
      case 0: // Search 탭
        return ref.read(searchScaffoldKeyProvider);
      case 1: // Settings 탭
        return ref.read(settingsScaffoldKeyProvider);
      default:
        return null;
    }
  }
}
