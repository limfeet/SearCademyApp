import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:searcademy/controller/drawer_controller.dart';
import 'package:searcademy/repositories/providers/navi_index_provider.dart';

class BaseScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const BaseScaffold({super.key, required this.child});

  @override
  ConsumerState<BaseScaffold> createState() => _BaseScaffoldState();
}

class _BaseScaffoldState extends ConsumerState<BaseScaffold> {
  late final drawerController = ref.read(drawerControllerProvider.notifier);

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(navIndexProvider, (previous, next) async {
      if (previous != next) {
        //await drawerController.closeDrawer();
        print('call closeDrawer!!');
      }
    });
    return widget.child; // ✅ 그냥 child를 리턴
  }
}
