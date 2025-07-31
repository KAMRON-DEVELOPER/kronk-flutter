import 'package:flutter/material.dart';

enum Themes { dark, black, purple, gruvbox, catppuccin }

class MyTheme {
  final Color primaryBackground;
  final Color secondaryBackground;
  final Color tertiaryBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color outline;

  MyTheme({
    required this.primaryBackground,
    required this.secondaryBackground,
    required this.tertiaryBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.outline,
  });

  MyTheme copyWith({Color? primaryBackground, Color? secondaryBackground, Color? tertiaryBackground, Color? primaryText, Color? secondaryText, Color? outline}) {
    return MyTheme(
      primaryBackground: primaryBackground ?? this.primaryBackground,
      secondaryBackground: secondaryBackground ?? this.secondaryBackground,
      tertiaryBackground: tertiaryBackground ?? this.tertiaryBackground,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      outline: outline ?? this.outline,
    );
  }

  static MyTheme fromThemes({required Themes theme}) {
    return themes[theme] as MyTheme;
  }

  static final Map<Themes, MyTheme> themes = {
    Themes.dark: MyTheme(
      primaryBackground: const Color(0xFF0C0F15),
      secondaryBackground: const Color(0xFF171B24),
      tertiaryBackground: const Color(0xFF242a38),
      primaryText: const Color(0xFFaed7f5),
      secondaryText: const Color(0xFFaed7f5).withValues(alpha: 0.5),
      outline: const Color(0xFFF2F7FC).withValues(alpha: 0.1),
    ),
    Themes.black: MyTheme(
      primaryBackground: const Color(0xFF141414),
      secondaryBackground: const Color(0xFF1E1E1E),
      tertiaryBackground: const Color(0xFF393939),
      primaryText: const Color(0xFFFFFFFF),
      secondaryText: const Color(0xFFa8a8a8),
      outline: const Color(0xFF707070).withValues(alpha: 0.1),
    ),
    Themes.purple: MyTheme(
      primaryBackground: const Color(0xFF1e1f22),
      secondaryBackground: const Color(0xFF282b30),
      tertiaryBackground: const Color(0xFF36393e),
      primaryText: const Color(0xFF6e86d3),
      secondaryText: const Color(0xFF6e86d3).withValues(alpha: 0.5),
      outline: const Color(0xFF6e86d3).withValues(alpha: 0.1),
    ),
    Themes.gruvbox: MyTheme(
      primaryBackground: const Color(0xFF141617),
      secondaryBackground: const Color(0xFF1D2021),
      tertiaryBackground: const Color(0xFF5A5B56),
      primaryText: const Color(0xFFb8bb26),
      secondaryText: const Color(0xFFb8bb26).withValues(alpha: 0.5),
      outline: const Color(0xFFb8bb26).withValues(alpha: 0.1),
    ),
    Themes.catppuccin: MyTheme(
      primaryBackground: const Color(0xFF151520),
      secondaryBackground: const Color(0xFF181825),
      tertiaryBackground: const Color(0xFF1E1E2E),
      primaryText: const Color(0xFFa899d0),
      secondaryText: const Color(0xFF685a8c),
      outline: const Color(0xFFa899d0).withValues(alpha: 0.1),
    ),
  };
}
