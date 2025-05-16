import 'package:firebase_auth/firebase_auth.dart';

import '../constants/firebase_constants.dart';
import 'handle_exception.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  User? get currentUser => fbAuth.currentUser;

  Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      fbAuth.setLanguageCode('ko');
      final userCredential = await fbAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final signedInUser = userCredential.user!;
      await usersCollection.doc(signedInUser.uid).set({
        'name': name,
        'email': email,
      });
    } on FirebaseAuthException catch (e) {
      // 에러 처리
      if (e.code == 'weak-password') {
        print('The password is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      } else if (e.code == 'invalid-email') {
        print('The email address is not valid.');
      } else {
        print('Error: ${e.message}');
      }
    } catch (e) {
      print('Error: ${e.toString()}');

      throw handleException(e);
    }
  }

  Future<void> signin({
    required String email,
    required String password,
  }) async {
    try {
      await fbAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw handleException(e);
    }
  }

  Future<void> signout() async {
    try {
      // 현재 로그인된 사용자가 Google 계정인지 확인
      final isGoogleUser = fbAuth.currentUser?.providerData.any(
            (userInfo) => userInfo.providerId == 'google.com',
          ) ??
          false;

      await fbAuth.signOut();

      // Google 로그아웃 (있을 경우만)
      if (isGoogleUser) {
        final googleSignIn = GoogleSignIn();
        // ✅ 현재 구글 로그인 되어 있는지 먼저 확인
        final isSignedIn = await googleSignIn.isSignedIn();

        if (isSignedIn) {
          await googleSignIn.signOut();
          // ✅ 실제 연결된 유저가 있을 때만 disconnect 시도
          if (googleSignIn.currentUser != null) {
            await googleSignIn.disconnect();
          } else {
            print('⚠️ disconnect skipped: no currentUser');
          }
        }
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  Future<void> changePassword(String password) async {
    try {
      await currentUser!.updatePassword(password);
    } catch (e) {
      throw handleException(e);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await fbAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw handleException(e);
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      await currentUser!.sendEmailVerification();
    } catch (e) {
      throw handleException(e);
    }
  }

  Future<void> reloadUser() async {
    try {
      await currentUser!.reload();
    } catch (e) {
      throw handleException(e);
    }
  }

  Future<void> reauthenticateWithCredential(
    String email,
    String password,
  ) async {
    try {
      await currentUser!.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
    } catch (e) {
      throw handleException(e);
    }
  }
}
