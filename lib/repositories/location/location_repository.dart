import 'package:shared_preferences/shared_preferences.dart';

class LocationRepository {
  static const _latKey = 'user_latitude';
  static const _lonKey = 'user_longitude';

  final SharedPreferences prefs;

  LocationRepository(this.prefs);

  Future<void> saveLocation(double lat, double lon) async {
    await prefs.setDouble(_latKey, lat);
    await prefs.setDouble(_lonKey, lon);
  }

  (double, double) loadLocation() {
    const defaultLat = 37.5665;
    const defaultLon = 126.9780;

    final lat = prefs.getDouble(_latKey) ?? defaultLat;
    final lon = prefs.getDouble(_lonKey) ?? defaultLon;

    return (lat, lon);
  }
}
