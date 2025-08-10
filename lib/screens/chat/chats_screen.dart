import 'dart:math';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/chat_model.dart';
import 'package:kronk/riverpod/chat/chats_provider.dart';
import 'package:kronk/riverpod/chat/chats_websocket_provider.dart';
import 'package:kronk/riverpod/general/screen_style_state_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/screens/chat/chat_screen.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/screen_style_state_dialog.dart';
import 'package:kronk/widgets/custom_drawer.dart';
import 'package:kronk/widgets/main_appbar.dart';
import 'package:kronk/widgets/navbar.dart';

/// ChatsScreen
class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ScreenStyleState screenStyle = ref.watch(screenStyleStateProvider('chats'));
    final bool isFloating = screenStyle.layoutStyle == LayoutStyle.floating;

    ref.listen(chatsWebsocketProvider, (previous, next) => next.whenData((data) => ref.read(chatsProvider.notifier).handleWebsocketEvents(data: data)));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: MainAppBar(titleText: 'Chats', tabText1: 'chats', tabText2: 'groups', onTap: () => showScreenStyleStateDialog(context, 'chats')),
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
            const TabBarView(children: [ChatsTabBar(), GroupsTabBar()]),
          ],
        ),
        bottomNavigationBar: const Navbar(),
        drawer: const CustomDrawer(),
      ),
    );
  }
}

/// ChatsTabBar
class ChatsTabBar extends ConsumerWidget {
  const ChatsTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final AsyncValue<List<ChatModel>> chats = ref.watch(chatsProvider);
    return RefreshIndicator(
      color: theme.primaryText,
      backgroundColor: theme.secondaryBackground,
      onRefresh: () => ref.watch(chatsProvider.notifier).refresh(),
      child: chats.when(
        data: (List<ChatModel> chats) {
          return ChatListWidget(chats: chats, isRefreshing: false);
        },
        error: (error, stackTrace) {
          if (error is DioException) return Center(child: Text('${error.message}'));
          return Center(child: Text(error.toString()));
        },
        loading: () => ChatListWidget(chats: chats.valueOrNull ?? [], isRefreshing: chats.isLoading && chats.hasValue),
      ),
    );
  }
}

/// ChatListWidget
class ChatListWidget extends ConsumerWidget {
  final List<ChatModel> chats;
  final bool isRefreshing;

  const ChatListWidget({super.key, required this.chats, required this.isRefreshing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final ScreenStyleState screenStyle = ref.watch(screenStyleStateProvider('chats'));
    final bool isFloating = screenStyle.layoutStyle == LayoutStyle.floating;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (chats.isEmpty && !isRefreshing)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No chats yet. 💬',
                    style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 32.dp, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Find people to chat.',
                    style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 32.dp, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),

        if (chats.isNotEmpty)
          SliverPadding(
            padding: EdgeInsets.all(isFloating ? 12.dp : 0),
            sliver: SliverList.separated(
              itemCount: chats.length,
              separatorBuilder: (context, index) => SizedBox(height: isFloating ? 12.dp : 0),
              itemBuilder: (context, index) => ChatTile(key: ValueKey(chats.elementAt(index).id), chat: chats.elementAt(index), isRefreshing: isRefreshing),
            ),
          ),
      ],
    );
  }
}

/// ChatTile
class ChatTile extends ConsumerWidget {
  final ChatModel chat;
  final bool isRefreshing;

