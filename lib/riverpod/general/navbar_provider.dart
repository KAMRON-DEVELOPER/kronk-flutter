import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/models/navbar_model.dart';
import 'package:kronk/riverpod/general/storage_provider.dart';
import 'package:kronk/utility/my_logger.dart';

final navbarItemsProvider = NotifierProvider<NavbarNotifier, List<NavbarModel>>(() => NavbarNotifier());

class NavbarNotifier extends Notifier<List<NavbarModel>> {
  @override
  List<NavbarModel> build() {
    return ref.watch(storageProvider).getNavbarItems();
  }

  Future<void> toggleNavbarItem({required int index, bool appliedToEnabled = false}) async {
    myLogger.e('toggleNavbarItem index: $index');
    final storage = ref.watch(storageProvider);
    List<NavbarModel> navbarItems = <NavbarModel>[...state];
    List<NavbarModel> enabledItems = navbarItems.where((e) => e.isEnabled).toList();

    final navbarItemsRoutes = navbarItems.map((e) => e.route);
    final enabledItemsRoutes = enabledItems.map((e) => e.route);
    myLogger.e('navbarItemsRoutes: $navbarItemsRoutes');
    myLogger.e('enabledItemsRoutes: $enabledItemsRoutes');

    final itemToToggle = appliedToEnabled ? enabledItems.elementAt(index) : navbarItems.elementAt(index);
    final actualIndex = navbarItems.indexOf(itemToToggle);
    myLogger.e('actualIndex: $actualIndex in ${appliedToEnabled ? 'enabledItems' : 'navbarItems'}');

    NavbarModel navbarItem = navbarItems.elementAt(actualIndex);
    myLogger.e('navbarItem.route: ${navbarItem.route}');

    if (navbarItem.isEnabled) {
      navbarItem.isEnabled = false;
    } else {
      navbarItem.isEnabled = true;
    }

    state = storage.getNavbarItems();

    await navbarItem.save();
  }

  Future<void> reorderNavbarItem({required int oldIndex, required int newIndex, bool appliedToEnabled = false}) async {
    myLogger.e('reorderNavbarItem oldIndex: $oldIndex, newIndex: $newIndex triggered from ${appliedToEnabled ? 'navbar' : 'settings'}');
    final storage = ref.watch(storageProvider);
    final navbarItems = [...state];

    if (appliedToEnabled) {
      final enabledItems = navbarItems.where((e) => e.isEnabled).toList();

      final itemToMove = enabledItems[oldIndex];
      final targetItem = enabledItems[newIndex];

      final actualOldIndex = navbarItems.indexOf(itemToMove);
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
