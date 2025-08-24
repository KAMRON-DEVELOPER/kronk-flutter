import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kronk/bloc/authentication/authentication_bloc.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/riverpod/general/screen_style_state_provider.dart';
import 'package:kronk/screens/chat/chat_screen.dart';
import 'package:kronk/screens/chat/chats_screen.dart';
import 'package:kronk/screens/education/education_screen.dart';
import 'package:kronk/screens/feed/feed_screen.dart';
import 'package:kronk/screens/feed/feeds_screen.dart';
import 'package:kronk/screens/search_screen.dart';
import 'package:kronk/screens/user/auth_screen.dart';
import 'package:kronk/screens/user/edit_profile_screen.dart';
import 'package:kronk/screens/user/forgot_password_screen.dart';
import 'package:kronk/screens/user/notes_screen.dart';
import 'package:kronk/screens/user/player_screen.dart';
import 'package:kronk/screens/user/profile_screen.dart';
import 'package:kronk/screens/user/request_forgot_password_screen.dart';
import 'package:kronk/screens/user/settings_screen.dart';
import 'package:kronk/screens/user/todos_screen.dart';
import 'package:kronk/screens/user/translator_screen.dart';
import 'package:kronk/screens/user/verify_screen.dart';
import 'package:kronk/screens/user/welcome_screen.dart';
import 'package:kronk/screens/vocabulary/vocabularies_screen.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/widgets/custom_drawer.dart';
import 'package:kronk/widgets/image_cropper_screen.dart';
import 'package:kronk/widgets/navbar.dart';

final activeScreenNameProvider = StateProvider<String>((ref) => 'default');

@immutable
class ScaffoldConfig {
  final bool resizeToAvoidBottomInset;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  const ScaffoldConfig({this.resizeToAvoidBottomInset = false, this.appBar, this.floatingActionButton});
}

final scaffoldConfigProvider = StateProvider<ScaffoldConfig>((ref) => const ScaffoldConfig());

// router.dart - The Final ScreenConfigurator

class ScreenConfigurator extends ConsumerWidget {
  final bool resizeToAvoidBottomInset;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget body;

  const ScreenConfigurator({super.key, this.resizeToAvoidBottomInset = false, this.appBar, this.floatingActionButton, required this.body});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouterState state = GoRouterState.of(context);
    final String myScreenName = state.uri.pathSegments.isNotEmpty ? state.uri.pathSegments.first : 'default';

    ref.listen<String>(activeScreenNameProvider, (previous, next) {
      if (next == myScreenName) {
        final newConfig = ScaffoldConfig(resizeToAvoidBottomInset: resizeToAvoidBottomInset, appBar: appBar, floatingActionButton: floatingActionButton);
        ref.read(scaffoldConfigProvider.notifier).state = newConfig;
      }
    });

    final scaffoldConfig = ref.read(scaffoldConfigProvider);
    final isActive = ref.read(activeScreenNameProvider) == myScreenName;

    if (isActive && scaffoldConfig.appBar != appBar) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        ref.read(scaffoldConfigProvider.notifier).state = ScaffoldConfig(
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          appBar: appBar,
          floatingActionButton: floatingActionButton,
        );
      });
    }

    return body;
  }
}

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouterState state = GoRouterState.of(context);
    final String matchedLocation = state.matchedLocation;
    final String screenName = state.uri.pathSegments.isNotEmpty ? state.uri.pathSegments.first : 'default';
    const fullscreenRoutes = ['/feeds/:feedId', '/chats/:chatId', '/image_cropper/:type', '/profile/edit'];
    final isNavbarHidden = fullscreenRoutes.contains(matchedLocation);

    final scaffoldConfig = ref.watch(scaffoldConfigProvider);
    final screenStyle = ref.watch(screenStyleStateProvider(screenName));
    final isFloating = screenStyle.layoutStyle == LayoutStyle.floating;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (ref.read(activeScreenNameProvider) != screenName) {
        ref.read(activeScreenNameProvider.notifier).state = screenName;
      }
    });
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: scaffoldConfig.appBar,
      body: Stack(
        children: [
          if (isFloating)
            Positioned(
              left: 0,
              top: MediaQuery.of(context).padding.top - 52.dp,
              right: 0,
              bottom: 0,
              child: Opacity(
                opacity: 0.4,
                child: Image.asset(
                  screenStyle.backgroundImage,
                  fit: BoxFit.cover,
                  cacheHeight: (Sizes.screenHeight - MediaQuery.of(context).padding.top - 52.dp).cacheSize(context),
                  cacheWidth: Sizes.screenWidth.cacheSize(context),
                ),
              ),
            ),
          navigationShell,
        ],
      ),
      floatingActionButton: scaffoldConfig.floatingActionButton,
      bottomNavigationBar: AnimatedContainer(duration: const Duration(milliseconds: 200), height: isNavbarHidden ? 0 : Sizes.navbarHeight, child: const Navbar()),
    );
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: '_rootNavigatorKey');
final _feedsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: '_feedsNavigatorKey');
final _searchNavigatorKey = GlobalKey<NavigatorState>(debugLabel: '_searchNavigatorKey');
final _chatsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: '_chatsNavigatorKey');
final _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: '_profileNavigatorKey');
final _todosNavigatorKey = GlobalKey<NavigatorState>(debugLabel: '_todosNavigatorKey');
final _educationNavigatorKey = GlobalKey<NavigatorState>(debugLabel: '_educationNavigatorKey');
final _notesNavigatorKey = GlobalKey<NavigatorState>(debugLabel: '_notesNavigatorKey');
final _entertainmentNavigatorKey = GlobalKey<NavigatorState>(debugLabel: '_entertainmentNavigatorKey');
final _vocabulariesNavigatorKey = GlobalKey<NavigatorState>(debugLabel: '_vocabulariesNavigatorKey');
final _translatorNavigatorKey = GlobalKey<NavigatorState>(debugLabel: '_translatorNavigatorKey');