  const ChatTile({super.key, required this.chat, required this.isRefreshing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final ScreenStyleState screenStyle = ref.watch(screenStyleStateProvider('chats'));
    final bool isFloating = screenStyle.layoutStyle == LayoutStyle.floating;
    double blurSigma = isRefreshing ? 3 : 0;
    final bool showHole = chat.participant.isOnline;

    return GestureDetector(
      onTap: () {
        ref.read(sharedChatProvider.notifier).state = chat;
        context.pushNamed('chat');
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.primaryBackground.withValues(alpha: screenStyle.opacity),
          border: BoxBorder.fromBorderSide(isFloating ? BorderSide.none : BorderSide(color: theme.outline, width: 0.5.dp)),
          borderRadius: isFloating ? BorderRadius.circular(screenStyle.borderRadius) : BorderRadius.zero,
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 10.dp, vertical: 0),
          leading: Stack(
            children: [
              /// Avatar
              AvatarWithHoleAnimated(
                showHole: showHole,
                holeRadius: 7.dp,
                avatarRadius: 28.dp,
                avatarUrl: '${constants.bucketEndpoint}/${chat.participant.avatarUrl}',
                blurSigma: blurSigma,
              ),

              /// Online & Offline status (animated)
              AnimatedIndicator(showHole: showHole, indicatorSize: 12.dp),
            ],
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                chat.participant.name,
                style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, fontWeight: FontWeight.w500),
              ),

              if (chat.lastActivityAt != null)
                Text(
                  chat.lastActivityAt!.toChatLabel(),
                  style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16.dp, fontWeight: FontWeight.w500),
                ),
            ],
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(
                  chat.participant.isTyping ? 'typing...' : '${chat.lastMessage?.message}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.quicksand(color: chat.participant.isTyping ? Colors.deepOrangeAccent : theme.secondaryText, fontSize: 16.dp, fontWeight: FontWeight.w500),
                ),
              ),

              // Selection or unread icon (always visible, not faded)
              SizedBox(
                width: 24.dp,
                height: 24.dp,
                // TODO Selection & Unread count widgets
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// AvatarWithHoleAnimated
class AvatarWithHoleAnimated extends ConsumerStatefulWidget {
  final bool showHole;
  final double holeRadius;
  final double avatarRadius;
  final String avatarUrl;
  final double blurSigma;

  const AvatarWithHoleAnimated({super.key, required this.showHole, required this.holeRadius, required this.avatarRadius, required this.avatarUrl, required this.blurSigma});

  @override
  ConsumerState<AvatarWithHoleAnimated> createState() => _AvatarWithHoleAnimatedState();
}

class _AvatarWithHoleAnimatedState extends ConsumerState<AvatarWithHoleAnimated> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _radiusAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100), reverseDuration: const Duration(milliseconds: 100));

    final curve = CurvedAnimation(parent: _controller, curve: Curves.linear, reverseCurve: Curves.linear);
    _radiusAnimation = Tween<double>(begin: 0, end: widget.holeRadius).animate(curve);

    if (widget.showHole) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void didUpdateWidget(covariant AvatarWithHoleAnimated oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showHole != oldWidget.showHole) {
      if (widget.showHole) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    return AnimatedBuilder(
      animation: _radiusAnimation,
      builder: (context, child) => ClipPath(
        clipper: CircleHoleClipper(holeRadius: _radiusAnimation.value, avatarRadius: widget.avatarRadius),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.avatarRadius),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: widget.blurSigma, sigmaY: widget.blurSigma),
            child: CachedNetworkImage(
              imageUrl: widget.avatarUrl,
              fit: BoxFit.cover,
              memCacheWidth: 2 * widget.avatarRadius.cacheSize(context),
              placeholder: (context, url) => Icon(Icons.account_circle_rounded, size: 51.dp, color: theme.primaryText),
              errorWidget: (context, url, error) => Icon(Icons.account_circle_rounded, size: 51.dp, color: theme.primaryText),
            ),
          ),
        ),
      ),
    );
  }
}

/// CircleHoleClipper
class CircleHoleClipper extends CustomClipper<Path> {
  final double holeRadius;
  final double avatarRadius;

  CircleHoleClipper({required this.holeRadius, required this.avatarRadius});

  @override
  Path getClip(Size size) {
    final path = Path()..addRRect(RRect.fromLTRBR(0, 0, size.width, size.width, Radius.circular(size.width / 2)));

    final Offset avatarCenter = Offset(size.width / 2, size.height / 2);

    // 315 degrees == -45 degrees in radians
    final double angle = -pi / 4;
    final Offset holeCenter = Offset(avatarCenter.dx + avatarRadius * cos(angle) - 1.5.dp, avatarCenter.dy - avatarRadius * sin(angle) - 1.5.dp);

    final holePath = Path()..addOval(Rect.fromCircle(center: holeCenter, radius: holeRadius));

    return Path.combine(PathOperation.difference, path, holePath);
  }

  @override
  bool shouldReclip(covariant CircleHoleClipper oldClipper) {
    return oldClipper.holeRadius != holeRadius;
  }
}

/// AnimatedIndicator
class AnimatedIndicator extends StatefulWidget {
  final bool showHole;
  final double indicatorSize;

  const AnimatedIndicator({super.key, required this.showHole, required this.indicatorSize});

  @override
  State<AnimatedIndicator> createState() => _AnimatedIndicatorState();
}

class _AnimatedIndicatorState extends State<AnimatedIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _sizeAnimation;
  late final Animation<double> _positionAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100), reverseDuration: const Duration(milliseconds: 100));

    final curve = CurvedAnimation(parent: _controller, curve: Curves.linear, reverseCurve: Curves.linear);
    _sizeAnimation = Tween<double>(begin: 0, end: widget.indicatorSize).animate(curve);
    _positionAnimation = Tween<double>(begin: 6.dp, end: 0.dp).animate(curve);

    if (widget.showHole) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showHole != oldWidget.showHole) {
      if (widget.showHole) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        return Positioned(
          bottom: _positionAnimation.value,
          right: _positionAnimation.value,
          child: Icon(Icons.circle_rounded, color: Colors.green, size: _sizeAnimation.value),
        );
      },
    );
  }
}

/// GroupsWidget
class GroupsTabBar extends ConsumerWidget {
  const GroupsTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return Center(
      child: Text(
        'Will be available soon, ⌛',
        style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 24.dp, fontWeight: FontWeight.bold),
      ),
    );
  }
}
