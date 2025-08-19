import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kronk/riverpod/general/navbar_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';

/// Navigation state
final activeIndexProvider = StateProvider<int>((ref) => 0);

/// Keep navbar scroll offset because when screen chang navbar recreated
final navbarScrollOffsetProvider = StateProvider<double>((ref) => 0.0);

/// NavbarLayout
class NavbarLayout {
  final double barHeight;
  final double cellWidth;
  final double contentWidth;

  const NavbarLayout({required this.barHeight, required this.cellWidth, required this.contentWidth});

  factory NavbarLayout.fromItemsCount(int itemCount) {
    const maxVisible = 5;
    final visibleCount = itemCount > maxVisible ? maxVisible : itemCount;
    final cellWidth = Sizes.screenWidth / visibleCount;
    final barHeight = kBottomNavigationBarHeight + Sizes.viewPaddingBottom;
    final contentWidth = cellWidth * itemCount;
    return NavbarLayout(barHeight: barHeight, cellWidth: cellWidth, contentWidth: contentWidth);
  }
}

/// Drag state
class DragState {
  final int? dragIndex;
  final int? hoverIndex;
  final NavbarLayout navbarLayout;

  const DragState({this.dragIndex, this.hoverIndex, required this.navbarLayout});

  DragState copyWith({int? dragIndex, int? hoverIndex, NavbarLayout? navbarLayout}) {
    return DragState(dragIndex: dragIndex ?? this.dragIndex, hoverIndex: hoverIndex ?? this.hoverIndex, navbarLayout: navbarLayout ?? this.navbarLayout);
  }
}

class DragStateNotifier extends Notifier<DragState> {
  // @override
  // DragState build() {
  //   final enabledItems = ref.watch(navbarItemsProvider).where((item) => item.isEnabled).toList();
  //   return DragState(navbarLayout: NavbarLayout.fromItemsCount(enabledItems.length));
  // }

  @override
  DragState build() {
    final items = ref.read(navbarItemsProvider).where((item) => item.isEnabled).toList();
    final initial = DragState(navbarLayout: NavbarLayout.fromItemsCount(items.length));

    ref.listen(navbarItemsProvider, (previous, next) {
      final enabledItems = next.where((item) => item.isEnabled).toList();
      state = state.copyWith(navbarLayout: NavbarLayout.fromItemsCount(enabledItems.length));
    });

    return initial;
  }

  void updateNavbarLayout(int itemCount) {
    state = state.copyWith(navbarLayout: NavbarLayout.fromItemsCount(itemCount));
  }

  void setDragIndex(int index) => state = state.copyWith(dragIndex: index);

  void setHoverIndex(int? index) => state = state.copyWith(hoverIndex: index);

  void endDrag() => state = state.copyWith(dragIndex: null, hoverIndex: null);
}

final dragStateProvider = NotifierProvider<DragStateNotifier, DragState>(DragStateNotifier.new);

/// Navbar
class Navbar extends ConsumerStatefulWidget {
  const Navbar({super.key});

  @override
  ConsumerState<Navbar> createState() => _NavbarState();
}

