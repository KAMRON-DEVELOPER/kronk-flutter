import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/router.dart';
import 'package:kronk/utility/setup.dart';

final googleSignIn = GoogleSignIn.instance;

void main() async {
  String initialLocation = await setup();
  final GoRouter router = AppRouter(initialLocation: initialLocation).router;

  runApp(ProviderScope(child: MyApp(router: router)));
}

class MyApp extends ConsumerWidget {
  final GoRouter router;

  const MyApp({super.key, required this.router});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Sizes.init(context);
    final MyTheme theme = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Kronk',
      debugShowCheckedModeBanner: false,
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
      routeInformationProvider: router.routeInformationProvider,

      theme: ThemeData(
        useMaterial3: true,
        splashFactory: NoSplash.splashFactory,
        scaffoldBackgroundColor: theme.primaryBackground,
        unselectedWidgetColor: theme.secondaryText,
        listTileTheme: ListTileThemeData(dense: true, iconColor: theme.secondaryText, selectedColor: Colors.red),
        appBarTheme: AppBarTheme(
          backgroundColor: theme.primaryBackground,
          surfaceTintColor: theme.primaryBackground,
          centerTitle: true,
          titleSpacing: 0,
          scrolledUnderElevation: 0,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(systemNavigationBarColor: theme.primaryBackground, systemNavigationBarIconBrightness: Brightness.dark),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: theme.primaryBackground,
          foregroundColor: theme.primaryText,
          shape: const CircleBorder(),
          iconSize: 36.dp,
        ),
        bottomSheetTheme: BottomSheetThemeData(dragHandleColor: theme.secondaryText),
        iconTheme: IconThemeData(color: theme.primaryText, size: 16.dp),
        scrollbarTheme: ScrollbarThemeData(radius: Radius.circular(2.dp), thickness: WidgetStatePropertyAll(4.dp), thumbColor: WidgetStatePropertyAll(theme.secondaryText)),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: theme.primaryBackground,
          selectedItemColor: theme.primaryText,
          unselectedItemColor: theme.secondaryText,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
