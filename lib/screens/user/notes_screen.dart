import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/riverpod/general/screen_style_state_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/screen_style_state_dialog.dart';
import 'package:kronk/widgets/custom_appbar.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final ScreenStyleState screenStyle = ref.watch(screenStyleStateProvider('notes'));
    final bool isFloating = screenStyle.layoutStyle == LayoutStyle.floating;

    return Scaffold(
      appBar: CustomAppBar(
        appBarHeight: 48.dp,
        bottomHeight: 0,
        bottomGap: 4.dp,
        actionsSpacing: 12,
        appBarPadding: EdgeInsets.only(left: 12.dp, right: 6.dp),
        bottomPadding: EdgeInsets.only(left: 12.dp, right: 12.dp, bottom: 4.dp),
        leading: Builder(
          builder: (context) => GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Icon(Icons.menu_rounded, color: theme.primaryText, size: 24),
          ),
        ),
        title: Text(
          'Notes',
          style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 24, fontWeight: FontWeight.w600),
        ),
        actions: [
          GestureDetector(
            onTap: () => showScreenStyleStateDialog(context, 'notes'),
            child: Icon(Icons.search_rounded, color: theme.primaryText, size: 24),
          ),
          GestureDetector(
            onTap: () {},
            child: Icon(Icons.more_vert_rounded, color: theme.primaryText, size: 24),
          ),
        ],
      ),

      body: Stack(
        children: [
          /// Static background images
          if (isFloating)
            Positioned(
              left: 0,
              top: MediaQuery.of(context).padding.top - 52.dp,
              right: 0,
              bottom: 0,
              child: Opacity(
                opacity: 0.4,
                child: Image.asset(
                  screenStyle.backgroundImage,
                  fit: BoxFit.cover,
                  cacheHeight: (Sizes.screenHeight - MediaQuery.of(context).padding.top - 52.dp).cacheSize(context),
                  cacheWidth: Sizes.screenWidth.cacheSize(context),
                ),
              ),
            ),

          /// body
          Center(
            child: Text(
              'Will be available soon, ⌛',
              style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
