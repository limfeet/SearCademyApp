import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 이거 꼭 추가
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
  Widget build(BuildContext context, ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.first_page), label: 'First'),
          BottomNavigationBarItem(icon: Icon(Icons.pages), label: 'Goods'),
          BottomNavigationBarItem(icon: Icon(Icons.last_page), label: 'Todos'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle), label: 'Weather'),
        ],
        currentIndex: navigationShell.currentIndex,
        onTap: (int index) => _onTap(context, ref, index),
      ),
    );
  }

  Future<void> _onTap(BuildContext context, ref, int index) async {
    ref.read(navIndexProvider.notifier).state = index;
    final scaffoldKey = ref.read(scaffoldKeyProvider);
    if (scaffoldKey.currentState?.isDrawerOpen ?? false) {
      print('Drawer 열려있음!');
      ref.read(drawerControllerProvider.notifier).closeDrawer();
      await Future.delayed(const Duration(milliseconds: 500));
    } else {
      print('Drawer 닫혀있음!');
    }

    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
