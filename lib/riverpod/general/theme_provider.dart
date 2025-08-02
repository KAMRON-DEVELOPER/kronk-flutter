import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/utility/storage.dart';

final themeProvider = AutoDisposeNotifierProvider<ThemeNotifier, MyTheme>(ThemeNotifier.new);

class ThemeNotifier extends AutoDisposeNotifier<MyTheme> {
  final Storage _storage = Storage();

  @override
  MyTheme build() {
    final Themes theme = _storage.getTheme();

    return MyTheme.fromThemes(theme: theme);
  }

  Future<void> changeTheme({required Themes theme}) async {
    state = MyTheme.fromThemes(theme: theme);
    await _storage.setThemeAsync(themeName: theme);
  }

  Themes getTheme() => _storage.getTheme();

  List<Themes> getThemes() => Themes.values;
}
