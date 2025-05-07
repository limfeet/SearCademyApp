import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:searcademy/pages/content/home/home_provider.dart';
import 'package:searcademy/pages/providers/theme/theme_provider.dart';
import 'package:searcademy/pages/widgets/base_scaffold.dart';
import 'package:searcademy/repositories/providers/package_info_provider.dart';

import '../../../config/router/route_names.dart';
import '../../../constants/firebase_constants.dart';
import '../../../models/custom_error.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = fbAuth.currentUser!.uid;
    final profileState = ref.watch(profileProvider(uid));
    final packageInfoAsync = ref.watch(packageInfoProvider);

    return BaseScaffold(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: profileState.when(
          skipLoadingOnRefresh: false,
          data: (appUser) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome ${appUser.name}',
                    style: const TextStyle(fontSize: 24.0),
                  ),
                  const SizedBox(height: 20.0),
                  const Text(
                    'Your Profile',
                    style: TextStyle(fontSize: 24.0),
                  ),
                  const SizedBox(height: 10.0),
                  Text(
                    'email: ${appUser.email}',
                    style: const TextStyle(fontSize: 16.0),
                  ),
                  const SizedBox(height: 10.0),
                  Text(
                    'id: ${appUser.id}',
                    style: const TextStyle(fontSize: 16.0),
                  ),
                  const SizedBox(height: 10.0),
                  Text(
                    'App Version: ${packageInfoAsync.maybeWhen(data: (info) => info.version, orElse: () => '...')}', // 앱 버전 표시
                    style: const TextStyle(fontSize: 16.0),
                  ),
                  const SizedBox(height: 40),
                  OutlinedButton(
                    onPressed: () {
                      GoRouter.of(context).goNamed(RouteNames.changePassword);
                    },
                    child: const Text(
                      'Change Password',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 40),
                  IconButton(
                    onPressed: () {
                      ref.read(themeProvider.notifier).toggleTheme();
                    },
                    icon: const Icon(Icons.light_mode),
                  ),
                ],
              ),
            );
          },
          error: (e, _) {
            final error = e as CustomError;

            return Center(
              child: Text(
                'code: ${error.code}\nplugin: ${error.plugin}\nmessage: ${error.message}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                ),
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}
