import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:searcademy/config/router/route_names.dart';
import 'package:searcademy/constants/firebase_constants.dart';
import 'package:searcademy/models/custom_error.dart';
import 'package:searcademy/pages/content/home/home_provider.dart';
import 'package:searcademy/repositories/auth_repository_provider.dart';
import 'package:searcademy/repositories/providers/package_info_provider.dart';
import 'package:searcademy/utils/error_dialog.dart';

// 페이지 타입을 구분하기 위한 enum
enum DrawerPageType {
  search,
  settings,
  // 추후 확장 가능한 다른 페이지들
  // todos,
  // weather,
}

// 공통 Drawer 위젯
class AppDrawer extends ConsumerWidget {
  const AppDrawer({
    super.key,
    this.currentPageType,
    this.scaffoldKey,
  });
  final DrawerPageType? currentPageType;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 현재 경로 가져오기
    final String currentPath = GoRouterState.of(context).uri.toString();
    final uid = fbAuth.currentUser!.uid;
    final profileState = ref.watch(profileProvider(uid));
    final packageInfoAsync = ref.watch(packageInfoProvider);

    return Drawer(
        child: ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        DrawerHeader(
          decoration: BoxDecoration(
            color: Colors.blue,
          ),
          child: profileState.when(
            skipLoadingOnRefresh: false,
            data: (hoppUser) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.blue),
                  ),
                  SizedBox(height: 10),
                  Text(
                    hoppUser.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    hoppUser.email,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              );
            },
            error: (e, _) {
              final error = e as CustomError;
              return Center(
                child: Text(
                  'Error: ${error.message}',
                  style: TextStyle(color: Colors.red),
                ),
              );
            },
            loading: () => Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
        ListTile(
          leading: Icon(Icons.home),
          title: Text('홈'),
          selected: currentPath == '/${RouteNames.academyList}',
          onTap: () {
            _navigateAndCloseDrawer(
              context,
              () => GoRouter.of(context).goNamed(RouteNames.academyList),
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.person),
          title: Text('Change password'),
          //selected: currentPath == '/changePassword',
          selected: currentPath == '/${RouteNames.changePassword}',
          onTap: () {
            _navigateAndCloseDrawer(
              context,
              () => GoRouter.of(context).goNamed(RouteNames.changePassword),
            );
          },
        ),
        // ListTile(
        //   leading: Icon(Icons.settings),
        //   title: Text('설정'),
        //   //selected: currentPath == '/settings',
        //   selected: currentPath == '/${RouteNames.settings}',
        //   onTap: () {
        //     context.pushNamed(RouteNames.settings);
        //     Navigator.pop(context);
        //   },
        // ),
        Divider(),
        ListTile(
          leading: Icon(Icons.info),
          title: Text(
            'version: ${packageInfoAsync.maybeWhen(data: (info) => info.version, orElse: () => '...')}',
          ),
        ),
        ListTile(
          leading: Icon(Icons.logout),
          title: Text('logout'),
          onTap: () async {
            // 로그아웃 처리
            // 🔧 로그아웃 시에도 드로어를 먼저 닫기
            _closeDrawer(context);
            try {
              await ref.read(authRepositoryProvider).signout();
            } on CustomError catch (e) {
              if (!context.mounted) return;
              errorDialog(context, e);
            }
          },
        ),
      ],
    ));
  }

  // 🔧 드로어를 닫고 네비게이션하는 헬퍼 메서드
  void _navigateAndCloseDrawer(
      BuildContext context, VoidCallback navigationCallback) {
    _closeDrawer(context);

    // 드로어가 닫힌 후 네비게이션 실행
    Future.delayed(const Duration(milliseconds: 250), () {
      navigationCallback();
    });
  }

  // 🔧 현재 페이지의 드로어를 닫는 헬퍼 메서드
  void _closeDrawer(BuildContext context) {
    // scaffoldKey가 제공된 경우 해당 키 사용
    if (scaffoldKey != null &&
        scaffoldKey!.currentState?.isDrawerOpen == true) {
      scaffoldKey!.currentState?.closeDrawer();
      return;
    }

    // 기본적으로 Navigator.pop 사용
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    }
  }
}
