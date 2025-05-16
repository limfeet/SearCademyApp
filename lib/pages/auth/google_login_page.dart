import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        try {
          // Google 로그인 처리
          final googleSignIn = GoogleSignIn(
            scopes: ['email'],
          );
          final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

          if (googleUser != null) {
            // Google 로그인 인증 결과 처리
            final GoogleSignInAuthentication googleAuth =
                await googleUser.authentication;
            final accessToken = googleAuth.accessToken;
            final idToken = googleAuth.idToken;

            final credential = GoogleAuthProvider.credential(
              accessToken: accessToken,
              idToken: idToken,
            );

            // Firebase 인증
            final userCredential =
                await FirebaseAuth.instance.signInWithCredential(credential);
            final signedInUser = userCredential.user;

            if (signedInUser != null) {
              print('login success??!!');

              // Firestore에 사용자 정보 저장
              final usersCollection =
                  FirebaseFirestore.instance.collection('users');
              try {
                await usersCollection.doc(signedInUser.uid).set({
                  'name': signedInUser.displayName ?? '', // null 방지
                  'email': signedInUser.email ?? '',
                }, SetOptions(merge: true)); // 덮어쓰기 방지 + 병합
                print('Firestore 저장 완료!');
              } on FirebaseException catch (e) {
                print('Firestore 저장 실패: ${e.code} - ${e.message}');
              } catch (e) {
                print('Firestore 저장 실패: $e');
              }
            } else {
              print('Firebase 사용자 없음');
            }

            if (kDebugMode) {
              print('login success??!!');
            }
          } else {
            if (kDebugMode) {
              print('login failed??!!');
            }
          }
        } on FirebaseAuthException catch (e) {
          print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
        } catch (e) {
          print('❌ Unknown Google login error: $e');
        }
      },
      child: const Text('Google Login'),
    );
  }
}
