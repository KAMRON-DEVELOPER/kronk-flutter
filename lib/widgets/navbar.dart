import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/riverpod/general/navbar_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/my_logger.dart';

/// Navigation state
final activeIndexProvider = StateProvider<int>((ref) => 0);

/// Scroll controller (auto-disposed)
final scrollControllerProvider = Provider.autoDispose<ScrollController>((ref) {
  final controller = ScrollController();
  ref.onDispose(controller.dispose);
  return controller;
});

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
  @override
  DragState build() {
    final enabledItems = ref.watch(navbarItemsProvider).where((item) => item.isEnabled).toList();
    return DragState(navbarLayout: NavbarLayout.fromItemsCount(enabledItems.length));
  }

  void updateNavbarLayout(int itemCount) {
    state = state.copyWith(navbarLayout: NavbarLayout.fromItemsCount(itemCount));
  }

  void setDragIndex(int index) => state = state.copyWith(dragIndex: index);

  void setHoverIndex(int? index) => state = state.copyWith(hoverIndex: index);

  void endDrag() => state = state.copyWith(dragIndex: null, hoverIndex: null);
}

final dragStateProvider = NotifierProvider<DragStateNotifier, DragState>(DragStateNotifier.new);

/// Drag state
class Navbar extends ConsumerWidget {
  const Navbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final scrollController = ref.watch(scrollControllerProvider);

    final navbarLayout = ref.watch(dragStateProvider).navbarLayout;

    return Container(
      height: navbarLayout.barHeight,
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        border: Border(top: BorderSide(color: theme.secondaryText, width: 0.1)),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: navbarLayout.contentWidth,
              height: navbarLayout.barHeight,
              child: const Stack(children: [DragTargetsLayer(), AnimatedIconsLayer()]),
            ),
          ),
          const DeleteOverlay(),
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
          onMove: (details) {
            ref.read(dragStateProvider.notifier).setHoverIndex(index);
          },
          onWillAcceptWithDetails: (details) {
            return details.data != index;
          },
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
class AnimatedIconsLayer extends ConsumerStatefulWidget {
  const AnimatedIconsLayer({super.key});

  @override
  ConsumerState<AnimatedIconsLayer> createState() => _AnimatedIconsLayerState();
}

class _AnimatedIconsLayerState extends ConsumerState<AnimatedIconsLayer> with SingleTickerProviderStateMixin {
  AnimationController? _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _shakeController?.dispose();
    super.dispose();
  }

  double getLeftOffset({required int index, required int? dragIndex, required int? hoverIndex, required double cellWidth}) {
    if (dragIndex == null) return index * cellWidth;
    if (index == dragIndex) return (hoverIndex ?? dragIndex) * cellWidth;
    final isItemBetween = hoverIndex != null && ((index > dragIndex && index <= hoverIndex) || (index < dragIndex && index >= hoverIndex));
    if (isItemBetween) return dragIndex < hoverIndex ? (index - 1) * cellWidth : (index + 1) * cellWidth;
    return index * cellWidth;
  }

  @override
  Widget build(BuildContext context) {
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
              _shakeController?.reset();
            },
            onDragEnd: (details) async {
              final feedbackSize = Size(navbarLayout.cellWidth * 1.2, navbarLayout.barHeight * 1.2);
              final finger = details.offset;
              final feedbackRect = Rect.fromCenter(center: finger, width: feedbackSize.width, height: feedbackSize.height);

              final isOverlapping = barRect.overlaps(feedbackRect);

              if (!details.wasAccepted && dragState.dragIndex != null && !isOverlapping) {
                await notifier.toggleNavbarItem(index: dragState.dragIndex!, appliedToEnabled: true);
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
                onTap: () {
                  myLogger.e('index: $index');
                  if (activeIndex != index) context.go(item.route);
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

/// Delete overlay when navbar item dropped
class DeleteOverlay extends ConsumerWidget {
  const DeleteOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDragging = ref.watch(dragStateProvider.select((state) => state.dragIndex != null));

    return Visibility(
      visible: isDragging,
      child: Positioned.fill(
        bottom: kBottomNavigationBarHeight,
        child: Container(
          color: Colors.black.withValues(alpha: 0.7),
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: Text(
                'Drop it outside the navbar to delete it. 😎',
                textAlign: TextAlign.center,
                style: GoogleFonts.quicksand(color: ref.watch(themeProvider).primaryText, fontSize: 24.dp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
