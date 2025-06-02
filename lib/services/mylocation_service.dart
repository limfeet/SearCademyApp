import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:searcademy/repositories/location/location_provider.dart';

Future<void> fetchAndSaveLocation(WidgetRef ref) async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("위치 서비스 꺼져있음 → 기본 위치 저장");
      await _saveDefaultLocation(ref);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("위치 권한 거부됨 → 기본 위치 저장");
        await _saveDefaultLocation(ref);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("위치 권한 영구거부됨 → 기본 위치 저장");
      await _saveDefaultLocation(ref);
      return;
    }

    // 여기까지 오면 권한 OK
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    await ref.read(
        saveLocationProvider((position.latitude, position.longitude)).future);
  } catch (e) {
    print("위치 가져오기 실패: $e → 기본 위치 저장");
    await _saveDefaultLocation(ref);
  }
}

Future<void> _saveDefaultLocation(WidgetRef ref) async {
  const defaultLat = 37.5665;
  const defaultLon = 126.9780;
  await ref.read(saveLocationProvider((defaultLat, defaultLon)).future);
}
