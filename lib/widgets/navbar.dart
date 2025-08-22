import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kronk/models/navbar_model.dart';
import 'package:kronk/riverpod/general/navbar_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/my_logger.dart';

final activeNavbarIndexProvider = StateProvider<int>((ref) => 0);

/// Navbar
class Navbar extends ConsumerStatefulWidget {
  const Navbar({super.key});

  @override
  ConsumerState<Navbar> createState() => _NavbarState();
}

class _NavbarState extends ConsumerState<Navbar> {
  late final ScrollController scrollController;
  late NavbarState navbarState;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    final items = ref.read(navbarItemsProvider).where((e) => e.isEnabled).toList();
    navbarState = NavbarState(items: items);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final notifier = ref.read(navbarItemsProvider.notifier);

    ref.listen(navbarItemsProvider, (previous, next) {
      if (previous?.where((e) => e.isEnabled).toList().length != next.where((e) => e.isEnabled).toList().length) {
        setState(() => navbarState = navbarState.copyWith(items: next));
      }
    });

    myLogger.e('Navbar is building');
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
            child: navbarState.items.isNotEmpty
                ? SingleChildScrollView(
                    key: const PageStorageKey('navbarScroll'),
                    controller: scrollController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: navbarState.items.length * navbarState.cellWidth,
                      height: navbarState.navbarHeight,
                      child: Stack(
                        children: [
                          DragTargetsLayer(
                            itemsLength: navbarState.items.length,
                            navbarState: navbarState,
                            onMove: (details, index) {
                              final itemSize = Size(navbarState.cellWidth, navbarState.navbarHeight);
                              final targetOffset = Offset(index * navbarState.cellWidth, Sizes.screenHeight - navbarState.navbarHeight);
                              final fingerOffset = details.offset;
                              final targetRect = targetOffset & itemSize;
                              final feedbackRect = fingerOffset & itemSize;

                              final overlapRect = feedbackRect.intersect(targetRect);
                              final overlapArea = overlapRect.width * overlapRect.height;
                              final targetArea = targetRect.width * targetRect.height;
                              final overlapRatio = overlapArea / targetArea;

                              if (overlapRatio > 0.6 && navbarState.hoverIndex != index) setState(() => navbarState = navbarState.copyWith(hoverIndex: index));
                            },
                            onAcceptWithDetails: (details, index) async {
                              final activeNavbarIndex = ref.read(activeNavbarIndexProvider);
                              final enabledItems = ref.read(navbarItemsProvider).where((item) => item.isEnabled).toList();
                              final activeItem = enabledItems.elementAt(activeNavbarIndex);

                              await notifier.reorderNavbarItem(oldIndex: details.data, newIndex: index, appliedToEnabled: true);

                              final newEnabledItems = ref.read(navbarItemsProvider).where((item) => item.isEnabled).toList();
                              final newActiveNavbarIndex = newEnabledItems.indexOf(activeItem);

                              if (newActiveNavbarIndex != -1) ref.read(activeNavbarIndexProvider.notifier).state = newActiveNavbarIndex;
                            },
                          ),

                          AnimatedIconsLayer(
                            items: navbarState.items,
                            navbarState: navbarState,
                            onDragStarted: (index) {
                              setState(() => navbarState = navbarState.copyWith(dragIndex: index));
                            },
                            onDragEnd: (details) async {
                              final activeNavbarIndex = ref.read(activeNavbarIndexProvider);
                              final enabledItemsBefore = ref.read(navbarItemsProvider).where((item) => item.isEnabled).toList();
                              final activeItem = enabledItemsBefore.elementAt(activeNavbarIndex);

                              final fingerOffset = details.offset;
                              final feedbackRect = Rect.fromCenter(center: fingerOffset, width: navbarState.cellWidth, height: navbarState.navbarHeight);

                              final barRect = Rect.fromLTWH(0, Sizes.screenHeight - navbarState.navbarHeight, Sizes.screenWidth, navbarState.navbarHeight);
                              final isOverlapping = barRect.overlaps(feedbackRect);
                              final dragIndex = navbarState.dragIndex;

                              if (dragIndex != null && !details.wasAccepted && !isOverlapping) {
                                await notifier.toggleNavbarItem(index: dragIndex, appliedToEnabled: true);

                                final enabledItemsAfter = ref.read(navbarItemsProvider).where((item) => item.isEnabled).toList();
                                final newActiveIndex = enabledItemsAfter.indexOf(activeItem);

                                if (newActiveIndex != -1) {
                                  ref.read(activeNavbarIndexProvider.notifier).state = newActiveIndex;
                                } else if (enabledItemsAfter.isNotEmpty) {
                                  ref.read(activeNavbarIndexProvider.notifier).state = 0;
                                  if (!context.mounted) return;
                                  context.go(enabledItemsAfter.first.route);
                                } else if (enabledItemsAfter.isEmpty) {
                                  if (!context.mounted) return;
                                  context.go('/welcome');
                                }
                              }

                              setState(() => navbarState = navbarState.copyWith(dragIndex: null, hoverIndex: null));
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Drag targets (static cells)
class DragTargetsLayer extends ConsumerWidget {
  final int itemsLength;
  final NavbarState navbarState;
  final void Function(DragTargetDetails<int>, int index) onMove;
  final void Function(DragTargetDetails<int>, int) onAcceptWithDetails;

  const DragTargetsLayer({super.key, required this.itemsLength, required this.navbarState, required this.onMove, required this.onAcceptWithDetails});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: List.generate(itemsLength, (index) {
        return DragTarget<int>(
          onMove: (details) => onMove(details, index),
          onWillAcceptWithDetails: (details) => details.data != index,
          onAcceptWithDetails: (details) => onAcceptWithDetails(details, index),
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

/// Animated icons layer
class AnimatedIconsLayer extends ConsumerWidget {
  final List<NavbarModel> items;
  final NavbarState navbarState;
  final void Function(int) onDragStarted;
  final void Function(DraggableDetails) onDragEnd;

  const AnimatedIconsLayer({super.key, required this.items, required this.navbarState, required this.onDragStarted, required this.onDragEnd});

  double getLeftOffset({required int index, required int? dragIndex, required int? hoverIndex, required double cellWidth}) {
    if (dragIndex == null) return index * cellWidth;
    if (index == dragIndex) return (hoverIndex ?? dragIndex) * cellWidth;
    final isItemBetween = hoverIndex != null && ((index > dragIndex && index <= hoverIndex) || (index < dragIndex && index >= hoverIndex));
    if (isItemBetween) return dragIndex < hoverIndex ? (index - 1) * cellWidth : (index + 1) * cellWidth;
    return index * cellWidth;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final activeNavbarIndex = ref.watch(activeNavbarIndexProvider);

    return Stack(
      children: List.generate(items.length, (index) {
        final item = items.elementAt(index);
        final isActive = activeNavbarIndex == index;
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
            onDragStarted: () => onDragStarted(index),
            onDragEnd: (details) => onDragEnd(details),
            childWhenDragging: Container(width: navbarState.cellWidth, height: navbarState.navbarHeight, color: Colors.deepOrangeAccent.withValues(alpha: 0.5)),
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
                onTap: () => activeNavbarIndex != index ? context.go(item.route) : null,
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

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:kronk/models/navbar_model.dart';
// import 'package:kronk/riverpod/general/navbar_provider.dart';
// import 'package:kronk/riverpod/general/theme_provider.dart';
// import 'package:kronk/utility/classes.dart';
// import 'package:kronk/utility/dimensions.dart';
// import 'package:kronk/utility/extensions.dart';
// import 'package:kronk/utility/my_logger.dart';
//
// final activeNavbarIndexProvider = StateProvider<int>((ref) => 0);
//
// /// Navbar
// class Navbar extends ConsumerStatefulWidget {
//   const Navbar({super.key});
//
//   @override
//   ConsumerState<Navbar> createState() => _NavbarState();
// }
//
// class _NavbarState extends ConsumerState<Navbar> {
//   late final ScrollController scrollController;
//   late NavbarState navbarState;
//
//   @override
//   void initState() {
//     super.initState();
//     scrollController = ScrollController();
//     final items = ref.read(navbarItemsProvider).where((e) => e.isEnabled).toList();
//     navbarState = NavbarState(items: items);
//   }
//
//   @override
//   void dispose() {
//     scrollController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = ref.watch(themeProvider);
//     final notifier = ref.read(navbarItemsProvider.notifier);
//
//     ref.listen(navbarItemsProvider, (previous, next) {
//       if (previous?.where((e) => e.isEnabled).toList().length != next.where((e) => e.isEnabled).length) {
//         setState(() => navbarState = navbarState.copyWith(items: next));
//       }
//     });
//
//     final barRect = Rect.fromLTWH(0, Sizes.screenHeight - navbarState.navbarHeight, Sizes.screenWidth, navbarState.navbarHeight);
//
//     myLogger.e('items: ${navbarState.items.map((e) => e.route).toList()}');
//     return Container(
//       height: navbarState.navbarHeight,
//       decoration: BoxDecoration(
//         color: theme.primaryBackground,
//         border: Border(top: BorderSide(color: theme.secondaryText, width: 0.1)),
//       ),
//       child: Stack(
//         children: [
//           Listener(
//             onPointerMove: (event) {
//               if (navbarState.dragIndex == null) return;
//
//               final scrollPosition = scrollController.position;
//               final scrollThreshold = navbarState.cellWidth;
//
//               // Check if pointer is near the left edge and scroll left
//               if (event.localPosition.dx < scrollThreshold && scrollPosition.pixels > 0) {
//                 scrollController.animateTo(
//                   (scrollPosition.pixels - 20).clamp(0.0, scrollPosition.maxScrollExtent),
//                   duration: const Duration(milliseconds: 100),
//                   curve: Curves.linear,
//                 );
//               }
//               // Check if pointer is near the right edge and scroll right
//               else if (event.localPosition.dx > Sizes.screenWidth - scrollThreshold && scrollPosition.pixels < scrollPosition.maxScrollExtent) {
//                 scrollController.animateTo(
//                   (scrollPosition.pixels + 20).clamp(0.0, scrollPosition.maxScrollExtent),
//                   duration: const Duration(milliseconds: 100),
//                   curve: Curves.linear,
//                 );
//               }
//             },
//             child: navbarState.items.isNotEmpty
//                 ? SingleChildScrollView(
//                     key: const PageStorageKey('navbarScroll'),
//                     controller: scrollController,
//                     scrollDirection: Axis.horizontal,
//                     child: SizedBox(
//                       width: navbarState.items.length * navbarState.cellWidth,
//                       height: navbarState.navbarHeight,
//                       child: Stack(
//                         children: [
//                           DragTargetsLayer(
//                             itemsLength: navbarState.items.length,
//                             navbarState: navbarState,
//                             onMove: (details, index) {
//                               final itemSize = Size(navbarState.cellWidth, navbarState.navbarHeight);
//                               final targetOffset = Offset(index * navbarState.cellWidth, Sizes.screenHeight - navbarState.navbarHeight);
//                               final fingerOffset = details.offset;
//                               final targetRect = targetOffset & itemSize;
//                               final feedbackRect = fingerOffset & itemSize;
//
//                               final overlapRect = feedbackRect.intersect(targetRect);
//                               final overlapArea = overlapRect.width * overlapRect.height;
//                               final targetArea = targetRect.width * targetRect.height;
//                               final overlapRatio = overlapArea / targetArea;
//
//                               if (overlapRatio > 0.6 && navbarState.hoverIndex != index) setState(() => navbarState = navbarState.copyWith(hoverIndex: index));
//                             },
//                             onAcceptWithDetails: (details, index) async {
//                               final activeNavbarIndex = ref.read(activeNavbarIndexProvider);
//                               final enabledItems = ref.read(navbarItemsProvider).where((item) => item.isEnabled).toList();
//                               final activeItem = enabledItems.elementAt(activeNavbarIndex);
//
//                               await notifier.reorderNavbarItem(oldIndex: details.data, newIndex: index, appliedToEnabled: true);
//
//                               final newEnabledItems = ref.read(navbarItemsProvider).where((item) => item.isEnabled).toList();
//                               final newActiveNavbarIndex = newEnabledItems.indexOf(activeItem);
//
//                               if (newActiveNavbarIndex != -1) ref.read(activeNavbarIndexProvider.notifier).state = newActiveNavbarIndex;
//                             },
//                           ),
//
//                           AnimatedIconsLayer(
//                             items: navbarState.items,
//                             navbarState: navbarState,
//                             onDragStarted: (index) {
//                               setState(() => navbarState = navbarState.copyWith(dragIndex: index));
//                             },
//                             onDragEnd: (details) async {
//                               final activeNavbarIndex = ref.read(activeNavbarIndexProvider);
//                               final enabledItemsBefore = ref.read(navbarItemsProvider).where((item) => item.isEnabled).toList();
//                               final activeItem = enabledItemsBefore.elementAt(activeNavbarIndex);
//
//                               final fingerOffset = details.offset;
//                               final feedbackRect = Rect.fromCenter(center: fingerOffset, width: navbarState.cellWidth, height: navbarState.navbarHeight);
//
//                               final isOverlapping = barRect.overlaps(feedbackRect);
//                               final dragIndex = navbarState.dragIndex;
//
//                               if (dragIndex != null && !details.wasAccepted && !isOverlapping) {
//                                 await notifier.toggleNavbarItem(index: dragIndex, appliedToEnabled: true);
//
//                                 final enabledItemsAfter = ref.read(navbarItemsProvider).where((item) => item.isEnabled).toList();
//                                 final newActiveIndex = enabledItemsAfter.indexOf(activeItem);
//
//                                 if (newActiveIndex != -1) {
//                                   ref.read(activeNavbarIndexProvider.notifier).state = newActiveIndex;
//                                 } else if (enabledItemsAfter.isNotEmpty) {
//                                   ref.read(activeNavbarIndexProvider.notifier).state = 0;
//                                   if (!context.mounted) return;
//                                   context.go(enabledItemsAfter.first.route);
//                                 } else if (enabledItemsAfter.isEmpty) {
//                                   if (!context.mounted) return;
//                                   context.go('/welcome');
//                                 }
//                               }
//
//                               setState(() => navbarState = navbarState.copyWith(dragIndex: null, hoverIndex: null));
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                   )
//                 : const SizedBox.shrink(),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// /// Drag targets (static cells)
// class DragTargetsLayer extends ConsumerWidget {
//   final int itemsLength;
//   final NavbarState navbarState;
//   final void Function(DragTargetDetails<int>, int index) onMove;
//   final void Function(DragTargetDetails<int>, int) onAcceptWithDetails;
//
//   const DragTargetsLayer({super.key, required this.itemsLength, required this.navbarState, required this.onMove, required this.onAcceptWithDetails});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return Row(
//       children: List.generate(itemsLength, (index) {
//         return DragTarget<int>(
//           onMove: (details) => onMove(details, index),
//           onWillAcceptWithDetails: (details) => details.data != index,
//           onAcceptWithDetails: (details) => onAcceptWithDetails(details, index),
//           builder: (context, candidateData, rejectedData) => Container(
//             width: navbarState.cellWidth,
//             height: navbarState.navbarHeight,
//             decoration: BoxDecoration(border: Border.all(width: 0.1, color: Colors.redAccent)),
//           ),
//         );
//       }),
//     );
//   }
// }
//
// /// Animated icons layer
// class AnimatedIconsLayer extends ConsumerWidget {
//   final List<NavbarModel> items;
//   final NavbarState navbarState;
//   final void Function(int) onDragStarted;
//   final void Function(DraggableDetails) onDragEnd;
//
//   const AnimatedIconsLayer({super.key, required this.items, required this.navbarState, required this.onDragStarted, required this.onDragEnd});
//
//   double getLeftOffset({required int index, required int? dragIndex, required int? hoverIndex, required double cellWidth}) {
//     if (dragIndex == null) return index * cellWidth;
//     if (index == dragIndex) return (hoverIndex ?? dragIndex) * cellWidth;
//     final isItemBetween = hoverIndex != null && ((index > dragIndex && index <= hoverIndex) || (index < dragIndex && index >= hoverIndex));
//     if (isItemBetween) return dragIndex < hoverIndex ? (index - 1) * cellWidth : (index + 1) * cellWidth;
//     return index * cellWidth;
//   }
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final theme = ref.watch(themeProvider);
//     final activeNavbarIndex = ref.watch(activeNavbarIndexProvider);
//
//     return Stack(
//       children: List.generate(items.length, (index) {
//         final item = items.elementAt(index);
//         final isActive = activeNavbarIndex == index;
//         final leftOffset = getLeftOffset(index: index, dragIndex: navbarState.dragIndex, hoverIndex: navbarState.hoverIndex, cellWidth: navbarState.cellWidth);
//
//         return AnimatedPositioned(
//           key: ValueKey(item),
//           top: 0,
//           left: leftOffset,
//           width: navbarState.cellWidth,
//           height: navbarState.navbarHeight,
//           curve: Curves.easeOut,
//           duration: const Duration(milliseconds: 300),
//           child: LongPressDraggable<int>(
//             data: index,
//             dragAnchorStrategy: childDragAnchorStrategy,
//             onDragStarted: () => onDragStarted(index),
//             onDragEnd: (details) => onDragEnd(details),
//             childWhenDragging: Container(width: navbarState.cellWidth, height: navbarState.navbarHeight, color: Colors.deepOrangeAccent.withValues(alpha: 0.5)),
//             feedback: Material(
//               color: Colors.transparent,
//               child: Container(
//                 width: navbarState.cellWidth,
//                 height: navbarState.navbarHeight,
//                 color: Colors.greenAccent.withValues(alpha: 0.25),
//                 child: Icon(
//                   item.getIconData(isActive: isActive),
//                   color: isActive ? theme.primaryText : theme.secondaryText,
//                   size: 36.dp,
//                 ),
//               ),
//             ),
//             child: SizedBox(
//               width: navbarState.cellWidth,
//               height: navbarState.navbarHeight,
//               child: GestureDetector(
//                 onTap: () => activeNavbarIndex != index ? context.go(item.route) : null,
//                 child: Icon(
//                   item.getIconData(isActive: isActive),
//                   color: isActive ? theme.primaryText : theme.secondaryText,
//                   size: 28.dp,
//                 ),
//               ),
//             ),
//           ),
//         );
//       }),
//     );
//   }
// }
