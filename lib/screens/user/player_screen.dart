import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/widgets/navbar.dart';

import '../../riverpod/general/theme_provider.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends ConsumerState<PlayerScreen> {
  @override
  Widget build(BuildContext context) {
    final MyTheme currentTheme = ref.watch(themeNotifierProvider);

    return Scaffold(
      backgroundColor: currentTheme.primaryBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[Text('Player Screen', style: TextStyle(color: currentTheme.primaryText, fontSize: 36))],
        ),
      ),
      bottomNavigationBar: const Navbar(),
    );
  }
}
