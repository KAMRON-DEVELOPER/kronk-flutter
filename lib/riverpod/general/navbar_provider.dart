import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/models/navbar_model.dart';
import 'package:kronk/riverpod/general/storage_provider.dart';

final navbarProvider = NotifierProvider<NavbarNotifier, List<NavbarModel>>(() => NavbarNotifier());

class NavbarNotifier extends Notifier<List<NavbarModel>> {
  @override
  List<NavbarModel> build() {
    return ref.watch(storageProvider).getNavbarItems();
  }

  Future<void> toggleNavbarItem({required int index}) async {
    final storage = ref.watch(storageProvider);
    List<NavbarModel> navbarItems = <NavbarModel>[...state];
    NavbarModel navbarItem = navbarItems.elementAt(index);

    if (navbarItem.isEnabled) {
      navbarItem.isEnabled = false;
    } else {
      navbarItem.isEnabled = true;
    }
    await navbarItem.save();

    state = storage.getNavbarItems();
  }

  Future<void> reorderNavbarItem({required int oldIndex, required int newIndex}) async {
    final storage = ref.watch(storageProvider);
    List<NavbarModel> navbarItems = <NavbarModel>[...state];
    final NavbarModel reorderedItem = navbarItems.removeAt(oldIndex);
    navbarItems.insert(newIndex, reorderedItem);
    state = navbarItems;

    await storage.updateNavbarItemOrder(oldIndex: oldIndex, newIndex: newIndex);
  }

  void resetNavbar() {
    final storage = ref.watch(storageProvider);
    state = storage.getNavbarItems();
  }
}
