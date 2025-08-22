import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/constants/kronk_icon.dart';
import 'package:kronk/models/chat_model.dart';
import 'package:kronk/models/feed_model.dart';
import 'package:kronk/models/user_model.dart';
import 'package:kronk/riverpod/general/screen_style_state_provider.dart';
import 'package:kronk/riverpod/general/search_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/screens/chat/chat_screen.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/screen_style_state_dialog.dart';
import 'package:kronk/utility/storage.dart';
import 'package:kronk/widgets/custom_appbar.dart';
import 'package:kronk/widgets/feed/feed_card.dart';

final searchScreenTabIndexProvider = StateProvider<int>((ref) => 0);

/// SearchScreen
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void onTabChanged() {
    if (_tabController.indexIsChanging) return;
    ref.read(searchScreenTabIndexProvider.notifier).state = _tabController.index;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = ref.watch(themeProvider);
    final int tabIndex = ref.watch(searchScreenTabIndexProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(
        appBarHeight: 48.dp,
        bottomHeight: 40.dp,
        bottomGap: 4.dp,
        actionsSpacing: 8.dp,
        appBarPadding: EdgeInsets.only(left: 12.dp, right: 6.dp),
        bottomPadding: EdgeInsets.only(left: 12.dp, right: 12.dp, bottom: 4.dp),
        leading: Builder(
          builder: (context) => GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Icon(Icons.menu_rounded, color: theme.primaryText, size: 24.dp),
          ),
        ),
        title: Text(
          'Search',
          style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 24.dp, fontWeight: FontWeight.w500),
        ),
        actions: [
          GestureDetector(
            onTap: () => tabIndex == 0 ? showScreenStyleStateDialog(context, 'feeds') : showScreenStyleStateDialog(context, 'chats'),
            child: Icon(Icons.more_vert_rounded, color: theme.primaryText, size: 24.dp),
          ),
        ],
        bottom: Container(
          padding: EdgeInsets.all(2.dp),
          decoration: BoxDecoration(color: theme.secondaryBackground, borderRadius: BorderRadius.circular(12.dp)),
          child: TabBar(
            dividerHeight: 0,
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(color: theme.primaryBackground, borderRadius: BorderRadius.circular(10.dp)),
            labelStyle: GoogleFonts.quicksand(fontSize: 18.dp, color: theme.primaryText, fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.quicksand(fontSize: 18.dp, color: theme.secondaryText, fontWeight: FontWeight.w600),
            indicatorAnimation: TabIndicatorAnimation.elastic,
            tabs: [
              Tab(height: 36.dp, text: 'feed'),
              Tab(height: 36.dp, text: 'user'),
            ],
          ),
        ),
      ),
      body: TabBarView(controller: _tabController, children: [const FeedSearchWidget(), const UserSearchWidget()]),
    );
  }
}

/// FeedSearchWidget
class FeedSearchWidget extends ConsumerStatefulWidget {
  const FeedSearchWidget({super.key});

  @override
  ConsumerState<FeedSearchWidget> createState() => _FeedSearchWidgetState();
}

