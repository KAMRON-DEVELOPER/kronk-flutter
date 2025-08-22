import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/feed_model.dart';
import 'package:kronk/riverpod/feed/feed_notification_provider.dart';
import 'package:kronk/riverpod/feed/timeline_provider.dart';
import 'package:kronk/riverpod/general/screen_style_state_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/exceptions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/screen_style_state_dialog.dart';
import 'package:kronk/widgets/custom_drawer.dart';
import 'package:kronk/widgets/feed/feed_card.dart';
import 'package:kronk/widgets/feed/feed_notification_widget.dart';
import 'package:kronk/widgets/main_appbar.dart';

final feedsScreenTabIndexProvider = StateProvider<int>((ref) => 0);
final sharedFeed = StateProvider<FeedModel?>((ref) => null);

/// FeedsScreen
class FeedsScreen extends ConsumerWidget {
  const FeedsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ScreenStyleState screenStyle = ref.watch(screenStyleStateProvider('feeds'));
    final bool isFloating = screenStyle.layoutStyle == LayoutStyle.floating;

    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);
          tabController.addListener(() {
            ref.read(feedsScreenTabIndexProvider.notifier).state = tabController.index;
          });
          return Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: MainAppBar(titleText: 'Feeds', tabText1: 'discover', tabText2: 'following', onTap: () => showScreenStyleStateDialog(context, 'feeds')),
            body: Stack(
              children: [
                /// Static background images
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

                /// TabBarView
                const TabBarView(
                  children: [
                    TimelineTab(timelineType: TimelineType.discover),
                    TimelineTab(timelineType: TimelineType.following),
                  ],
                ),

                /// FloatingActionButton
                Positioned(
                  right: 10.dp,
                  bottom: 10.dp,
                  child: FloatingActionButton(
                    onPressed: () {
                      try {
                        final currentIndex = ref.read(feedsScreenTabIndexProvider);
                        final currentTimeline = currentIndex == 0 ? TimelineType.discover : TimelineType.following;
                        ref.read(timelineNotifierProvider(currentTimeline).notifier).createFeed();
                      } catch (error) {
                        myLogger.w('catch while adding feed creating card, e" $e');
                      }
                    },
                    child: const Icon(Icons.add_rounded),
                  ),
                ),
              ],
            ),
            drawer: const CustomDrawer(),
          );
        },
      ),
    );
  }
}

/// TimelineTab
class TimelineTab extends ConsumerStatefulWidget {
  final TimelineType timelineType;

  const TimelineTab({super.key, required this.timelineType});

  @override
  ConsumerState<TimelineTab> createState() => _TimelineTabState();
}

class _TimelineTabState extends ConsumerState<TimelineTab> with AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void scrollListener() {
    ref.read(feedsScreenScrollPositionProvider.notifier).state = _scrollController.position.pixels;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent) {
      ref.read(timelineNotifierProvider(widget.timelineType).notifier).loadMore(timelineType: widget.timelineType);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = ref.watch(themeProvider);
    final AsyncValue<List<FeedModel>> feeds = ref.watch(timelineNotifierProvider(widget.timelineType));

    ref.listen(feedNotificationNotifierProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          if (error is NoValidTokenException) {
            if (GoRouterState.of(context).path == '/feeds') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: theme.secondaryBackground,
                  behavior: SnackBarBehavior.floating,
                  dismissDirection: DismissDirection.horizontal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.dp)),
                  margin: EdgeInsets.only(left: 28.dp, right: 28.dp, bottom: Sizes.screenHeight - 96.dp),
                  content: Text(
                    'You token is expired or not authenticated.',
                    style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, height: 0),
                  ),
                ),
              );
            }
          }
        },
      );
    });

    ref.listen(
      timelineNotifierProvider(widget.timelineType),
      (previous, next) => next.whenOrNull(
        error: (error, stackTrace) {
          if (error is DioException) {
            context.go('/auth');
          }
        },
      ),
    );

    return Stack(
      children: [
        /// Feeds
        RefreshIndicator(
          color: theme.primaryText,
          backgroundColor: theme.secondaryBackground,
          // onRefresh: () => ref.refresh(timelineNotifierProvider(widget.timelineType).future),
          onRefresh: () {
            ref.read(feedNotificationNotifierProvider.notifier).clearNotifications();
            return ref.read(timelineNotifierProvider(widget.timelineType).notifier).refresh(timelineType: widget.timelineType);
          },
          child: feeds.when(
            error: (error, stackTrace) {
              if (error is DioException) return Center(child: Text('${error.message}'));
              return Center(child: Text('$error'));
            },
            loading: () => FeedListWidget(feeds: feeds.valueOrNull ?? [], controller: _scrollController, isRefreshing: feeds.isLoading && feeds.hasValue),
            data: (List<FeedModel> feeds) {
              return FeedListWidget(feeds: feeds, controller: _scrollController);
            },
          ),
        ),

        /// Notification bubble
        FeedNotificationWidget(scrollController: _scrollController, refreshKey: _refreshKey),
      ],
    );
  }
}

/// FeedListWidget
class FeedListWidget extends ConsumerWidget {
  final List<FeedModel> feeds;
  final ScrollController? controller;
  final bool isRefreshing;

  const FeedListWidget({super.key, required this.feeds, this.controller, this.isRefreshing = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final ScreenStyleState screenStyle = ref.watch(screenStyleStateProvider('feeds'));
    final bool isFloating = screenStyle.layoutStyle == LayoutStyle.floating;

    return Scrollbar(
      controller: controller,
      child: CustomScrollView(
        cacheExtent: 3000,
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          if (feeds.isEmpty && !isRefreshing)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'No feeds yet. 🦄',
                      style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 32.dp, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'You can add the first!',
                      style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 32.dp, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

          if (feeds.isNotEmpty)
            SliverPadding(
              padding: EdgeInsets.all(isFloating ? 12.dp : 0),
              sliver: SliverList.separated(
                itemCount: feeds.length,
                addAutomaticKeepAlives: true,
                separatorBuilder: (context, index) => SizedBox(height: 12.dp),
                itemBuilder: (context, index) => FeedCard(key: ValueKey(feeds.elementAt(index).id), initialFeed: feeds.elementAt(index), isRefreshing: isRefreshing),
              ),
            ),
        ],
      ),
    );
  }
}
