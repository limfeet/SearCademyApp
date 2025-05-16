import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:searcademy/config/router/router_provider.dart';
import 'package:searcademy/services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:searcademy/repositories/hive_todos_repository.dart';
import 'package:searcademy/repositories/providers/todos_repository_provider.dart';
import 'package:searcademy/pages/providers/theme/theme_provider.dart';
import 'package:searcademy/pages/providers/theme/theme_state.dart';

part 'main.g.dart';

@riverpod
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();
  await FirebaseService.initializeFirebase(); // Firebase 초기화
  // 앱 시작 시 FCM 토큰 얻기
  FirebaseService.getFCMToken();

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

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
