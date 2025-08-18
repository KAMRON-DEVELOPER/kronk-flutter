import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/models/navbar_model.dart';
import 'package:kronk/riverpod/general/storage_provider.dart';

final navbarProvider = NotifierProvider<NavbarNotifier, List<NavbarModel>>(() => NavbarNotifier());

class NavbarNotifier extends Notifier<List<NavbarModel>> {
  @override
  List<NavbarModel> build() {
    return ref.watch(storageProvider).getNavbarItems();
  }

  Future<void> toggleNavbarItem({required int index, bool appliedToEnabled = false}) async {
    final storage = ref.watch(storageProvider);
    List<NavbarModel> navbarItems = <NavbarModel>[...state];
    List<NavbarModel> enabledItems = navbarItems.where((e) => e.isEnabled).toList();

    final itemToToggle = appliedToEnabled ? enabledItems.elementAt(index) : navbarItems.elementAt(index);
    final actualIndex = navbarItems.indexOf(itemToToggle);

    NavbarModel navbarItem = navbarItems.elementAt(appliedToEnabled ? index : actualIndex);

    if (navbarItem.isEnabled) {
      navbarItem.isEnabled = false;
    } else {
      navbarItem.isEnabled = true;
    }

    state = storage.getNavbarItems();

    await navbarItem.save();
  }

  Future<void> reorderNavbarItem({required int oldIndex, required int newIndex, bool appliedToEnabled = false}) async {
    final storage = ref.watch(storageProvider);
    final navbarItems = [...state];
    final enabledItems = navbarItems.where((e) => e.isEnabled).toList();

    final itemToMove = appliedToEnabled ? enabledItems.elementAt(oldIndex) : navbarItems.elementAt(oldIndex);
    final actualOldIndex = navbarItems.indexOf(itemToMove);

    if (appliedToEnabled) {
      if (newIndex > oldIndex) newIndex -= 1;

      final targetItem = enabledItems.elementAt(newIndex);
      final actualNewIndex = navbarItems.indexOf(targetItem);

      final item = navbarItems.removeAt(actualOldIndex);
      navbarItems.insert(actualNewIndex, item);

      state = navbarItems;

      await storage.reorderNavbarItem(oldIndex: actualOldIndex, newIndex: actualNewIndex);
    } else {
      if (newIndex > oldIndex) newIndex -= 1;

      final item = navbarItems.removeAt(oldIndex);
      navbarItems.insert(newIndex, item);

      state = navbarItems;

      await storage.reorderNavbarItem(oldIndex: oldIndex, newIndex: newIndex);
    }
  }

  void resetNavbar() {
    final storage = ref.watch(storageProvider);
    state = storage.getNavbarItems();
  }
}
