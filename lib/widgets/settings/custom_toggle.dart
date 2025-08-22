import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/riverpod/general/navbar_state_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/extensions.dart';

class CustomToggle extends ConsumerWidget {
  final int index;
  final bool isEnabled;
  final bool toggleable;

  const CustomToggle({super.key, required this.index, required this.isEnabled, this.toggleable = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MyTheme theme = ref.watch(themeProvider);
    return GestureDetector(
      onTap: toggleable ? () async => await ref.read(navbarStateProvider.notifier).toggleNavbarItem(index: index) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48.dp,
        height: 28.dp,
        padding: EdgeInsets.symmetric(horizontal: 4.dp),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14.dp), color: isEnabled ? theme.primaryText : theme.secondaryText),
        alignment: isEnabled ? Alignment.centerRight : Alignment.centerLeft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 20.dp,
          height: 20.dp,
          decoration: BoxDecoration(color: theme.secondaryBackground, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