class _FeedSearchWidgetState extends ConsumerState<FeedSearchWidget> {
  late ScrollController _scrollController;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchController = TextEditingController();
    _scrollController.addListener(scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent) {
      ref.read(feedSearchNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final AsyncValue<List<FeedModel>> asyncFeeds = ref.watch(feedSearchNotifierProvider);
    final ScreenStyleState screenStyle = ref.watch(screenStyleStateProvider('feeds'));
    final bool isFloating = screenStyle.layoutStyle == LayoutStyle.floating;

    final BorderRadius borderRadius = BorderRadius.circular(isFloating ? screenStyle.borderRadius : 0);
    final BorderSide borderSide = BorderSide(color: theme.secondaryBackground, width: 0.5);
    return Stack(
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

        /// Content
        CustomScrollView(
          slivers: [
            /// Search field
            SliverToBoxAdapter(
              child: Container(
                height: 40.dp,
                margin: EdgeInsets.only(left: 12.dp, top: 12.dp, right: 12.dp),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16, fontWeight: FontWeight.w500),
                  cursorColor: theme.primaryText,
                  cursorWidth: 1,
                  cursorRadius: const Radius.circular(0.5),
                  cursorHeight: 20,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.primaryBackground.withValues(alpha: screenStyle.opacity),
                    border: OutlineInputBorder(borderRadius: borderRadius, borderSide: borderSide),
                    focusedBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: borderSide),
                    disabledBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: borderSide),
                    enabledBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: borderSide),
                    hint: Text(
                      'Search',
                      style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16.dp, fontWeight: FontWeight.w600),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10.dp, horizontal: 20.dp),
                    prefixIcon: Icon(Icons.search_rounded, size: 24.dp, color: theme.secondaryText),
                    suffixIcon: _searchController.text.isNotEmpty == true
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              ref.invalidate(feedSearchNotifierProvider);
                            },
                            icon: Icon(Icons.clear_rounded, size: 20.dp, color: theme.secondaryText),
                          )
                        : null,
                  ),
                  onChanged: (String searchQuery) => ref.read(feedSearchNotifierProvider.notifier).fetchSearchQueryResult(searchQuery: searchQuery),
                ),
              ),
            ),

            /// Feeds list
            asyncFeeds.when(
              data: (List<FeedModel> feeds) {
                if (feeds.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No results found. 🔍',
                        style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 32.dp, fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                }

                if (feeds.isNotEmpty) {
                  return SliverFillRemaining(
                    child: ListView.separated(
                      padding: EdgeInsets.all(12.dp),
                      itemCount: feeds.length,
                      separatorBuilder: (context, index) => SizedBox(height: 12.dp),
                      itemBuilder: (context, index) => FeedCard(initialFeed: feeds.elementAt(index), isRefreshing: false),
                    ),
                  );
                }
                return const SliverFillRemaining(child: SizedBox.shrink());
              },
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (e, st) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            ),
          ],
        ),
      ],
    );
  }
}

/// UserSearchWidget
class UserSearchWidget extends ConsumerStatefulWidget {
  const UserSearchWidget({super.key});

  @override
  ConsumerState<UserSearchWidget> createState() => _UserSearchWidgetState();
}

