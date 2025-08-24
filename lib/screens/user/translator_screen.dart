import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/widgets/custom_appbar.dart';

class TranslatorScreen extends ConsumerWidget {
  const TranslatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return Scaffold(
      appBar: BaseAppBar(
        appBarHeight: 48,
        bottomHeight: 0,
        bottomGap: 4,
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
          'Translator(😎)',
          style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 24, fontWeight: FontWeight.w600),
        ),
        actions: [
          GestureDetector(
            onTap: () {},
            child: Icon(Icons.search_rounded, color: theme.primaryText, size: 24),
          ),
          GestureDetector(
            onTap: () {},
            child: Icon(Icons.more_vert_rounded, color: theme.primaryText, size: 24),
          ),
        ],
      ),
      body: Center(
        child: Text('Will be available soon, ⌛', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
