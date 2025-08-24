import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/riverpod/general/storage_provider.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/my_logger.dart';

final navbarStateProvider = NotifierProvider<NavbarStateNotifier, NavbarState>(() => NavbarStateNotifier());

class NavbarStateNotifier extends Notifier<NavbarState> {
  @override
  NavbarState build() {
    final items = ref.read(storageProvider).getNavbarItems();
    return NavbarState(items: items);
  }

  Future<void> toggleNavbarItem({required int index, bool appliedToEnabled = false}) async {
    final items = ref.read(storageProvider).getNavbarItems();
    final sourceList = appliedToEnabled ? items.where((e) => e.isEnabled).toList() : items;

    if (index < 0 || index >= sourceList.length) {
      myLogger.e('toggleNavbarItem: invalid index $index');
      return;
    }

    final itemToToggle = sourceList.elementAt(index);

    if (itemToToggle.isEnabled) {
      itemToToggle.isEnabled = false;
    } else {
      itemToToggle.isEnabled = true;
    }

    final updatedItems = items.map((e) => e.route == itemToToggle.route ? itemToToggle : e).toList();
    state = state.copyWith(items: updatedItems);
    try {
      await itemToToggle.save();
    } catch (error, stackTrace) {
      myLogger.e('Failed to save ${itemToToggle.route}', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> reorderNavbarItem({required int oldIndex, required int newIndex, bool appliedToEnabled = false}) async {
    final items = [...state.items];

    int actualOldIndex = oldIndex;
    int actualNewIndex = newIndex;

    if (appliedToEnabled) {
      final enabledItems = items.where((e) => e.isEnabled).toList();

      if (oldIndex < 0 || oldIndex >= enabledItems.length || newIndex < 0 || newIndex >= enabledItems.length) {
        myLogger.e('reorderNavbarItem: invalid indexes (old=$oldIndex, new=$newIndex)');
        return;
      }

      final itemToMove = enabledItems.elementAt(oldIndex);
      final targetItem = enabledItems.elementAt(newIndex);

      actualOldIndex = items.indexOf(itemToMove);
      actualNewIndex = items.indexOf(targetItem);
    } else {
      if (newIndex > oldIndex) newIndex -= 1;
      actualOldIndex = oldIndex;
      actualNewIndex = newIndex;
    }

    if (actualOldIndex < 0 || actualOldIndex >= items.length || actualNewIndex < 0 || actualNewIndex >= items.length) {
      myLogger.w('reorderNavbarItem: invalid resolved indexes (old=$actualOldIndex, new=$actualNewIndex)');
      return;
    }

    final item = items.removeAt(actualOldIndex);
    items.insert(actualNewIndex, item);
    state = state.copyWith(items: items);
    try {
      await ref.read(storageProvider).reorderNavbarItem(oldIndex: actualOldIndex, newIndex: actualNewIndex);
    } catch (error, stackTrace) {
      myLogger.e('Failed to persist reorder', error: error, stackTrace: stackTrace);
    }
  }

  void update({required NavbarState navbarState}) {
    state = navbarState;
  }
}
