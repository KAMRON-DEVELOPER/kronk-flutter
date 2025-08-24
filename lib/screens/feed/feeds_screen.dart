import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/feed_model.dart';
import 'package:kronk/riverpod/feed/feed_notification_provider.dart';
import 'package:kronk/riverpod/feed/timeline_provider.dart';
import 'package:kronk/riverpod/general/screen_style_state_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/router.dart';
import 'package:kronk/widgets/custom_appbar.dart';
import 'package:kronk/widgets/feed/feed_card.dart';
import 'package:kronk/widgets/feed/feed_notification_widget.dart';

/*
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
          )
 */
final feedsScreenTabIndexProvider = StateProvider<int>((ref) => 0);
final sharedFeed = StateProvider<FeedModel?>((ref) => null);

/// FeedsScreen
class FeedsScreen extends ConsumerStatefulWidget {
  const FeedsScreen({super.key});

  @override
  ConsumerState<FeedsScreen> createState() => _FeedsScreenState();
}

class _FeedsScreenState extends ConsumerState<FeedsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(feedsScreenTabIndexProvider.notifier).state = _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenConfigurator(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(screenName: 'feeds', tabController: _tabController, titleText: 'Feeds', tabText1: 'discover', tabText2: 'following'),
      floatingActionButton: FloatingActionButton(
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
      body: TabBarView(
        controller: _tabController,
        children: const [
          TimelineTab(timelineType: TimelineType.discover),
          TimelineTab(timelineType: TimelineType.following),
        ],
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
    final feeds = ref.watch(timelineNotifierProvider(widget.timelineType));

    ref.listen(feedNotificationNotifierProvider, (previous, next) {
      next.whenOrNull(error: (error, stackTrace) {});
    });

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
