import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/extensions.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
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

  const CustomAppBar({
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
    final theme = ref.watch(themeNotifierProvider);
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
