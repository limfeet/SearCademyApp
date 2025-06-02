import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:searcademy/repositories/location/location_repository.dart';
import 'package:searcademy/repositories/providers/shared_preferences_provider.dart';

part 'location_provider.g.dart';

@riverpod
LocationRepository locationRepository(ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocationRepository(prefs);
}

@riverpod
Future<(double, double)> location(ref) async {
  final repo = ref.watch(locationRepositoryProvider);
  return repo.loadLocation();
}

@riverpod
Future<void> saveLocation(ref, (double lat, double lon) args) async {
  final repo = ref.watch(locationRepositoryProvider);
  await repo.saveLocation(args.$1, args.$2);
}
