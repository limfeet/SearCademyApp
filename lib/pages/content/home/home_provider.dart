import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:searcademy/models/app_user.dart';
import 'package:searcademy/repositories/profile_repository_provider.dart';

part 'home_provider.g.dart';

@riverpod
FutureOr<AppUser> profile(ProfileRef ref, String uid) {
  return ref.watch(profileRepositoryProvider).getProfile(uid: uid);
}
