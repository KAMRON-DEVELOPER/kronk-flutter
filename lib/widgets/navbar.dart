import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kronk/models/navbar_model.dart';
import 'package:kronk/riverpod/general/navbar_state_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';

/// Navbar
class Navbar extends ConsumerStatefulWidget {
  const Navbar({super.key});

  @override
  ConsumerState<Navbar> createState() => _NavbarState();
}

class _NavbarState extends ConsumerState<Navbar> {
  late final ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final navbarState = ref.watch(navbarStateProvider);

    return Container(
      height: navbarState.navbarHeight,
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        border: Border(top: BorderSide(color: theme.secondaryText, width: 0.1)),
      ),
      child: Stack(
        children: [
          Listener(
            onPointerMove: (event) {
              if (navbarState.dragIndex == null) return;

              final scrollPosition = scrollController.position;
              final scrollThreshold = navbarState.cellWidth;

              // Check if pointer is near the left edge and scroll left
              if (event.localPosition.dx < scrollThreshold && scrollPosition.pixels > 0) {
                scrollController.animateTo(
                  (scrollPosition.pixels - 20).clamp(0.0, scrollPosition.maxScrollExtent),
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.linear,
                );
              }
              // Check if pointer is near the right edge and scroll right
              else if (event.localPosition.dx > Sizes.screenWidth - scrollThreshold && scrollPosition.pixels < scrollPosition.maxScrollExtent) {
                scrollController.animateTo(
                  (scrollPosition.pixels + 20).clamp(0.0, scrollPosition.maxScrollExtent),
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.linear,
                );
              }
            },
            child: navbarState.items.isEmpty
                ? const SizedBox.shrink()
                : SingleChildScrollView(
                    key: const PageStorageKey('navbarScroll'),
                    controller: scrollController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: navbarState.items.length * navbarState.cellWidth,
                      height: navbarState.navbarHeight,
                      child: Stack(
                        children: [
                          DragTargetsLayer(scrollController: scrollController),
                          const AnimatedIconsLayer(),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// DragTargetsLayer
class DragTargetsLayer extends ConsumerWidget {
  final ScrollController scrollController;

  const DragTargetsLayer({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navbarState = ref.watch(navbarStateProvider);
    final notifier = ref.read(navbarStateProvider.notifier);

    return Row(
      children: List.generate(navbarState.items.length, (index) {
        return DragTarget<int>(
          onMove: (details) {
            final itemSize = Size(navbarState.cellWidth, navbarState.navbarHeight);
            final targetOffset = Offset(index * navbarState.cellWidth - scrollController.offset, Sizes.screenHeight - navbarState.navbarHeight);
            final fingerOffset = details.offset;
            final targetRect = targetOffset & itemSize;
            final feedbackRect = fingerOffset & itemSize;

            final overlapRect = feedbackRect.intersect(targetRect);
            final overlapArea = overlapRect.width * overlapRect.height;
            final targetArea = targetRect.width * targetRect.height;
            final overlapRatio = overlapArea / targetArea;

            if (overlapRatio > 0.6 && navbarState.hoverIndex != index) notifier.update(navbarState: navbarState.copyWith(hoverIndex: index));
          },
          onWillAcceptWithDetails: (details) => details.data != index,
          onAcceptWithDetails: (details) async {
            final items = ref.read(navbarStateProvider.select((e) => e.items)).where((e) => e.isEnabled).toList();
            final activeItem = items.elementAt(navbarState.activeIndex);

            await notifier.reorderNavbarItem(oldIndex: details.data, newIndex: index, appliedToEnabled: true);

            final stateAfter = ref.read(navbarStateProvider);
            final newItems = stateAfter.items.where((e) => e.isEnabled).toList();
            final newActiveIndex = newItems.indexOf(activeItem);

            if (newActiveIndex != -1) notifier.update(navbarState: stateAfter.copyWith(activeIndex: newActiveIndex));
          },
          builder: (context, candidateData, rejectedData) => Container(
            width: navbarState.cellWidth,
            height: navbarState.navbarHeight,
            decoration: BoxDecoration(border: Border.all(width: 0.1, color: Colors.redAccent)),
          ),
        );
      }),
    );
  }
}

/// AnimatedIconsLayer
class AnimatedIconsLayer extends ConsumerWidget {
  const AnimatedIconsLayer({super.key});

  double getLeftOffset({required int index, required int? dragIndex, required int? hoverIndex, required double cellWidth}) {
    if (dragIndex == null) return index * cellWidth;
    if (hoverIndex == null || hoverIndex == dragIndex) return index * cellWidth;
    if (index == dragIndex) return hoverIndex * cellWidth;

    final isBetween = (index > dragIndex && index <= hoverIndex) || (index < dragIndex && index >= hoverIndex);

    if (isBetween) return dragIndex < hoverIndex ? (index - 1) * cellWidth : (index + 1) * cellWidth;
    return index * cellWidth;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final navbarState = ref.watch(navbarStateProvider);
    final notifier = ref.read(navbarStateProvider.notifier);

    return Stack(
      children: List.generate(navbarState.items.length, (index) {
        final item = navbarState.items.elementAt(index);
        final isActive = navbarState.activeIndex == index;
        final leftOffset = getLeftOffset(index: index, dragIndex: navbarState.dragIndex, hoverIndex: navbarState.hoverIndex, cellWidth: navbarState.cellWidth);

        return AnimatedPositioned(
          key: ValueKey(item),
          top: 0,
          left: leftOffset,
          width: navbarState.cellWidth,
          height: navbarState.navbarHeight,
          curve: Curves.easeOut,
          duration: const Duration(milliseconds: 300),
          child: LongPressDraggable<int>(
            data: index,
            dragAnchorStrategy: childDragAnchorStrategy,
            onDragStarted: () => notifier.update(navbarState: navbarState.copyWith(dragIndex: index)),
            // onDragEnd: (details) async {
            //   final currentState = ref.read(navbarStateProvider);
            //   final enabledItemsBefore = currentState.items.where((item) => item.isEnabled).toList();
            //   final activeItem = enabledItemsBefore.elementAt(currentState.activeIndex);
            //   final dragIndex = currentState.dragIndex;
            //
            //   if (details.wasAccepted) {
            //     notifier.update(navbarState: currentState.copyWith(dragIndex: null, hoverIndex: null));
            //     return;
            //   }
            //
            //   final fingerOffset = details.offset;
            //   final feedbackRect = Rect.fromCenter(center: fingerOffset, width: currentState.cellWidth, height: currentState.navbarHeight);
            //   final barRect = Rect.fromLTWH(0, Sizes.screenHeight - currentState.navbarHeight, Sizes.screenWidth, currentState.navbarHeight);
            //   final isOverlapping = barRect.overlaps(feedbackRect);
            //
            //   if (dragIndex != null && !isOverlapping) {
            //     await notifier.toggleNavbarItem(index: dragIndex, appliedToEnabled: true);
            //
            //     final stateAfterToggle = ref.read(navbarStateProvider);
            //     final enabledItemsAfter = stateAfterToggle.items.where((item) => item.isEnabled).toList();
            //     final newActiveIndex = enabledItemsAfter.indexOf(activeItem);
            //
            //     if (newActiveIndex != -1) {
            //       notifier.update(navbarState: stateAfterToggle.copyWith(activeIndex: newActiveIndex));
            //     } else if (enabledItemsAfter.isNotEmpty) {
            //       notifier.update(navbarState: stateAfterToggle.copyWith(activeIndex: 0));
            //       if (!context.mounted) return;
            //       context.go(enabledItemsAfter.first.route);
            //     } else {
            //       if (!context.mounted) return;
            //       context.go('/welcome');
            //     }
            //   }
            //
            //   final latestState = ref.read(navbarStateProvider);
            //   notifier.update(navbarState: latestState.copyWith(dragIndex: null, hoverIndex: null));
            // },
            onDragEnd: (details) async {
              final currentState = ref.read(navbarStateProvider);
              final enabledItemsBefore = currentState.items.where((item) => item.isEnabled).toList();

              NavbarModel? activeItem;
              if (currentState.activeIndex >= 0 && currentState.activeIndex < enabledItemsBefore.length) {
                activeItem = enabledItemsBefore.elementAt(currentState.activeIndex);
              }

              final dragIndex = currentState.dragIndex;

              if (details.wasAccepted) {
                final latest = ref.read(navbarStateProvider);
                notifier.update(navbarState: latest.copyWith(dragIndex: null, hoverIndex: null));
                return;
              }

              // Compute overlap with navbar rect (to decide toggle/remove)
              final fingerOffset = details.offset;
              final feedbackRect = Rect.fromCenter(center: fingerOffset, width: currentState.cellWidth, height: currentState.navbarHeight);
              final barRect = Rect.fromLTWH(0, Sizes.screenHeight - currentState.navbarHeight, Sizes.screenWidth, currentState.navbarHeight);
              final isOverlapping = barRect.overlaps(feedbackRect);

              if (dragIndex != null && !isOverlapping) {
                await notifier.toggleNavbarItem(index: dragIndex, appliedToEnabled: true);
              }

              final stateAfter = ref.read(navbarStateProvider);
              final enabledItemsAfter = stateAfter.items.where((item) => item.isEnabled).toList();

              int newActiveIndex = stateAfter.activeIndex;

              if (activeItem != null) {
                newActiveIndex = enabledItemsAfter.indexOf(activeItem);
              }

              if (newActiveIndex != -1) {
                notifier.update(navbarState: stateAfter.copyWith(dragIndex: null, hoverIndex: null, activeIndex: newActiveIndex));
              } else if (enabledItemsAfter.isNotEmpty) {
                notifier.update(navbarState: stateAfter.copyWith(dragIndex: null, hoverIndex: null, activeIndex: 0));
                if (!context.mounted) return;
                context.go(enabledItemsAfter.first.route);
              } else {
                notifier.update(navbarState: stateAfter.copyWith(dragIndex: null, hoverIndex: null, activeIndex: -1));
                if (!context.mounted) return;
                context.go('/welcome');
              }
            },
            childWhenDragging: const SizedBox.shrink(),
            feedback: Material(
              color: Colors.transparent,
              child: Container(
                width: navbarState.cellWidth,
                height: navbarState.navbarHeight,
                color: Colors.greenAccent.withValues(alpha: 0.25),
                child: Icon(
                  item.getIconData(isActive: isActive),
                  color: isActive ? theme.primaryText : theme.secondaryText,
                  size: 36.dp,
                ),
              ),
            ),
            child: SizedBox(
              width: navbarState.cellWidth,
              height: navbarState.navbarHeight,
              child: GestureDetector(
                onTap: () {
                  if (navbarState.activeIndex != index) {
                    context.go(item.route);
                    notifier.update(navbarState: navbarState.copyWith(activeIndex: index));
                  }
                },
                child: Icon(
                  item.getIconData(isActive: isActive),
                  color: isActive ? theme.primaryText : theme.secondaryText,
                  size: 28.dp,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
