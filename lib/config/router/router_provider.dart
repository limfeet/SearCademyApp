import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:searcademy/config/splash/splash_provider.dart';
import 'package:searcademy/constants/firebase_constants.dart';
import 'package:searcademy/pages/auth/reset_password/reset_password_page.dart';
import 'package:searcademy/pages/auth/signin/signin_page.dart';
import 'package:searcademy/pages/auth/signup/signup_page.dart';
import 'package:searcademy/pages/auth/verify_email/verify_email_page.dart';
import 'package:searcademy/pages/content/academy/academylist_detail_page.dart';
import 'package:searcademy/pages/content/academy/academylist_infinite_page.dart';
import 'package:searcademy/pages/content/academy/academylist_page.dart';
import 'package:searcademy/pages/content/googlemap/googlemap_page.dart';
import 'package:searcademy/pages/content/home/home_page.dart';
import 'package:searcademy/pages/content/setting/settings.dart';
import 'package:searcademy/pages/empty_page.dart';
import 'package:searcademy/pages/splash/firebase_error_page.dart';
import 'package:searcademy/pages/splash/splash_page.dart';
import 'package:searcademy/repositories/auth_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../pages/page_not_found.dart';
import '../../pages/scaffold_with_nav_bar.dart';

import 'route_names.dart';

part 'router_provider.g.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter route(Ref ref) {
  final authState = ref.watch(authStateStreamProvider);
  final splashComplete = ref.watch(splashCompleteProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      // if (authState is AsyncLoading<User?>) {
      //   return '/splash';
      // }

      if (authState is AsyncError<User?>) {
        return '/firebaseError';
      }

      final authenticated = authState.valueOrNull != null;

      final authenticating = (state.matchedLocation == '/signin') ||
          (state.matchedLocation == '/signup') ||
          (state.matchedLocation == '/resetPassword');

      if (splashComplete == false) {
        return '/splash';
      }
      if (authenticated == false) {
        return authenticating ? null : '/signin';
      }

      if (!fbAuth.currentUser!.emailVerified) {
        return '/verifyEmail';
      }

      final verifyingEmail = state.matchedLocation == '/verifyEmail';
      final splashing = state.matchedLocation == '/splash';

      return (authenticating || verifyingEmail || splashing) ? '/home' : null;

      //return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: RouteNames.splash,
        builder: (context, state) {
          print('##### Splash #####');
          return const SplashPage();
        },
      ),
      GoRoute(
        path: '/firebaseError',
        name: RouteNames.firebaseError,
        builder: (context, state) {
          return const FirebaseErrorPage();
        },
      ),
      GoRoute(
        path: '/signin',
        name: RouteNames.signin,
        builder: (context, state) {
          return const SigninPage();
        },
      ),
      GoRoute(
        path: '/signup',
        name: RouteNames.signup,
        builder: (context, state) {
          return const SignupPage();
        },
      ),
      GoRoute(
        path: '/resetPassword',
        name: RouteNames.resetPassword,
        builder: (context, state) {
          return const ResetPasswordPage();
        },
      ),
      GoRoute(
        path: '/verifyEmail',
        name: RouteNames.verifyEmail,
        builder: (context, state) {
          return const VerifyEmailPage();
        },
      ),
      GoRoute(
        path: '/settings',
        name: RouteNames.settings,
        builder: (context, state) {
          return const SettingsPage();
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: RouteNames.home,
                builder: (context, state) {
                  return const HomePage();
                },
                routes: [
                  GoRoute(
                    path: 'changePassword',
                    name: RouteNames.changePassword,
                    builder: (context, state) {
                      return const EmptyPage(
                        message: "CHANGE PW POSITION",
                      );
                    },
                  ),
                ],
              ),
              GoRoute(
                path: '/academyList',
                name: RouteNames.academyList,
                builder: (context, state) {
                  return const InfiniteScrollPage();
                },
                routes: [
                  GoRoute(
                    path: 'academyListDetail/:id',
                    name: RouteNames.academyListDetail,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return AcademylistDetailPage(
                          academyId: id); // 해당 학원의 상세 페이지로 이동
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/goods',
                name: RouteNames.goods,
                builder: (context, state) {
                  // return const EmptyPage(
                  //   message: "PRODUCT POSITION",
                  //);
                  return const AcademyListPage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/todos',
                name: RouteNames.todos,
                builder: (context, state) {
                  // return const EmptyPage(
                  //   message: "TODO POSITION",
                  // );
                  return const InfiniteScrollPage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/second',
                name: RouteNames.second,
                builder: (context, state) {
                  // return const EmptyPage(
                  //   message: "WEATHER POSITION",
                  // );
                  return const MapWithLocationInput();
                },
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => PageNotFound(
      errMsg: state.error.toString(),
    ),
  );
}
