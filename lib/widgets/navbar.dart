import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/models/navbar_model.dart';
import 'package:kronk/riverpod/general/navbar_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/my_logger.dart';

final StateProvider<int> activeIndexProvider = StateProvider<int>((Ref ref) => 0);
final StateProvider<double> navbarScrollOffsetProvider = StateProvider<double>((ref) => 0.0);
final isDeleteModeProvider = StateProvider<bool>((ref) => false);

class Navbar extends ConsumerStatefulWidget {
  const Navbar({super.key});

  @override
  ConsumerState<Navbar> createState() => _NavbarState();
}

class _NavbarState extends ConsumerState<Navbar> with SingleTickerProviderStateMixin {
  int? _draggingIndex;
  int? _hoverIndex;
  OverlayEntry? _overlayEntry;
  AnimationController? _shakeController;
  late final ScrollController _scrollController;
  final _scrollKey = GlobalKey();
  final _containerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _shakeController?.dispose();
    _scrollController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (context) => Consumer(
        builder: (context, ref, child) => Positioned(
          left: 0,
          top: 0,
          right: 0,
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
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  double _getLeftOffset(int index, double cellWidth) {
    if (_draggingIndex == null) return index * cellWidth;

    if (index == _draggingIndex) return (_hoverIndex ?? _draggingIndex)! * cellWidth;

    final isItemBetween = _hoverIndex != null && ((index > _draggingIndex! && index <= _hoverIndex!) || (index < _draggingIndex! && index >= _hoverIndex!));

    if (isItemBetween) {
      if (_draggingIndex! < _hoverIndex!) {
        return (index - 1) * cellWidth;
      } else {
        return (index + 1) * cellWidth;
      }
    }

    return index * cellWidth;
  }

  // double _getLeftOffset(int index, double cellWidth) {
  //   // If we are dragging the item at this index, move its placeholder to follow the hover position.
  //   if (_draggingIndex == index) {
  //     return (_hoverIndex ?? _draggingIndex)! * cellWidth;
  //   }
  //   // IMPORTANT: All other items must remain in their original positions during the drag.
  //   return index * cellWidth;
  // }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final activeIndex = ref.watch(activeIndexProvider);
    final List<NavbarModel> enabledItems = ref.watch(navbarProvider).where((item) => item.isEnabled).toList();
    final notifier = ref.read(navbarProvider.notifier);

    final barHeight = kBottomNavigationBarHeight + Sizes.viewPaddingBottom;
    final barRect = Rect.fromLTWH(0, Sizes.screenHeight - barHeight, Sizes.screenWidth, barHeight);

    return Container(
      height: barHeight,
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        border: Border(top: BorderSide(color: theme.secondaryText, width: 0.1)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (enabledItems.isEmpty) return const SizedBox.shrink();

          final maxVisible = 5;
          final showScroll = enabledItems.length > maxVisible;
          final visibleCount = showScroll ? maxVisible : enabledItems.length;
          final cellWidth = constraints.maxWidth / visibleCount;
          final contentWidth = cellWidth * enabledItems.length;

          return Stack(
            children: [
              /// Navbar
              SingleChildScrollView(
                key: _scrollKey,
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  key: _containerKey,
                  width: contentWidth,
                  height: barHeight,
                  child: Stack(
                    children: [
                      // Invisible static drag targets (the "grid")
                      Row(
                        children: List.generate(enabledItems.length, (index) {
                          return DragTarget<int>(
                            onMove: (details) {
                              myLogger.e('onMove: ${details.data}');
                            },
                            onWillAcceptWithDetails: (details) {
                              myLogger.e('onWillAcceptWithDetails details.data: ${details.data}, index: $index');
                              return details.data != index;
                            },
                            onAcceptWithDetails: (details) async {
                              myLogger.e('onAcceptWithDetails details.data: ${details.data}, index: $index');
                              await notifier.reorderNavbarItem(oldIndex: details.data, newIndex: index, appliedToEnabled: true);
                              setState(() => _hoverIndex = null);
                            },
                            builder: (context, _, __) => SizedBox(width: cellWidth, height: barHeight),
                          );
                        }),
                      ),

                      // Animated icons layer
                      ...List.generate(enabledItems.length, (index) {
                        final item = enabledItems.elementAt(index);
                        final isActive = activeIndex == index;

                        return AnimatedPositioned(
                          key: ValueKey(item),
                          top: 0,
                          left: _getLeftOffset(index, cellWidth),
                          width: cellWidth,
                          height: barHeight,
                          curve: Curves.easeOut,
                          duration: const Duration(milliseconds: 300),
                          child: LongPressDraggable<int>(
                            data: index,
                            dragAnchorStrategy: childDragAnchorStrategy,
                            // feedbackOffset: Offset(cellWidth / -2 + 14.dp, barHeight / -2 + 14.dp),
                            onDragStarted: () {
                              setState(() => _draggingIndex = index);
                              _showOverlay();
                              _shakeController?.reset();
                            },
                            onDragEnd: (details) async {
                              final feedbackSize = Size(cellWidth * 1.2, barHeight * 1.2);
                              final finger = details.offset;
                              final feedbackRect = Rect.fromCenter(center: finger, width: feedbackSize.width, height: feedbackSize.height);

                              final isOverlapping = barRect.overlaps(feedbackRect);

                              if (!details.wasAccepted && _draggingIndex != null && !isOverlapping) {
                                await notifier.toggleNavbarItem(index: _draggingIndex!, appliedToEnabled: true);
                              }

                              setState(() {
                                _draggingIndex = null;
                                _hoverIndex = null;
                              });

                              _removeOverlay();
                            },
                            onDragUpdate: (details) {
                              // Find the RenderBox of the container using the GlobalKey
                              final containerBox = _containerKey.currentContext?.findRenderObject() as RenderBox?;
                              if (containerBox == null) return;

                              // Convert the global pointer position to the local coordinates of the container
                              final localPosition = containerBox.globalToLocal(details.globalPosition);

                              // Now, calculate the hover index using the correct position
                              final newHoverIndex = (localPosition.dx / cellWidth).clamp(0, enabledItems.length - 1).floor();

                              if (_hoverIndex != newHoverIndex) {
                                setState(() => _hoverIndex = newHoverIndex);
                              }

                              final scrollBox = _scrollKey.currentContext?.findRenderObject() as RenderBox?;
                              if (scrollBox == null) return;

                              // Get the pointer's position relative to the visible scroll area
                              final scrollBoxPosition = scrollBox.globalToLocal(details.globalPosition);
                              final scrollPosition = _scrollController.position;
                              final scrollThreshold = cellWidth; // A 1-cell threshold from the edge

                              // If near the left edge, scroll left
                              if (scrollBoxPosition.dx < scrollThreshold && scrollPosition.pixels > 0) {
                                _scrollController.animateTo(
                                  (scrollPosition.pixels - cellWidth).clamp(0.0, scrollPosition.maxScrollExtent),
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOut,
                                );
                                // If near the right edge, scroll right
                              } else if (scrollBoxPosition.dx > scrollBox.size.width - scrollThreshold && scrollPosition.pixels < scrollPosition.maxScrollExtent) {
                                _scrollController.animateTo(
                                  (scrollPosition.pixels + cellWidth).clamp(0.0, scrollPosition.maxScrollExtent),
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOut,
                                );
                              }
                            },
                            childWhenDragging: const SizedBox.shrink(),
                            feedback: Material(
                              color: Colors.transparent,
                              child: Transform.scale(
                                scale: 1.2,
                                child: Opacity(
                                  opacity: 0.8,
                                  child: SizedBox(
                                    width: cellWidth,
                                    height: barHeight,
                                    child: Icon(
                                      item.getIconData(isActive: isActive),
                                      color: isActive ? theme.primaryText : theme.secondaryText,
                                      size: 28.dp,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            child: SizedBox(
                              width: cellWidth,
                              height: barHeight,
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
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
