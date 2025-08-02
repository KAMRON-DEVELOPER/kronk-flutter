import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/vocabulary_model.dart';
import 'package:kronk/riverpod/general/screen_style_state_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/riverpod/vocabulary/vocabularies_provider.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/screen_style_state_dialog.dart';
import 'package:kronk/widgets/custom_drawer.dart';
import 'package:kronk/widgets/main_appbar.dart';
import 'package:kronk/widgets/navbar.dart';

class VocabulariesScreen extends ConsumerWidget {
  const VocabulariesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ScreenStyleState displayState = ref.watch(screenStyleStateProvider('vocabulary'));
    final bool isFloating = displayState.layoutStyle == LayoutStyle.floating;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: MainAppBar(titleText: 'Vocabulary', tabText1: 'vocabularies', tabText2: 'create', onTap: () => showScreenStyleStateDialog(context, 'vocabulary')),
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
                    displayState.backgroundImage,
                    fit: BoxFit.cover,
                    cacheHeight: (Sizes.screenHeight - MediaQuery.of(context).padding.top - 52.dp).cacheSize(context),
                    cacheWidth: Sizes.screenWidth.cacheSize(context),
                  ),
                ),
              ),

            const TabBarView(children: [VocabulariesWidget(), CreateVocabulariesWidget()]),
          ],
        ),
        bottomNavigationBar: const Navbar(),
        drawer: const CustomDrawer(),
      ),
    );
  }
}

/// VocabulariesWidget
class VocabulariesWidget extends ConsumerStatefulWidget {
  const VocabulariesWidget({super.key});

  @override
  ConsumerState<VocabulariesWidget> createState() => _VocabulariesWidgetState();
}

class _VocabulariesWidgetState extends ConsumerState<VocabulariesWidget> {
  List<VocabularyModel> _previousVocabularies = [];

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final AsyncValue<List<VocabularyModel>> chats = ref.watch(vocabulariesProvider);
    return RefreshIndicator(
      color: theme.primaryText,
      backgroundColor: theme.secondaryBackground,
      onRefresh: () => ref.watch(vocabulariesProvider.notifier).refresh(),
      child: chats.when(
        error: (error, stackTrace) {
          if (error is DioException) return Center(child: Text('${error.message}'));
          return Center(child: Text('$error'));
        },
        loading: () => ChatListWidget(chats: _previousVocabularies, isRefreshing: true),
        data: (List<VocabularyModel> chats) {
          _previousVocabularies = chats;
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
    final bool isFloating = displayState.screenStyle == ScreenStyle.floating;
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
    final bool isFloating = displayState.screenStyle == ScreenStyle.floating;
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

/// CreateVocabulariesWidget
class CreateVocabulariesWidget extends ConsumerWidget {
  const CreateVocabulariesWidget({super.key});

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
