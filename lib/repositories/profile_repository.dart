import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:searcademy/constants/firebase_constants.dart';
import 'package:searcademy/models/app_user.dart';

import 'handle_exception.dart';

class ProfileRepository {
  Future<AppUser> getProfile({required String uid}) async {
    try {
      final DocumentSnapshot appUserDoc = await usersCollection.doc(uid).get();

      if (appUserDoc.exists) {
        final appUser = AppUser.fromDoc(appUserDoc);
        return appUser;
      }

      throw 'User not found';
    } catch (e) {
      throw handleException(e);
    }
  }
}
