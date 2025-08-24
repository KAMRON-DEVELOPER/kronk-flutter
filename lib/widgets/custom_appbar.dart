import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/extensions.dart';

import '../utility/screen_style_state_dialog.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String screenName;
  final String titleText;
  final String tabText1;
  final String tabText2;
  final TabController? tabController;

  const CustomAppBar({super.key, required this.screenName, required this.titleText, required this.tabText1, required this.tabText2, this.tabController});

  @override
  Size get preferredSize => Size.fromHeight(48.dp + 40.dp + 4.dp);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return BaseAppBar(
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
          onTap: () => showScreenStyleStateDialog(context, screenName),
          child: Icon(Icons.more_vert_rounded, color: theme.primaryText, size: 24.dp),
        ),
      ],
      bottom: Container(
        padding: EdgeInsets.all(2.dp),
        decoration: BoxDecoration(color: theme.secondaryBackground, borderRadius: BorderRadius.circular(12.dp)),
        child: TabBar(
          controller: tabController,
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

class BaseAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final Widget? leading;
  final Widget title;
  final List<Widget> actions;
  final double actionsSpacing;
  final EdgeInsets appBarPadding;
  final EdgeInsets bottomPadding;
  final Widget? bottom;
  final double? bottomHeight;
  final double appBarHeight;
  final double bottomGap;

  const BaseAppBar({
    super.key,
    this.leading,
    required this.appBarHeight,
    this.bottomHeight,
    required this.bottomGap,
    required this.appBarPadding,
    required this.bottomPadding,
    required this.title,
    this.actions = const [],
    this.actionsSpacing = 8,
    this.bottom,
  });

  @override
  Size get preferredSize => Size(double.infinity, appBarHeight + (bottomHeight ?? 0) + bottomGap);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return Container(
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        border: Border(
          bottom: BorderSide(color: theme.secondaryBackground, width: 0.5.dp),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: appBarHeight,
              padding: appBarPadding,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (leading != null) Align(alignment: Alignment.centerLeft, child: leading),
                  Align(alignment: Alignment.center, child: title),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(mainAxisAlignment: MainAxisAlignment.end, spacing: actionsSpacing, children: actions),
                  ),
                ],
              ),
            ),
            if (bottom != null) Container(height: bottomHeight, padding: bottomPadding, child: bottom),
          ],
        ),
      ),
    );
  }
}
