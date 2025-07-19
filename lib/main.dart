import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:searcademy/config/router/router_provider.dart';
import 'package:searcademy/services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:searcademy/repositories/hive_todos_repository.dart';
import 'package:searcademy/repositories/providers/todos_repository_provider.dart';
import 'package:searcademy/pages/providers/theme/theme_provider.dart';
import 'package:searcademy/pages/providers/theme/theme_state.dart';
import 'package:searcademy/repositories/providers/shared_preferences_provider.dart';
// 🔥 광고 관련 import 추가
import 'package:searcademy/ads/ad_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();
  await FirebaseService.initializeFirebase(); // Firebase 초기화
  // 앱 시작 시 FCM 토큰 얻기
  FirebaseService.getFCMToken();

  // 🔥 광고 SDK 초기화 추가
  try {
    await AdManager.initialize();
    print("Google Mobile Ads SDK 초기화 완료");
  } catch (e) {
    print("광고 SDK 초기화 실패: $e");
  }

  try {
    await Hive.initFlutter();
    print("Hive initialized successfully");
    await Hive.openBox('todos');
    print("Box 'todos' opened successfully");
  } catch (e) {
    print("Hive initialization or box opening failed: $e");
  }

  final prefs = await SharedPreferences.getInstance();
  await dotenv.load(fileName: '.env');
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        todosRepositoryProvider.overrideWithValue(HiveTodosRepository())
      ],
      child: const MyApp(),
    ),
  );
}

// 🔥 MyApp을 StatefulWidget으로 변경하여 앱 라이프사이클 관리
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 앱 시작 시 기존 광고 정리
    AdManager.instance.disposeAllAds();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 앱 종료 시 광고 정리
    AdManager.instance.disposeAllAds();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // 앱 포그라운드로 돌아올 때
        print('앱이 포그라운드로 돌아옴');
        break;
      case AppLifecycleState.paused:
        // 앱이 백그라운드로 갈 때
        print('앱이 백그라운드로 이동');
        break;
      case AppLifecycleState.detached:
        // 앱 종료 시
        AdManager.instance.disposeAllAds();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routeProvider);
    final currentTheme = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Searcademy',
      debugShowCheckedModeBanner: false,
      theme: switch (currentTheme) {
        LightTheme() => ThemeData.light(
            //colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
            // textTheme: const TextTheme(
            //   bodyMedium: TextStyle(fontSize: 24),
            //   labelLarge: TextStyle(fontSize: 24),
            // ),
          ),
        DarkTheme() => ThemeData.dark(
            //colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
            // textTheme: const TextTheme(
            //   bodyMedium: TextStyle(fontSize: 24),
            //   labelLarge: TextStyle(fontSize: 24),
            // ),
          ),
      },
      routerConfig: router,
    );
  }
}
