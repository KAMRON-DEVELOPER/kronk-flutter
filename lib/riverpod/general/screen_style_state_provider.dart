import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/riverpod/general/storage_provider.dart';
import 'package:kronk/utility/classes.dart';

final screenStyleStateProvider = AutoDisposeNotifierProviderFamily<ScreenStyleStateNotifier, ScreenStyleState, String>(ScreenStyleStateNotifier.new);

class ScreenStyleStateNotifier extends AutoDisposeFamilyNotifier<ScreenStyleState, String> {
  @override
  ScreenStyleState build(String screenName) {
    final storage = ref.read(storageProvider);

    return storage.getScreenStyleState(screenName: screenName);
  }

  Future<void> updateScreenStyleState({LayoutStyle? layoutStyle, double? opacity, double? borderRadius, String? backgroundImage}) async {
    final storage = ref.read(storageProvider);
    final newState = state.copyWith(screenName: state.screenName, layoutStyle: layoutStyle, opacity: opacity, borderRadius: borderRadius, backgroundImage: backgroundImage);
    state = newState;

    await storage.setScreenStyleState(screenName: state.screenName, screenStyle: newState);
  }
}
