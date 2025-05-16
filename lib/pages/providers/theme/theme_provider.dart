import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_state.dart';

part 'theme_provider.g.dart';

@riverpod
class Theme extends _$Theme {
  static const _themeKey = 'theme_mode';

  @override
  ThemeState build() {
    _loadTheme(); // 비동기지만 UI 먼저 띄우고 나중에 수정
    return const DarkTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);

    if (savedTheme == 'light') {
      state = const LightTheme();
    } else if (savedTheme == 'dark') {
      state = const DarkTheme();
    }
  }

  void toggleTheme() async {
    state = switch (state) {
      LightTheme() => const DarkTheme(),
      DarkTheme() => const LightTheme(),
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, state is LightTheme ? 'light' : 'dark');
  }

  void changeTheme(ThemeState themeState) async {
    state = themeState;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _themeKey, themeState is LightTheme ? 'light' : 'dark');
  }
}
