import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 각 탭별로 독립적인 스캐폴드 키 제공
final searchScaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>((ref) {
  return GlobalKey<ScaffoldState>();
});

final settingsScaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>((ref) {
  return GlobalKey<ScaffoldState>();
});

// 기존 호환성을 위해 유지 (하지만 사용하지 않는 것을 권장)
// final scaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>((ref) {
//   return GlobalKey<ScaffoldState>();
// });

// 추가 탭이 필요한 경우 아래와 같이 추가
// final todosScaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>((ref) {
//   return GlobalKey<ScaffoldState>();
// });

// final weatherScaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>((ref) {
//   return GlobalKey<ScaffoldState>();
// });
