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
import 'package:kronk/riverpod/chat/chats_screen_style_provider.dart';
import 'package:kronk/riverpod/chat/chats_ws_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/screens/chat/chat_screen.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/widgets/custom_drawer.dart';
import 'package:kronk/widgets/main_appbar.dart';
import 'package:kronk/widgets/navbar.dart';

/// ChatsScreen
class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ChatsScreenDisplayState displayState = ref.watch(chatsScreenStyleProvider);
    final bool isFloating = displayState.screenStyle == LayoutStyle.floating;

    final AsyncValue<Map<String, dynamic>> chatsWS = ref.watch(chatsWSNotifierProvider);

    chatsWS.when(
      data: (data) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(chatsNotifierProvider.notifier).handleEvents(data: data);
        });
        // Future.microtask(() {
        //   ref.read(chatsNotifierProvider.notifier).handleEvents(data: data);
        // });
      },
      error: (error, stackTrace) {
        myLogger.d('data: $error type: ${error.runtimeType}');
      },
      loading: () {
        myLogger.d('loading');
      },
    );

    ref.listen(chatsNotifierProvider, (previous, next) {
      final ChatModel? cached = ref.read(sharedChat);
      if (cached == null) return;

      final updated = next.value?.firstWhere((chat) => chat.id == cached.id, orElse: () => cached);
      if (updated != cached) {
        ref.read(sharedChat.notifier).state = updated;
      }
    });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: MainAppBar(titleText: 'Chats', tabText1: 'chats', tabText2: 'groups', onTap: () => showChatsScreenSettingsDialog(context)),
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

            const TabBarView(children: [ChatsWidget(), GroupsWidget()]),
          ],
        ),
        bottomNavigationBar: const Navbar(),
        drawer: const CustomDrawer(),
      ),
    );
  }
}

/// ChatsWidget
class ChatsWidget extends ConsumerStatefulWidget {
  const ChatsWidget({super.key});

  @override
  ConsumerState<ChatsWidget> createState() => _ChatsWidgetState();
}

class _ChatsWidgetState extends ConsumerState<ChatsWidget> {
  List<ChatModel> _previousChats = [];

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final AsyncValue<List<ChatModel>> chats = ref.watch(chatsNotifierProvider);
    return RefreshIndicator(
      color: theme.primaryText,
      backgroundColor: theme.secondaryBackground,
      onRefresh: () => ref.watch(chatsNotifierProvider.notifier).refresh(),
      child: chats.when(
        error: (error, stackTrace) {
          if (error is DioException) return Center(child: Text('${error.message}'));
          return Center(child: Text('$error'));
        },
        loading: () => ChatListWidget(chats: _previousChats, isRefreshing: true),
        data: (List<ChatModel> chats) {
          _previousChats = chats;
          return ChatListWidget(chats: chats, isRefreshing: false);
        },
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
    final ChatsScreenDisplayState displayState = ref.watch(chatsScreenStyleProvider);
    final bool isFloating = displayState.screenStyle == LayoutStyle.floating;
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
              separatorBuilder: (context, index) => SizedBox(height: 12.dp),
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
    final ChatsScreenDisplayState displayState = ref.watch(chatsScreenStyleProvider);
    final bool isFloating = displayState.screenStyle == LayoutStyle.floating;
    double blurSigma = isRefreshing ? 3 : 0;
    final bool showHole = chat.participant.isOnline;

    return GestureDetector(
      onTap: () {
        ref.read(sharedChat.notifier).state = chat;
        context.pushNamed('chat');
      },
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          tileColor: theme.primaryBackground.withValues(alpha: displayState.tileOpacity),
          contentPadding: EdgeInsets.symmetric(horizontal: 10.dp, vertical: 0),
          shape: RoundedRectangleBorder(
            borderRadius: isFloating ? BorderRadius.circular(displayState.tileBorderRadius) : BorderRadius.zero,
            side: isFloating ? BorderSide.none : BorderSide(color: theme.outline, width: 0.5.dp),
          ),
          leading: Stack(
            children: [
              /// Avatar
              AvatarWithHoleAnimated(
                showHole: showHole,
                holeRadius: 9.dp,
                avatarRadius: 28.dp,
                avatarUrl: '${constants.bucketEndpoint}/${chat.participant.avatarUrl}',
                blurSigma: blurSigma,
              ),

              /// Online & Offline status (animated)
              AnimatedIndicator(showHole: showHole, indicatorSize: 16.dp),
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
              // Fading message text with space before icon
              Expanded(
                child: Text(
                  '${chat.lastMessage?.message}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16.dp, fontWeight: FontWeight.w500),
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
      builder: (context, child) {
        return AvatarWithHole(holeRadius: _radiusAnimation.value, avatarRadius: widget.avatarRadius, avatar: child);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.dp),
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: widget.blurSigma, sigmaY: widget.blurSigma),
          child: CachedNetworkImage(
            imageUrl: widget.avatarUrl,
            fit: BoxFit.cover,
            width: 56.dp,
            memCacheWidth: 56.cacheSize(context),
            placeholder: (context, url) => Icon(Icons.account_circle_rounded, size: 56.dp, color: theme.primaryText),
            errorWidget: (context, url, error) => Icon(Icons.account_circle_rounded, size: 56.dp, color: theme.primaryText),
          ),
        ),
      ),
    );
  }
}

/// AvatarWithHole
class AvatarWithHole extends StatelessWidget {
  final double holeRadius;
  final double avatarRadius;
  final Widget? avatar;

  const AvatarWithHole({super.key, required this.holeRadius, required this.avatarRadius, required this.avatar});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: CircleHoleClipper(holeRadius: holeRadius, avatarRadius: avatarRadius),
      child: avatar,
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
    final Offset holeCenter = Offset(avatarCenter.dx + avatarRadius * cos(angle), avatarCenter.dy - avatarRadius * sin(angle));

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
class GroupsWidget extends ConsumerWidget {
  const GroupsWidget({super.key});

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

void showChatsScreenSettingsDialog(BuildContext context) {
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
          final theme = ref.watch(themeProvider);
          final ChatsScreenDisplayState displayState = ref.watch(chatsScreenStyleProvider);
          final bool isFloating = displayState.screenStyle == LayoutStyle.floating;

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
                                onTap: () => ref.read(chatsScreenStyleProvider.notifier).updateChatsScreenStyle(backgroundImagePath: imageName),
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
                          onTap: () => ref.read(chatsScreenStyleProvider.notifier).updateChatsScreenStyle(screenStyle: LayoutStyle.edgeToEdge),
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
                          onTap: () => ref.read(chatsScreenStyleProvider.notifier).updateChatsScreenStyle(screenStyle: LayoutStyle.floating),
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
                    value: displayState.tileBorderRadius,
                    min: 0,
                    max: 24,
                    activeColor: theme.primaryText,
                    inactiveColor: theme.primaryText.withValues(alpha: 0.2),
                    thumbColor: theme.primaryText,
                    onChanged: (double newRadius) => ref.read(chatsScreenStyleProvider.notifier).updateChatsScreenStyle(tileBorderRadius: newRadius),
                  ),

                  /// Slider opacity
                  Slider(
                    value: displayState.tileOpacity,
                    min: 0,
                    max: 1,
                    activeColor: theme.primaryText,
                    inactiveColor: theme.primaryText.withValues(alpha: 0.2),
                    thumbColor: theme.primaryText,
                    onChanged: (double newOpacity) => ref.read(chatsScreenStyleProvider.notifier).updateChatsScreenStyle(tileOpacity: newOpacity),
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
