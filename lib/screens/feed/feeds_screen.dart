import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/feed_model.dart';
import 'package:kronk/riverpod/feed/feed_notification_provider.dart';
import 'package:kronk/riverpod/feed/feed_screen_style_provider.dart';
import 'package:kronk/riverpod/feed/timeline_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/exceptions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/widgets/custom_drawer.dart';
import 'package:kronk/widgets/feed/feed_card.dart';
import 'package:kronk/widgets/feed/feed_notification_widget.dart';
import 'package:kronk/widgets/main_appbar.dart';
import 'package:kronk/widgets/navbar.dart';

final feedsScreenTabIndexProvider = StateProvider<int>((ref) => 0);
final sharedFeed = StateProvider<FeedModel?>((ref) => null);

/// FeedsScreen
class FeedsScreen extends ConsumerWidget {
  const FeedsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    final FeedScreenDisplayState displayState = ref.watch(feedsScreenStyleProvider);
    final bool isFloating = displayState.screenStyle == ScreenStyle.floating;

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
            appBar: MainAppBar(titleText: 'Feeds', tabText1: 'discover', tabText2: 'following', onTap: () => showFeedScreenSettingsDialog(context)),
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
                        displayState.backgroundImagePath,
                        fit: BoxFit.cover,
                        cacheHeight: (Sizes.screenHeight - MediaQuery.of(context).padding.top - 52.dp).cacheSize(context),
                        cacheWidth: Sizes.screenWidth.cacheSize(context),
                      ),
                    ),
                  ),

                const TabBarView(
                  children: [
                    TimelineTab(timelineType: TimelineType.discover),
                    TimelineTab(timelineType: TimelineType.following),
                  ],
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                try {
                  final currentIndex = ref.read(feedsScreenTabIndexProvider);
                  final currentTimeline = currentIndex == 0 ? TimelineType.discover : TimelineType.following;
                  ref.read(timelineNotifierProvider(currentTimeline).notifier).createFeed();
                } catch (error) {
                  if (GoRouterState.of(context).path == '/feeds') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: theme.secondaryBackground,
                        behavior: SnackBarBehavior.floating,
                        dismissDirection: DismissDirection.horizontal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.dp)),
                        margin: EdgeInsets.only(left: 28.dp, right: 28.dp, bottom: Sizes.screenHeight - 96.dp),
                        content: Text(
                          'Failed to create feed: $error',
                          style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, height: 0),
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Icon(Icons.add_rounded),
            ),
            bottomNavigationBar: const Navbar(),
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
  List<FeedModel> _previousFeeds = [];

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
    final theme = ref.watch(themeNotifierProvider);
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
            loading: () => FeedListWidget(feeds: _previousFeeds, controller: _scrollController, isRefreshing: true),
            data: (List<FeedModel> feeds) {
              _previousFeeds = feeds;
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
    final theme = ref.watch(themeNotifierProvider);
    final FeedScreenDisplayState displayState = ref.watch(feedsScreenStyleProvider);
    final bool isFloating = displayState.screenStyle == ScreenStyle.floating;

    return Scrollbar(
      controller: controller,
      child: CustomScrollView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
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
                separatorBuilder: (context, index) => SizedBox(height: 12.dp),
                itemBuilder: (context, index) => FeedCard(key: ValueKey(feeds.elementAt(index).id), initialFeed: feeds.elementAt(index), isRefreshing: isRefreshing),
              ),
            ),
        ],
      ),
    );
  }
}

