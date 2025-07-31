import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/widgets/custom_appbar.dart';

class MainAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String titleText;
  final String tabText1;
  final String tabText2;
  final void Function()? onTap;

  const MainAppBar({super.key, required this.titleText, required this.tabText1, required this.tabText2, required this.onTap});

  @override
  Size get preferredSize => Size.fromHeight(48.dp + 40.dp + 4.dp);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    return CustomAppBar(
      appBarHeight: 48.dp,
      bottomHeight: 40.dp,
      bottomGap: 4.dp,
      actionsSpacing: 8.dp,
      appBarPadding: EdgeInsets.only(left: 12.dp, right: 6.dp),
      bottomPadding: EdgeInsets.only(left: 12.dp, right: 12.dp, bottom: 4.dp),
      leading: Builder(
        builder: (context) => GestureDetector(
          onTap: () => Scaffold.of(context).openDrawer(),
          child: Icon(Icons.menu_rounded, color: theme.primaryText, size: 24.dp),
        ),
      ),
      title: Text(
        titleText,
        style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 24.dp, fontWeight: FontWeight.w500),
      ),
      actions: [
        GestureDetector(
          onTap: () => context.go('/search'),
          child: Icon(Icons.search_rounded, color: theme.primaryText, size: 24.dp),
        ),
        GestureDetector(
          onTap: onTap,
          child: Icon(Icons.more_vert_rounded, color: theme.primaryText, size: 24.dp),
        ),
      ],
      bottom: Container(
        padding: EdgeInsets.all(2.dp),
        decoration: BoxDecoration(color: theme.secondaryBackground, borderRadius: BorderRadius.circular(12.dp)),
        child: TabBar(
          dividerHeight: 0,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(color: theme.primaryBackground, borderRadius: BorderRadius.circular(10.dp)),
          labelStyle: GoogleFonts.quicksand(fontSize: 18.dp, color: theme.primaryText, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.quicksand(fontSize: 18.dp, color: theme.secondaryText, fontWeight: FontWeight.w600),
          indicatorAnimation: TabIndicatorAnimation.elastic,
          tabs: [
            Tab(height: 36.dp, text: tabText1),
            Tab(height: 36.dp, text: tabText2),
          ],
        ),
      ),
    );
  }
}
