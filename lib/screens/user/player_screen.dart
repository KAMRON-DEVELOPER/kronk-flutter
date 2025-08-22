import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/constants/my_theme.dart';

import '../../riverpod/general/theme_provider.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends ConsumerState<PlayerScreen> {
  @override
  Widget build(BuildContext context) {
    final MyTheme currentTheme = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: currentTheme.primaryBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[Text('Player Screen', style: TextStyle(color: currentTheme.primaryText, fontSize: 36))],
        ),
      ),
    );
  }
}
