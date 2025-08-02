import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/models/navbar_model.dart';
import 'package:kronk/riverpod/general/navbar_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';

final StateProvider<int> selectedIndexProvider = StateProvider<int>((Ref ref) => 0);
final StateProvider<double> navbarScrollOffsetProvider = StateProvider<double>((ref) => 0.0);

class Navbar extends ConsumerStatefulWidget {
  const Navbar({super.key});

  @override
  ConsumerState<Navbar> createState() => _NavbarState();
}

class _NavbarState extends ConsumerState<Navbar> {
  late ScrollController _scrollController;

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
    final MyTheme theme = ref.watch(themeProvider);
    final List<NavbarModel> items = ref.watch(navbarProvider).where((NavbarModel navbarItem) => navbarItem.isEnabled).toList();
    final int selectedIndex = ref.watch(selectedIndexProvider);

    final double iconSize = 32.dp;
    const int maxIconsInScreen = 5;
    final double screenWidth = Sizes.screenWidth;

    // Actual icons we are displaying
    final int count = items.length;

    // If less than or equal to 5 items, distribute evenly
    final bool fitsWithoutScroll = count <= maxIconsInScreen;
    final double itemWidth = fitsWithoutScroll ? screenWidth / count : screenWidth / maxIconsInScreen;

    return Container(
      height: 56.dp,
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        border: Border(
          top: BorderSide(color: theme.secondaryBackground, width: 0.5.dp),
        ),
      ),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: count,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          final item = items.elementAt(index);
          final bool isActive = index == selectedIndex;

          return SizedBox(
            width: itemWidth,
            child: Center(
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: iconSize,
                onPressed: () {
                  if (!isActive) {
                    // ref.read(selectedIndexProvider.notifier).state = index;
                    context.go(item.route);
                  }
                },
                icon: Icon(
                  item.getIconData(isActive: isActive),
                  color: isActive ? theme.primaryText : theme.secondaryText,
                  size: iconSize,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
