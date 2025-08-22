import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';

class EducationScreen extends ConsumerStatefulWidget {
  const EducationScreen({super.key});

  @override
  ConsumerState<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends ConsumerState<EducationScreen> {
  @override
  Widget build(BuildContext context) {
    final MyTheme activeTheme = ref.watch(themeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Education Screen'), automaticallyImplyLeading: false),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text('Education Screen', style: TextStyle(color: activeTheme.primaryText, fontSize: 36))],
        ),
      ),
    );
  }
}
