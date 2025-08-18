import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kronk/models/navbar_model.dart';
import 'package:kronk/riverpod/general/navbar_provider.dart';
import 'package:kronk/utility/extensions.dart';

final StateProvider<int> selectedIndexProvider = StateProvider<int>((Ref ref) => 0);
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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void didUpdateWidget(covariant Dock oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _shakeController?.dispose();
    _scrollController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.7))),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  double _getLeftOffset(int index, double cellWidth) {
    if (_draggingIndex == null) return index * cellWidth;

    if (index == _draggingIndex) {
      return (_hoverIndex ?? _draggingIndex)! * cellWidth;
    }

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

  void _onDragStarted(int index) {
    setState(() => _draggingIndex = index);
    _showOverlay();
    _shakeController?.reset();
  }

  void _onDragEnd(DraggableDetails details, Rect barRect) {
    if (!details.wasAccepted && !barRect.contains(details.offset)) {
      final removedIndex = _draggingIndex!;
      widget.onToggle(removedIndex);
      _items.removeAt(removedIndex);
    }

    setState(() {
      _draggingIndex = null;
      _hoverIndex = null;
    });

    _removeOverlay();
  }

  void _onDragUpdate(DragUpdateDetails details, double cellWidth) {
    final position = details.localPosition;
    final newHoverIndex = (position.dx / cellWidth).clamp(0, _items.length - 1).floor();

    if (_hoverIndex != newHoverIndex) {
      setState(() => _hoverIndex = newHoverIndex);

      // Scroll when dragging near edges
      final scrollThreshold = cellWidth * 1.5;
      final scrollPosition = _scrollController.position;

      if (position.dx < scrollThreshold && scrollPosition.pixels > 0) {
        _scrollController.animateTo(scrollPosition.pixels - cellWidth, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      } else if (position.dx > scrollPosition.viewportDimension - scrollThreshold && scrollPosition.pixels < scrollPosition.maxScrollExtent) {
        _scrollController.animateTo(scrollPosition.pixels + cellWidth, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    final List<NavbarModel> enabledItems = ref.watch(navbarProvider).where((item) => item.isEnabled).toList();
    final notifier = ref.read(navbarProvider.notifier);

    final barHeight = kBottomNavigationBarHeight + MediaQuery.of(context).viewPadding.bottom;
    final barRect = Rect.fromLTWH(0, MediaQuery.of(context).size.height - barHeight, MediaQuery.of(context).size.width, barHeight);

    return Container(
      height: barHeight,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (_items.isEmpty) return const SizedBox.shrink();

          // Limit to max 5 visible items
          final maxVisible = 5;
          final showScroll = _items.length > maxVisible;
          final visibleCount = showScroll ? maxVisible : _items.length;
          final cellWidth = constraints.maxWidth / visibleCount;
          final contentWidth = cellWidth * _items.length;

          return Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: contentWidth,
                  height: barHeight,
                  child: Stack(
                    children: List.generate(_items.length, (index) {
                      return AnimatedPositioned(
                        key: ValueKey(_items[index]),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        left: _getLeftOffset(index, cellWidth),
                        top: 0,
                        width: cellWidth,
                        height: barHeight,
                        child: LongPressDraggable<int>(
                          data: index,
                          feedback: Material(
                            color: Colors.transparent,
                            child: Transform.scale(
                              scale: 1.2,
                              child: Opacity(
                                opacity: 0.8,
                                child: SizedBox(width: cellWidth, height: barHeight, child: _items[index]),
                              ),
                            ),
                          ),
                          childWhenDragging: const SizedBox.shrink(),
                          onDragStarted: () => _onDragStarted(index),
                          onDragUpdate: (details) => _onDragUpdate(details, cellWidth),
                          onDragEnd: (details) => _onDragEnd(details, barRect),
                          child: DragTarget<int>(
                            onWillAcceptWithDetails: (details) {
                              if (details.data != index) {
                                setState(() => _hoverIndex = index);
                                return true;
                              }
                              return false;
                            },
                            onAcceptWithDetails: (details) {
                              final oldIndex = details.data;
                              final newIndex = index;

                              setState(() {
                                final item = _items.removeAt(oldIndex);
                                _items.insert(newIndex, item);
                              });

                              widget.onReorder(oldIndex, newIndex);
                            },
                            onLeave: (data) => setState(() => _hoverIndex = null),
                            builder: (context, candidate, rejected) {
                              return _items[index];
                            },
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              // Scroll indicators
              if (showScroll && _scrollController.hasClients)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Visibility(
                    visible: _scrollController.offset > 0,
                    child: Container(
                      width: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.black.withValues(alpha: 0.3), Colors.transparent], begin: Alignment.centerLeft, end: Alignment.centerRight),
                      ),
                    ),
                  ),
                ),
              if (showScroll && _scrollController.hasClients)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Visibility(
                    visible: _scrollController.offset < _scrollController.position.maxScrollExtent,
                    child: Container(
                      width: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.black.withValues(alpha: 0.3), Colors.transparent], begin: Alignment.centerRight, end: Alignment.centerLeft),
                      ),
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
