import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/riverpod/general/navbar_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/router.dart';
import 'package:kronk/utility/setup.dart';
import 'package:kronk/widgets/navbar.dart';

final googleSignIn = GoogleSignIn.instance;

void main() async {
  String initialLocation = await setup();
  final GoRouter router = AppRouter(initialLocation: initialLocation).router;

  runApp(ProviderScope(child: MyApp(router: router)));
}

class MyApp extends ConsumerStatefulWidget {
  final GoRouter router;

  const MyApp({super.key, required this.router});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(() => _listenRouterChanges(fullPath: widget.router.routerDelegate.currentConfiguration.fullPath));
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(() => _listenRouterChanges(fullPath: widget.router.routerDelegate.currentConfiguration.fullPath));
    super.dispose();
  }

  void _listenRouterChanges({required String fullPath}) {
    final navbarItems = ref.read(navbarItemsProvider);
    final enabledRoutes = navbarItems.where((e) => e.isEnabled).toList();
    final enabledRoutesString = enabledRoutes.map((e) => e.route).toList();

    final index = enabledRoutesString.indexWhere((route) => fullPath.startsWith(route));
    if (index != -1) {
      ref.read(activeIndexProvider.notifier).state = index;
    }
  }

  @override
  Widget build(BuildContext context) {
    final MyTheme theme = ref.watch(themeProvider);
    Sizes.init(context);

    return MaterialApp.router(
      title: 'Kronk',
      debugShowCheckedModeBanner: false,
      routerDelegate: widget.router.routerDelegate,
      routeInformationParser: widget.router.routeInformationParser,
      routeInformationProvider: widget.router.routeInformationProvider,

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