class AppRouter {
  final String initialLocation;

  AppRouter({required this.initialLocation});

  GoRouter get router => GoRouter(
    debugLogDiagnostics: false,
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    routes: <RouteBase>[
      GoRoute(
        path: '/welcome',
        pageBuilder: (context, state) => FadeTransitionPage(key: state.pageKey, child: const WelcomeScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => SlidePageTransition(key: state.pageKey, child: const SettingsScreen()),
      ),
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) {
          return SlidePageTransition(
            key: state.pageKey,
            child: BlocProvider(create: (context) => AuthenticationBloc(), child: const AuthScreen()),
          );
        },
        routes: [
          GoRoute(
            path: 'verify',
            pageBuilder: (context, state) => SlidePageTransition(
              key: state.pageKey,
              child: BlocProvider(create: (BuildContext context) => AuthenticationBloc(), child: const VerifyScreen()),
            ),
          ),
          GoRoute(
            path: 'request_forgot_password',
            pageBuilder: (context, state) => SlidePageTransition(
              key: state.pageKey,
              child: BlocProvider(create: (BuildContext context) => AuthenticationBloc(), child: const RequestForgotPasswordScreen()),
            ),
          ),
          GoRoute(
            path: 'forgot_password',
            pageBuilder: (context, state) => SlidePageTransition(
              key: state.pageKey,
              child: BlocProvider(create: (BuildContext context) => AuthenticationBloc(), child: const ResetPasswordScreen()),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/image_cropper/:type',
        pageBuilder: (context, state) => SlidePageTransition(
          key: state.pageKey,
          child: ImageCropperScreen(cropImageFor: state.pathParameters['type'] == 'avatar' ? CropImageFor.avatar : CropImageFor.banner),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            navigatorKey: _feedsNavigatorKey,
            routes: [
              GoRoute(
                path: '/feeds',
                pageBuilder: (context, state) => SlidePageTransition(key: state.pageKey, child: const FeedsScreen()),
                routes: [
                  GoRoute(
                    path: ':feedId',
                    pageBuilder: (context, state) => SlidePageTransition(
                      key: state.pageKey,
                      child: FeedScreen(feedId: state.extra as String),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _searchNavigatorKey,
            routes: [
              GoRoute(
                path: '/search',
                pageBuilder: (context, state) => SlidePageTransition(key: state.pageKey, child: const SearchScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _chatsNavigatorKey,
            routes: [
              GoRoute(
                path: '/chats',
                pageBuilder: (context, state) => SlidePageTransition(key: state.pageKey, child: const ChatsScreen()),
                routes: [
                  GoRoute(
                    path: ':chatId',
                    name: 'chat',
                    pageBuilder: (context, state) => SlidePageTransition(
                      key: state.pageKey,
                      child: ChatScreen(chatId: state.extra as String),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _educationNavigatorKey,
            routes: [
              GoRoute(
                path: '/education',
                pageBuilder: (context, state) => SlidePageTransition(key: state.pageKey, child: const EducationScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _notesNavigatorKey,
            routes: [
              GoRoute(
                path: '/notes',
                pageBuilder: (context, state) => SlidePageTransition(key: state.pageKey, child: const NotesScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _todosNavigatorKey,
            routes: [
              GoRoute(
                path: '/todos',
                pageBuilder: (context, state) => SlidePageTransition(key: state.pageKey, child: const TodosScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _entertainmentNavigatorKey,
            routes: [
              GoRoute(
                path: '/entertainment',
                pageBuilder: (context, state) => SlidePageTransition(key: state.pageKey, child: const PlayerScreen()),
              ),
            ],
          ),

          ///
          StatefulShellBranch(
            navigatorKey: _vocabulariesNavigatorKey,
            routes: [
              GoRoute(
                path: '/vocabulary',
                name: 'vocabulary',
                pageBuilder: (context, state) => SlidePageTransition(key: state.pageKey, child: const VocabulariesScreen()),
              ),
            ],
          ),

          StatefulShellBranch(
            navigatorKey: _translatorNavigatorKey,
            routes: [
              GoRoute(
                path: '/translator',
                name: 'translator',
                pageBuilder: (context, state) => SlidePageTransition(key: state.pageKey, child: const TranslatorScreen()),
              ),
            ],
          ),

          ///
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                pageBuilder: (context, state) => SlidePageTransition(key: state.pageKey, child: const ProfileScreen()),
                routes: [
                  GoRoute(
                    path: ':targetUserId',
                    name: 'preview',
                    pageBuilder: (context, state) => SlidePageTransition(
                      key: state.pageKey,
                      child: ProfileScreen(targetUserId: state.extra as String?),
                    ),
                  ),
                  GoRoute(
                    path: 'edit',
                    name: 'edit',
                    pageBuilder: (context, state) => SlidePageTransition(key: state.pageKey, child: const EditProfileScreen()),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorPageBuilder: (context, state) => const MaterialPage(child: Center(child: Text('Error'))),
  );
}

class FadeTransitionPage extends CustomTransitionPage<void> {
  FadeTransitionPage({required super.child, super.key})
    : super(
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
            child: child,
          );
        },
      );
}

class SlidePageTransition extends CustomTransitionPage<void> {
  SlidePageTransition({required super.child, super.key})
    : super(
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOut));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      );
}
