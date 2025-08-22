import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/constants/my_theme.dart';

import '../../riverpod/general/theme_provider.dart';

class TodosScreen extends ConsumerStatefulWidget {
  const TodosScreen({super.key});

  @override
  ConsumerState<TodosScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<TodosScreen> {
  @override
  Widget build(BuildContext context) {
    final MyTheme currentTheme = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: currentTheme.primaryBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text('Todos Screen', style: TextStyle(color: currentTheme.primaryText, fontSize: 36))],
        ),
      ),
    );
  }
}
