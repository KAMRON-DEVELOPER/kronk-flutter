import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/models/navbar_model.dart';
import 'package:kronk/riverpod/general/storage_provider.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/my_logger.dart';

final navbarStateProvider = NotifierProvider<NavbarStateNotifier, NavbarState>(() => NavbarStateNotifier());

class NavbarStateNotifier extends Notifier<NavbarState> {
  @override
  NavbarState build() {
    final items = ref.read(storageProvider).getNavbarItems().where((e) => e.isEnabled).toList();
    return NavbarState(items: items);
  }

  Future<void> toggleNavbarItem({required int index, bool appliedToEnabled = false}) async {
    final storage = ref.watch(storageProvider);
    List<NavbarModel> navbarItems = <NavbarModel>[...state.items];
    List<NavbarModel> enabledItems = navbarItems.where((e) => e.isEnabled).toList();

    final itemToToggle = appliedToEnabled ? enabledItems.elementAt(index) : navbarItems.elementAt(index);
    final actualIndex = navbarItems.indexOf(itemToToggle);

    NavbarModel navbarItem = navbarItems.elementAt(actualIndex);

    if (navbarItem.isEnabled) {
      navbarItem.isEnabled = false;
    } else {
      navbarItem.isEnabled = true;
    }

    state = state.copyWith(items: storage.getNavbarItems());
    await navbarItem.save();
  }

  Future<void> reorderNavbarItem({required int oldIndex, required int newIndex, bool appliedToEnabled = false}) async {
    final storage = ref.watch(storageProvider);
    final navbarItems = [...state.items];
    myLogger.e('before navbarItems -> ${navbarItems.map((e) => e.route)}');

    if (appliedToEnabled) {
      final enabledItems = navbarItems.where((e) => e.isEnabled).toList();

      final itemToMove = enabledItems.elementAt(oldIndex);
      final targetItem = enabledItems.elementAt(newIndex);

      final actualOldIndex = navbarItems.indexOf(itemToMove);
      final actualNewIndex = navbarItems.indexOf(targetItem);

      final item = navbarItems.removeAt(actualOldIndex);
      navbarItems.insert(actualNewIndex, item);

      myLogger.e('after navbarItems -> ${navbarItems.map((e) => e.route)}');
      state = state.copyWith(items: navbarItems);
      await storage.reorderNavbarItem(oldIndex: actualOldIndex, newIndex: actualNewIndex);
    } else {
      if (newIndex > oldIndex) newIndex -= 1;

      final item = navbarItems.removeAt(oldIndex);
      navbarItems.insert(newIndex, item);

      myLogger.e('after navbarItems -> ${navbarItems.map((e) => e.route)}');
      state = state.copyWith(items: navbarItems);
      await storage.reorderNavbarItem(oldIndex: oldIndex, newIndex: newIndex);
    }
  }

  void update({required NavbarState navbarState}) {
    state = navbarState;
  }
}
