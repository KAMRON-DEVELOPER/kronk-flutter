import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/models/feed_model.dart';
import 'package:kronk/riverpod/feed/timeline_provider.dart';
import 'package:kronk/riverpod/general/screen_style_state_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/screens/feed/feeds_screen.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/screen_style_state_dialog.dart';
import 'package:kronk/widgets/custom_appbar.dart';
import 'package:kronk/widgets/feed/feed_card.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(sharedFeed);
    final MyTheme theme = ref.watch(themeProvider);
    final ScreenStyleState screenStyle = ref.watch(screenStyleStateProvider('feeds'));
    final bool isFloating = screenStyle.layoutStyle == LayoutStyle.floating;

    return Scaffold(
      appBar: CustomAppBar(
        appBarHeight: 48.dp,
        bottomHeight: 0,
        bottomGap: 1,
        actionsSpacing: 8.dp,
        appBarPadding: EdgeInsets.only(left: 12.dp, right: 6.dp),
        bottomPadding: EdgeInsets.only(left: 12.dp, right: 12.dp, bottom: 4.dp),
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Icon(Icons.arrow_back_rounded, color: theme.primaryText, size: 24),
        ),
        title: Text(
          'Comments',
          style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 24.dp, fontWeight: FontWeight.w500),
        ),
        actions: [
          GestureDetector(
            onTap: () => showScreenStyleStateDialog(context, 'feeds'),
            child: Icon(Icons.more_vert_rounded, color: theme.primaryText, size: 24.dp),
          ),
        ],
      ),
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
                  cacheHeight: (Sizes.screenHeight - MediaQuery.of(context).padding.top - 49.dp).cacheSize(context),
                  cacheWidth: Sizes.screenWidth.cacheSize(context),
                ),
              ),
            ),

          /// Content
          RefreshIndicator(
            color: theme.primaryText,
            backgroundColor: theme.secondaryBackground,
            onRefresh: () => ref.refresh(commentNotifierProvider(feed.id).notifier).refresh(parentId: feed.id),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                /// Main Feed
                SliverPadding(
                  padding: EdgeInsets.all(isFloating ? 12.dp : 0),
                  sliver: SliverToBoxAdapter(child: FeedCard(initialFeed: feed!, isRefreshing: false)),
                ),

                /// Comments Section
                CommentWidget(parentId: feed.id),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CommentWidget extends ConsumerStatefulWidget {
  final String? parentId;

  const CommentWidget({super.key, required this.parentId});

  @override
  ConsumerState<CommentWidget> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends ConsumerState<CommentWidget> {
  List<FeedModel> _previousFeeds = [];

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<FeedModel>> feeds = ref.watch(commentNotifierProvider(widget.parentId));

    return feeds.when(
      error: (error, stackTrace) {
        if (error is DioException) return Center(child: Text('${error.message}'));
        return SliverToBoxAdapter(child: Center(child: Text('$error')));
      },
      loading: () => CommentListWidget(comments: _previousFeeds, isRefreshing: true),
      data: (List<FeedModel> comments) {
        _previousFeeds = comments;
        return CommentListWidget(comments: comments);
      },
    );
  }
}

class CommentListWidget extends ConsumerWidget {
  final List<FeedModel> comments;
  final bool isRefreshing;

  const CommentListWidget({super.key, required this.comments, this.isRefreshing = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MyTheme theme = ref.watch(themeProvider);
    final ScreenStyleState screenStyle = ref.watch(screenStyleStateProvider('feeds'));
    final bool isFloating = screenStyle.layoutStyle == LayoutStyle.floating;

    myLogger.i('CommentListWidget is building...');

    if (comments.isEmpty && !isRefreshing) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'No comments yet. 📨',
                style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 28.dp, fontWeight: FontWeight.bold),
              ),
              Text(
                'You can add the first!',
                style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 28.dp, fontWeight: FontWeight.bold),
              ),
              Icon(Icons.arrow_downward_rounded, color: theme.primaryText, size: 36),
              Text(
                'Later',
                style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 28.dp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.all(isFloating ? 12.dp : 0),
      sliver: SliverList.separated(
        itemCount: comments.length,
        separatorBuilder: (context, index) => SizedBox(height: 12.dp),
        itemBuilder: (context, index) {
          return FeedCard(key: ValueKey(comments[index].id), initialFeed: comments[index], isRefreshing: isRefreshing);
        },
      ),
    );
  }
}