class _UserSearchWidgetState extends ConsumerState<UserSearchWidget> {
  late ScrollController _scrollController;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchController = TextEditingController();
    _scrollController.addListener(scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent) {
      ref.read(userSearchNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final AsyncValue<List<UserModel>> asyncUsers = ref.watch(userSearchNotifierProvider);
    final ScreenStyleState screenStyle = ref.watch(screenStyleStateProvider('chats'));
    final bool isFloating = screenStyle.layoutStyle == LayoutStyle.floating;

    final BorderRadius borderRadius = BorderRadius.circular(isFloating ? screenStyle.borderRadius : 0);
    final BorderSide borderSide = BorderSide(color: theme.secondaryBackground, width: 0.5);
    return Stack(
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

        /// Content
        CustomScrollView(
          slivers: [
            /// Search field
            SliverToBoxAdapter(
              child: Container(
                height: 40.dp,
                margin: EdgeInsets.only(left: 12.dp, top: 12.dp, right: 12.dp),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16, fontWeight: FontWeight.w500),
                  cursorColor: theme.primaryText,
                  cursorWidth: 1,
                  cursorRadius: const Radius.circular(0.5),
                  cursorHeight: 20,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.primaryBackground.withValues(alpha: screenStyle.opacity),
                    border: OutlineInputBorder(borderRadius: borderRadius, borderSide: borderSide),
                    focusedBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: borderSide),
                    disabledBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: borderSide),
                    enabledBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: borderSide),
                    hint: Text(
                      'Search',
                      style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16.dp, fontWeight: FontWeight.w600),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10.dp, horizontal: 20.dp),
                    prefixIcon: Icon(Icons.search_rounded, size: 24.dp, color: theme.secondaryText),
                    suffixIcon: _searchController.text.isNotEmpty == true
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              ref.invalidate(userSearchNotifierProvider);
                            },
                            icon: Icon(Icons.clear_rounded, size: 24.dp, color: theme.secondaryText),
                          )
                        : null,
                  ),
                  onChanged: (String searchQuery) => ref.read(userSearchNotifierProvider.notifier).fetchSearchQueryResult(searchQuery: searchQuery),
                ),
              ),
            ),

            /// Profile lists
            asyncUsers.when(
              data: (List<UserModel> userSearchResultList) {
                if (userSearchResultList.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No results found. 🔍',
                        style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 32.dp, fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                }

                if (userSearchResultList.isNotEmpty) {
                  return SliverFillRemaining(
                    child: ListView.separated(
                      padding: EdgeInsets.all(12.dp),
                      itemCount: userSearchResultList.length,
                      separatorBuilder: (context, index) => SizedBox(height: 12.dp),
                      itemBuilder: (context, index) {
                        final user = userSearchResultList.elementAt(index);
                        return ProfileSearchCard(user: user);
                      },
                    ),
                  );
                }
                return const SliverFillRemaining(child: SizedBox.shrink());
              },
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (e, st) {
                myLogger.e('Error: $e, StackTrace: $st');
                return SliverFillRemaining(child: Center(child: Text('Error: $e, StackTrace: $st')));
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// ProfileSearchCard
class ProfileSearchCard extends ConsumerWidget {
  final UserModel user;

  const ProfileSearchCard({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final storage = Storage();
        final cacheUser = storage.getUser();
        if (cacheUser.id == user.id) {
          myLogger.d('it is me..., user.name: ${user.name} vs cacheUser.name: ${cacheUser.name}');
          context.go('/profile');
        } else {
          myLogger.d('it is Adhambek...');
          context.pushNamed('previewProfile', extra: user.id);
        }
      },
      child: Card(
        color: theme.primaryBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.dp)),
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.dp, horizontal: 12.dp),
          child: Column(
            spacing: 12.dp,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Avatar, name, username, followers, followings, feeds
              Row(
                spacing: 12.dp,
                children: [
                  /// Avatar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28.dp),
                    child: Image.network(
                      '${constants.bucketEndpoint}/${user.avatarUrl}',
                      fit: BoxFit.cover,
                      width: 56.dp,
                      cacheWidth: 56.cacheSize(context),
                      loadingBuilder: (context, child, loadingProgress) =>
                          loadingProgress == null ? child : Icon(Icons.account_circle_rounded, size: 56.dp, color: theme.primaryText),
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.account_circle_rounded, size: 56.dp, color: theme.primaryText),
                    ),
                  ),

                  /// Name, username, followers, followings, feeds
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Name
                      Text(
                        user.name,
                        style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 12.dp, fontWeight: FontWeight.w500),
                      ),

                      /// Username
                      Text(
                        '@${user.username}',
                        style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 10.dp, fontWeight: FontWeight.w500),
                      ),

                      /// Followers & followings
                      Row(
                        spacing: 12.dp,
                        children: [
                          Row(
                            spacing: 4.dp,
                            children: [
                              Text(
                                '${user.followersCount}',
                                style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 10.dp, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'followers',
                                style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 10.dp, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          Row(
                            spacing: 4.dp,
                            children: [
                              Text(
                                '${user.followingsCount}',
                                style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 10.dp, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'followings',
                                style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 10.dp, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          Row(
                            spacing: 4.dp,
                            children: [
                              Text(
                                '0',
                                style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 10.dp, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'feeds',
                                style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 10.dp, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              /// Follow & chat buttons
              if (user.isFollowing != null)
                Row(
                  spacing: 12.dp,
                  children: [
                    /// Chat
                    GestureDetector(
                      onTap: () {
                        ref.read(sharedChatProvider.notifier).state = ChatModel(
                          participant: ParticipantModel(id: user.id, name: user.name, username: user.username),
                        );
                        context.go('/chats/chat');
                      },
                      child: Container(
                        alignment: Alignment.center,
                        padding: EdgeInsets.all(6.dp),
                        decoration: BoxDecoration(color: theme.secondaryBackground, borderRadius: BorderRadius.circular(18.dp)),
                        child: Icon(KronkIcon.messageCircleLeftOutline, size: 24.dp, color: theme.primaryText),
                      ),
                    ),

                    /// Follow & unfollow
                    GestureDetector(
                      onTap: () => ref.read(userSearchNotifierProvider.notifier).toggleFollow(userId: user.id),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 4.dp, horizontal: 12.dp),
                        decoration: BoxDecoration(color: user.isFollowing! ? theme.secondaryBackground : theme.primaryText, borderRadius: BorderRadius.circular(18.dp)),
                        child: Row(
                          spacing: 2.dp,
                          children: [
                            if (!user.isFollowing!) Icon(Icons.add_rounded, size: 22.dp, color: theme.primaryBackground),
                            Text(
                              user.isFollowing! ? 'Following' : 'Follow',
                              style: GoogleFonts.quicksand(color: user.isFollowing! ? theme.primaryText : theme.primaryBackground, fontSize: 18.dp, fontWeight: FontWeight.w600),
                            ),
                            if (!user.isFollowing!) SizedBox(width: 4.dp),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
