import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:searcademy/config/router/route_names.dart';
import 'package:searcademy/constants/firebase_constants.dart';
import 'package:searcademy/controller/drawer_controller.dart';
import 'package:searcademy/models/custom_error.dart';
import 'package:searcademy/pages/content/home/home_provider.dart';
import 'package:searcademy/pages/providers/theme/theme_provider.dart';
import 'package:searcademy/pages/widgets/appdrawer.dart';
import 'package:searcademy/pages/widgets/base_scaffold.dart';
import 'package:searcademy/repositories/providers/package_info_provider.dart';
import 'package:searcademy/repositories/providers/scaffoldstate_provider.dart';
import 'package:searcademy/services/api_client_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 클래스 외부에 함수로 정의
Future<String> getActiveApiHealthUrl() async {
  final prefs = await SharedPreferences.getInstance();
  final isEnabled = prefs.getBool('custom_api_enabled') ?? false;

  if (isEnabled) {
    final customUrl = prefs.getString('custom_api_url') ?? '';
    if (customUrl.isNotEmpty) {
      return '$customUrl/system/diagnostics/health';
    }
  }

  return dotenv.env['HEALTH_API_URL'] ??
      '${dotenv.env['API_BASE_URL'] ?? ''}/system/diagnostics/health';
}

Future<Map<String, dynamic>?> getApiVersion() async {
  try {
    final apiClient = ApiClientService();
    final healthApiUrl = await getActiveApiHealthUrl();

    if (healthApiUrl.isEmpty) {
      print('Health API URL이 설정되지 않았습니다.');
      return null;
    }

    final response = await apiClient.get(healthApiUrl);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
  } catch (e) {
    print('API 버전 조회 실패: $e');
  }
  return null;
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = fbAuth.currentUser!.uid;
    final profileState = ref.watch(profileProvider(uid));
    final packageInfoAsync = ref.watch(packageInfoProvider);
    final drawerController = ref.read(drawerControllerProvider.notifier);
    final scaffoldKey = ref.watch(settingsScaffoldKeyProvider);

    // 🔥 로그인 제공자 확인 (Google 로그인인지 체크)
    final user = fbAuth.currentUser;
    final isPasswordProvider =
        user?.providerData.any((info) => info.providerId == 'password') ??
            false;

    if (kDebugMode) {
      // ✅ JWT 출력
      Future.microtask(() async {
        final token =
            await fbAuth.currentUser?.getIdToken(true); // true = 강제 갱신
        debugPrint('🔥 Firebase ID Token: $token');
        debugPrint('==================');
        debugPrint(token);
        debugPrint('==================');
      });
    }

    return Scaffold(
      key: scaffoldKey,
      drawer: AppDrawer(
        // 🔧 Settings 페이지임을 명시적으로 전달
        currentPageType: DrawerPageType.settings,
        scaffoldKey: scaffoldKey,
      ),
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            // 🔧 독립적인 드로어 컨트롤 사용
            if (scaffoldKey.currentState?.isDrawerOpen ?? false) {
              scaffoldKey.currentState?.closeDrawer();
            } else {
              scaffoldKey.currentState?.openDrawer();
            }
          },
        ),
      ),
      body: profileState.when(
        skipLoadingOnRefresh: false,
        data: (appUser) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome ${appUser.name}',
                  style: const TextStyle(fontSize: 24.0),
                ),
                const SizedBox(height: 20.0),
                const Text(
                  'Your Profile',
                  style: TextStyle(fontSize: 24.0),
                ),
                const SizedBox(height: 10.0),
                Text(
                  'email: ${appUser.email}',
                  style: const TextStyle(fontSize: 16.0),
                ),
                const SizedBox(height: 10.0),
                Text(
                  'id: ${appUser.id}',
                  style: const TextStyle(fontSize: 16.0),
                ),
                const SizedBox(height: 10.0),
                Text(
                  'App Version: ${packageInfoAsync.maybeWhen(data: (info) => info.version, orElse: () => '...')}',
                  style: const TextStyle(fontSize: 16.0),
                ),
                const SizedBox(height: 10.0),
                // 🔥 API 버전 정보 추가
                FutureBuilder<Map<String, dynamic>?>(
                  future: getApiVersion(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text(
                        'API Version: Loading...',
                        style: TextStyle(fontSize: 16.0),
                      );
                    }

                    if (snapshot.hasData && snapshot.data != null) {
                      final data = snapshot.data!;
                      return Column(
                        children: [
                          Text(
                            'API Version: ${data['version'] ?? 'Unknown'}',
                            style: const TextStyle(fontSize: 16.0),
                          ),
                          Text(
                            'Status: ${data['status'] ?? 'Unknown'}',
                            style: const TextStyle(
                              fontSize: 14.0,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      );
                    }

                    return const Text(
                      'API Version: Failed to load',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.red,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                if (kDebugMode) ...[
                  // 🆕 개발자 페이지 버튼 추가
                  ElevatedButton.icon(
                    onPressed: () {
                      GoRouter.of(context).go('/settings/developer');
                    },
                    icon: const Icon(Icons.developer_mode),
                    label: const Text(
                      '개발자 페이지',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),

                  const SizedBox(height: 20), // 기존 버튼과 간격 조정
                ],

                // 🔥 패스워드 제공자인 경우에만 Change Password 버튼 표시
                if (isPasswordProvider) ...[
                  OutlinedButton(
                    onPressed: () {
                      GoRouter.of(context).goNamed(RouteNames.changePassword);
                    },
                    child: const Text(
                      'Change Password',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 40),
                ] else ...[
                  // Google 로그인 사용자에게는 다른 메시지나 버튼을 표시할 수 있음
                  const SizedBox(height: 40),
                ],

                IconButton(
                  onPressed: () {
                    ref.read(themeProvider.notifier).toggleTheme();
                  },
                  icon: const Icon(Icons.light_mode),
                ),
              ],
            ),
          );
        },
        error: (e, _) {
          final error = e as CustomError;

          return Center(
            child: Text(
              'code: ${error.code}\nplugin: ${error.plugin}\nmessage: ${error.message}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 18,
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