class _NavbarState extends ConsumerState<Navbar> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final navbarLayout = ref.watch(dragStateProvider).navbarLayout;
    final bool isAnyServiceEnabled = ref.watch(navbarItemsProvider.select((items) => items.any((item) => item.isEnabled)));

    return Container(
      height: navbarLayout.barHeight,
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        border: Border(top: BorderSide(color: theme.secondaryText, width: 0.1)),
      ),
      child: Stack(
        children: [
          Listener(
            onPointerMove: (event) {
              if (ref.read(dragStateProvider).dragIndex == null) return;

              final scrollPosition = _scrollController.position;
              final scrollThreshold = navbarLayout.cellWidth;

              // Check if pointer is near the left edge and scroll left
              if (event.localPosition.dx < scrollThreshold && scrollPosition.pixels > 0) {
                _scrollController.animateTo(
                  (scrollPosition.pixels - 20).clamp(0.0, scrollPosition.maxScrollExtent),
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.linear,
                );
              }
              // Check if pointer is near the right edge and scroll right
              else if (event.localPosition.dx > Sizes.screenWidth - scrollThreshold && scrollPosition.pixels < scrollPosition.maxScrollExtent) {
                _scrollController.animateTo(
                  (scrollPosition.pixels + 20).clamp(0.0, scrollPosition.maxScrollExtent),
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.linear,
                );
              }
            },
            child: isAnyServiceEnabled
                ? SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: navbarLayout.contentWidth,
                      height: navbarLayout.barHeight,
                      child: const Stack(children: [DragTargetsLayer(), AnimatedIconsLayer()]),
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
  const DragTargetsLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabledItems = ref.watch(navbarItemsProvider).where((item) => item.isEnabled).toList();
    final notifier = ref.read(navbarItemsProvider.notifier);
    final navbarLayout = ref.watch(dragStateProvider).navbarLayout;

    return Row(
      children: List.generate(enabledItems.length, (index) {
        return DragTarget<int>(
          onMove: (details) => ref.read(dragStateProvider.notifier).setHoverIndex(index),
          onWillAcceptWithDetails: (details) => details.data != index,
          onAcceptWithDetails: (details) async {
            final activeIndex = ref.read(activeIndexProvider);
            final enabledItems = ref.read(navbarItemsProvider).where((item) => item.isEnabled).toList();
            final activeItem = enabledItems.elementAt(activeIndex);

            await notifier.reorderNavbarItem(oldIndex: details.data, newIndex: index, appliedToEnabled: true);

            final newEnabledItems = ref.read(navbarItemsProvider).where((item) => item.isEnabled).toList();
            final newActiveIndex = newEnabledItems.indexOf(activeItem);

            if (newActiveIndex != -1) ref.read(activeIndexProvider.notifier).state = newActiveIndex;
          },
          builder: (context, candidateData, rejectedData) => SizedBox(width: navbarLayout.cellWidth, height: navbarLayout.barHeight),
        );
      }),
    );
  }
}

/// Animated icons layer
class AnimatedIconsLayer extends ConsumerWidget {
  const AnimatedIconsLayer({super.key});

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
    final enabledItems = ref.watch(navbarItemsProvider).where((item) => item.isEnabled).toList();
    final notifier = ref.read(navbarItemsProvider.notifier);
    final activeIndex = ref.watch(activeIndexProvider);
    final dragState = ref.watch(dragStateProvider);
    final navbarLayout = dragState.navbarLayout;

    final barRect = Rect.fromLTWH(0, Sizes.screenHeight - navbarLayout.barHeight, Sizes.screenWidth, navbarLayout.barHeight);

    return Stack(
      children: List.generate(enabledItems.length, (index) {
        final item = enabledItems.elementAt(index);
        final isActive = activeIndex == index;
        final leftOffset = getLeftOffset(index: index, dragIndex: dragState.dragIndex, hoverIndex: dragState.hoverIndex, cellWidth: navbarLayout.cellWidth);

        return AnimatedPositioned(
          key: ValueKey(item),
          top: 0,
          left: leftOffset,
          width: navbarLayout.cellWidth,
          height: navbarLayout.barHeight,
          curve: Curves.easeOut,
          duration: const Duration(milliseconds: 300),
          child: LongPressDraggable<int>(
            data: index,
            dragAnchorStrategy: childDragAnchorStrategy,
            onDragStarted: () {
              ref.read(dragStateProvider.notifier).setDragIndex(index);
            },
            // Inside AnimatedIconsLayer -> LongPressDraggable
            onDragEnd: (details) async {
              final activeIndex = ref.read(activeIndexProvider);
              final enabledItemsBefore = ref.read(navbarItemsProvider).where((item) => item.isEnabled).toList();
              final activeItem = enabledItemsBefore.elementAt(activeIndex);

              final feedbackSize = Size(navbarLayout.cellWidth * 1.2, navbarLayout.barHeight * 1.2);
              final finger = details.offset;
              final feedbackRect = Rect.fromCenter(center: finger, width: feedbackSize.width, height: feedbackSize.height);
              final isOverlapping = barRect.overlaps(feedbackRect);
              final dragIndex = dragState.dragIndex;

              if (dragIndex != null && !details.wasAccepted && !isOverlapping) {
                await notifier.toggleNavbarItem(index: dragIndex, appliedToEnabled: true);

                final enabledItemsAfter = ref.read(navbarItemsProvider).where((item) => item.isEnabled).toList();
                final newActiveIndex = enabledItemsAfter.indexOf(activeItem);

                if (newActiveIndex != -1) {
                  ref.read(activeIndexProvider.notifier).state = newActiveIndex;
                } else if (enabledItemsAfter.isNotEmpty) {
                  ref.read(activeIndexProvider.notifier).state = 0;
                  if (!context.mounted) return;
                  context.go(enabledItemsAfter.first.route);
                } else if (enabledItemsAfter.isEmpty) {
                  if (!context.mounted) return;
                  context.go('/welcome');
                }
              }

              ref.read(dragStateProvider.notifier).endDrag();
            },
            childWhenDragging: const SizedBox.shrink(),
            feedback: Material(
              color: Colors.transparent,
              child: Transform.scale(
                scale: 1.2,
                child: SizedBox(
                  width: navbarLayout.cellWidth,
                  height: navbarLayout.barHeight,
                  child: Icon(
                    item.getIconData(isActive: isActive),
                    color: isActive ? theme.primaryText : theme.secondaryText,
                    size: 28.dp,
                  ),
                ),
              ),
            ),
            child: SizedBox(
              width: navbarLayout.cellWidth,
              height: navbarLayout.barHeight,
              child: GestureDetector(
                onTap: () => activeIndex != index ? context.go(item.route) : null,
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
