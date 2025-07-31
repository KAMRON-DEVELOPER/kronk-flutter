import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/models/navbar_model.dart';
import 'package:kronk/utility/storage.dart';

final navbarProvider = NotifierProvider<NavbarNotifier, List<NavbarModel>>(() => NavbarNotifier());

class NavbarNotifier extends Notifier<List<NavbarModel>> {
  late final Storage _storage;

  @override
  List<NavbarModel> build() {
    _storage = Storage();
    return _storage.getNavbarItems();
  }

  Future<void> toggleNavbarItem({required int index}) async {
    List<NavbarModel> navbarItems = <NavbarModel>[...state];
    NavbarModel navbarItem = navbarItems.elementAt(index);

    if (navbarItem.isEnabled) {
      navbarItem.isEnabled = false;
    } else {
      navbarItem.isEnabled = true;
    }
    await navbarItem.save();

    state = _storage.getNavbarItems();
  }

  Future<void> reorderNavbarItem({required int oldIndex, required int newIndex}) async {
    List<NavbarModel> navbarItems = <NavbarModel>[...state];
    final NavbarModel reorderedItem = navbarItems.removeAt(oldIndex);
    navbarItems.insert(newIndex, reorderedItem);
    state = navbarItems;

    await _storage.updateNavbarItemOrder(oldIndex: oldIndex, newIndex: newIndex);
  }
}
