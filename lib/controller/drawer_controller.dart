import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:searcademy/repositories/providers/scaffoldstate_provider.dart';

final drawerControllerProvider =
    StateNotifierProvider<DrawerControllerNotifier, bool>((ref) {
  return DrawerControllerNotifier(ref);
});

class DrawerControllerNotifier extends StateNotifier<bool> {
  DrawerControllerNotifier(this.ref) : super(false);
  final Ref ref;

  void openDrawer() {
    final scaffoldKey = ref.read(scaffoldKeyProvider);
    scaffoldKey.currentState?.openDrawer();
  }

  Future<void> closeDrawer() async {
    final scaffoldKey = ref.read(scaffoldKeyProvider);
    scaffoldKey.currentState?.closeDrawer();
  }
}