void showFeedScreenSettingsDialog(BuildContext context) {
  const List<String> backgroundImages = [
    '1.jpg',
    '2.jpg',
    '3.jpg',
    '5.jpg',
    '6.jpeg',
    '7.jpeg',
    '8.jpeg',
    '9.jpeg',
    '10.jpeg',
    '11.jpeg',
    '12.jpeg',
    '13.jpeg',
    '14.jpeg',
    '15.jpeg',
    '16.jpeg',
    '17.jpeg',
    '18.jpeg',
    '19.jpg',
    '20.jpg',
    '21.jpg',
    '22.jpg',
    '23.jpg',
    '24.jpg',
    '25.jpg',
    '26.jpg',
    '27.jpg',
    '28.jpg',
  ];

  showDialog(
    context: context,
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          final theme = ref.watch(themeNotifierProvider);
          final FeedScreenDisplayState displayState = ref.watch(feedsScreenStyleProvider);
          final bool isFloating = displayState.screenStyle == ScreenStyle.floating;

          final double width = 96.dp;
          final double height = 16 / 9 * width;
          return Dialog(
            backgroundColor: theme.tertiaryBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.dp)),
            child: Padding(
              padding: EdgeInsets.all(8.dp),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: 8.dp,
                children: [
                  /// Background image list
                  SizedBox(
                    height: height,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: backgroundImages.length,
                      itemBuilder: (context, index) {
                        final String imageName = 'assets/images/${backgroundImages.elementAt(index)}';
                        return Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            /// Images list
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.dp),
                              child: GestureDetector(
                                onTap: () => ref.read(feedsScreenStyleProvider.notifier).updateFeedScreenStyle(backgroundImagePath: imageName),
                                child: Image.asset(imageName, height: height, width: width, cacheHeight: height.cacheSize(context), cacheWidth: width.cacheSize(context)),
                              ),
                            ),

                            /// Selected background image indicator
                            if (displayState.backgroundImagePath == imageName)
                              Positioned(
                                bottom: 8.dp,
                                child: Icon(Icons.check_circle_rounded, color: theme.secondaryText, size: 32.dp),
                              ),
                          ],
                        );
                      },
                      separatorBuilder: (context, index) => SizedBox(width: 8.dp),
                    ),
                  ),

                  /// Toggle button
                  Row(
                    spacing: 8.dp,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => ref.read(feedsScreenStyleProvider.notifier).updateFeedScreenStyle(screenStyle: ScreenStyle.edgeToEdge),
                          child: Container(
                            height: 64.dp,
                            decoration: BoxDecoration(
                              color: theme.secondaryBackground,
                              borderRadius: BorderRadius.circular(8.dp),
                              border: Border.all(color: isFloating ? theme.secondaryBackground : theme.primaryText),
                            ),
                            child: Center(
                              child: Text(
                                'Edge-to-edge',
                                style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => ref.read(feedsScreenStyleProvider.notifier).updateFeedScreenStyle(screenStyle: ScreenStyle.floating),
                          child: Container(
                            height: 64.dp,
                            decoration: BoxDecoration(
                              color: theme.secondaryBackground,
                              borderRadius: BorderRadius.circular(8.dp),
                              border: Border.all(color: isFloating ? theme.primaryText : theme.secondaryBackground),
                            ),
                            child: Center(
                              child: Text(
                                'Floating',
                                style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  /// Slider Rounded Corner
                  Slider(
                    value: displayState.cardBorderRadius,
                    min: 0,
                    max: 24,
                    activeColor: theme.primaryText,
                    inactiveColor: theme.primaryText.withValues(alpha: 0.2),
                    thumbColor: theme.primaryText,
                    onChanged: (double newRadius) => ref.read(feedsScreenStyleProvider.notifier).updateFeedScreenStyle(cardBorderRadius: newRadius),
                  ),

                  /// Slider opacity
                  Slider(
                    value: displayState.cardOpacity,
                    min: 0,
                    max: 1,
                    activeColor: theme.primaryText,
                    inactiveColor: theme.primaryText.withValues(alpha: 0.2),
                    thumbColor: theme.primaryText,
                    onChanged: (double newOpacity) => ref.read(feedsScreenStyleProvider.notifier).updateFeedScreenStyle(cardOpacity: newOpacity),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
