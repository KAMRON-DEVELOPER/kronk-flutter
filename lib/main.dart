import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/riverpod/general/navbar_state_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/router.dart';
import 'package:kronk/utility/setup.dart';

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
  late StreamSubscription<Uri> _appLinksSubscription;

  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(() => _listenRouterChanges(widget.router.routerDelegate.currentConfiguration.fullPath));
    _appLinksSubscription = AppLinks().uriLinkStream.listen((uri) {
      myLogger.e('AppLinks uri: $uri');
      widget.router.go(uri.fragment);
    });
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(() => _listenRouterChanges(widget.router.routerDelegate.currentConfiguration.fullPath));
    _appLinksSubscription.cancel();
    super.dispose();
  }

  void _listenRouterChanges(String fullPath) {
    final navbarState = ref.read(navbarStateProvider);
    final enabledItems = navbarState.items.where((e) => e.isEnabled).toList();
    final enabledRoutes = enabledItems.map((e) => e.route).toList();

    final activeIndex = enabledRoutes.indexWhere((route) => fullPath.startsWith(route));
    if (activeIndex != -1 && navbarState.activeIndex != activeIndex) {
      ref.read(navbarStateProvider.notifier).update(navbarState: navbarState.copyWith(activeIndex: activeIndex));
    }
  }

  @override
  Widget build(BuildContext context) {
    Sizes.init(context);
    final MyTheme theme = ref.watch(themeProvider);

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
