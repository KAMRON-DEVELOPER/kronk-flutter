import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/chat_message_model.dart';
import 'package:kronk/models/chat_model.dart';
import 'package:kronk/riverpod/chat/chat_messages_provider.dart';
import 'package:kronk/riverpod/chat/chat_state_provider.dart';
import 'package:kronk/riverpod/chat/chats_provider.dart';
import 'package:kronk/riverpod/chat/chats_websocket_provider.dart';
import 'package:kronk/riverpod/general/screen_style_state_provider.dart';
import 'package:kronk/riverpod/general/storage_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/screen_style_state_dialog.dart';

final sharedChatProvider = StateProvider<ChatModel?>((ref) => null);
final chatMessageControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(controller.dispose);
  return controller;
});

/// ChatScreen
class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final sharedChat = ref.watch(sharedChatProvider);
    final chat = ref.watch(chatStateProvider(sharedChat!));

    final ScreenStyleState screenStyle = ref.watch(screenStyleStateProvider('chats'));
    final bool isFloating = screenStyle.layoutStyle == LayoutStyle.floating;

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
                cacheHeight: (Sizes.screenHeight - MediaQuery.of(context).padding.top - 56.dp).cacheSize(context),
                cacheWidth: Sizes.screenWidth.cacheSize(context),
              ),
            ),
          ),

        /// Scaffold
        AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(statusBarColor: theme.primaryBackground, statusBarIconBrightness: Brightness.dark),
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: Colors.transparent,
            appBar: ChatAppBar(chat: chat),
            body: Column(
              children: [
                /// messages
                Expanded(child: chat.id != null ? const ChatMessagesWidget() : const InitialMessageWidget()),

                /// input bar
                const ChatInputWidget(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// ChatMessagesWidget
class ChatMessagesWidget extends ConsumerStatefulWidget {
  const ChatMessagesWidget({super.key});

  @override
  ConsumerState<ChatMessagesWidget> createState() => _ChatMessagesWidgetState();
}

class _ChatMessagesWidgetState extends ConsumerState<ChatMessagesWidget> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      final sharedChat = ref.read(sharedChatProvider);
      if (sharedChat?.id != null) {
        ref.read(chatMessagesStateProvider(sharedChat!.id!).notifier).loadMore(chatId: sharedChat.id!);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final sharedChat = ref.watch(sharedChatProvider);
    final chatId = sharedChat?.id ?? '';
    final chatMessagesState = ref.watch(chatMessagesStateProvider(chatId));

    ref.listen(chatMessagesStateProvider(sharedChat?.id ?? ''), (previous, next) {
      final prevMessages = previous?.value?.chatMessages ?? [];
      final nextMessages = next.value?.chatMessages ?? [];

      if (nextMessages.length > prevMessages.length) {
        if (prevMessages.isEmpty || nextMessages.first.id != prevMessages.first.id) {
          _scrollToBottom();
        }
      }
    });

    return RefreshIndicator(
      color: theme.primaryText,
      backgroundColor: theme.secondaryBackground,
      onRefresh: () => ref.read(chatMessagesStateProvider(chatId).notifier).refresh(chatId: chatId),
      child: chatMessagesState.when(
        data: (chatMessagesState) => Scrollbar(
          controller: _scrollController,
          child: ListView.separated(
            reverse: true,
            controller: _scrollController,
            itemCount: chatMessagesState.chatMessages.length + (chatMessagesState.hasMore ? 1 : 0),
            padding: EdgeInsets.all(12.dp),
            itemBuilder: (context, index) {
              if (chatMessagesState.hasMore && index == chatMessagesState.chatMessages.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return ChatMessageBubble(message: chatMessagesState.chatMessages.elementAt(index));
            },
            separatorBuilder: (context, index) => SizedBox(height: 12.dp),
          ),
        ),
        error: (error, stackTrace) => Text(
          error.toString(),
          style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        loading: () => Container(
          width: 32.dp,
          height: 32.dp,
          alignment: Alignment.topCenter,
          padding: EdgeInsets.only(top: 24.dp),
          child: FittedBox(child: CircularProgressIndicator(color: theme.primaryText)),
        ),
      ),
    );
  }
}

/// ChatMessageBubble
class ChatMessageBubble extends ConsumerWidget {
  final ChatMessageModel message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final storage = ref.watch(storageProvider);
    final ScreenStyleState screenStyle = ref.watch(screenStyleStateProvider('chats'));
    final isSentByUser = message.senderId == storage.getUser()?.id;

    return Row(
      mainAxisAlignment: isSentByUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Stack(
          children: [
            /// Message
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.dp, vertical: 6.dp),
              alignment: isSentByUser ? Alignment.centerRight : Alignment.centerLeft,
              decoration: BoxDecoration(
                color: (isSentByUser ? theme.tertiaryBackground : theme.primaryBackground).withValues(alpha: screenStyle.opacity),
                borderRadius: BorderRadius.circular(12.dp),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, fontWeight: FontWeight.w600),
                    children: [
                      TextSpan(text: message.message),
                      const TextSpan(
                        text: '12:00 PM',
                        style: TextStyle(color: Colors.transparent),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            /// Time & read/unread
            Positioned(
              right: 6.dp,
              bottom: 2.dp,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4.dp,
                children: [
                  Text(
                    message.createdAt.toChatTime(),
                    style: TextStyle(fontSize: 12.dp, color: theme.secondaryText),
                  ),
                  Icon(!message.isRead ? Icons.done_all : Icons.done, size: 14.dp, color: theme.secondaryText),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// ChatInputWidget
class ChatInputWidget extends ConsumerWidget {
  const ChatInputWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final storage = ref.watch(storageProvider);
    final sharedChat = ref.watch(sharedChatProvider);
    final notifier = ref.watch(chatStateProvider(sharedChat!).notifier);
    final messageController = ref.watch(chatMessageControllerProvider);

    Future<void> onTap() async {
      if (messageController.text.isEmpty) return;
      try {
        if (sharedChat.id == null) {
          final ChatModel chat = await ref.read(chatsProvider.notifier).createChat(message: messageController.text.trim(), participantId: sharedChat.participant.id);
          myLogger.w('chat.id: ${chat.id}, chat.participant.name: ${chat.participant.name}, chat.lastMessage: ${chat.lastMessage}');
          notifier.updateField(chat: chat);
          ref.read(chatMessagesStateProvider(chat.id!).notifier).addMessage(lastMessage: chat.lastMessage!);
        } else {
          ref
              .read(chatsWebsocketProvider.notifier)
              .sendMessage(chatId: sharedChat.id!, userId: storage.getUser()?.id ?? '', participantId: sharedChat.participant.id, message: messageController.text.trim());
        }
        messageController.clear();
      } catch (error) {
        myLogger.e('Exception while creating chat, e: ${error.toString()}');
      }
    }

    return SafeArea(
      top: false,
      child: Container(
        height: 56.dp,
        padding: EdgeInsets.symmetric(horizontal: 16.dp, vertical: 6.dp),
        decoration: BoxDecoration(
          color: theme.primaryBackground,
          border: Border(
            top: BorderSide(color: theme.secondaryBackground, width: 0.5.dp),
          ),
        ),
        child: Row(
          spacing: 16.dp,
          children: [
            /// Emoji picker
            Icon(Icons.emoji_emotions_outlined, size: 26.dp),

            /// Input
            Expanded(
              child: TextField(
                controller: messageController,
                onChanged: (value) => ref.read(chatsWebsocketProvider.notifier).handleTyping(chatId: sharedChat.id, text: value),
                style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 18.dp, fontWeight: FontWeight.w600),
                cursorColor: theme.primaryText,
                decoration: InputDecoration(
                  hintText: 'Message',
                  hintStyle: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 18.dp, fontWeight: FontWeight.w600),
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                ),
              ),
            ),

            /// Media, send or mic
            GestureDetector(
              onLongPressStart: (details) {},
              onLongPressEnd: (details) {},
              onTap: onTap,
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: messageController,
                builder: (context, value, child) {
                  final hasText = value.text.isNotEmpty;
                  return Row(
                    spacing: 16.dp,
                    children: [
                      /// Media picker
                      if (messageController.text.isEmpty) Icon(Icons.attach_file_rounded, size: 26.dp),

                      /// Send & mic
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        reverseDuration: const Duration(milliseconds: 200),
                        child: Icon(key: ValueKey<bool>(hasText), hasText ? Icons.send_rounded : Icons.mic_none_rounded, size: 26.dp),
                        transitionBuilder: (child, animation) => ScaleTransition(
                          scale: animation,
                          child: FadeTransition(opacity: animation, child: child),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// InitialMessageWidget
class InitialMessageWidget extends ConsumerWidget {
  const InitialMessageWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return Center(
      child: Text(
        'Send Message 💬',
        style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 24.dp, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// ChatAppBar
class ChatAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final ChatModel chat;

  const ChatAppBar({required this.chat, super.key});

  @override
  Size get preferredSize => Size(double.infinity, 56.5.dp);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return SafeArea(
      child: Container(
        height: 56.dp,
        padding: EdgeInsets.only(left: 12.dp, right: 12.dp),
        decoration: BoxDecoration(
          color: theme.primaryBackground,
          border: Border(
            bottom: BorderSide(color: theme.secondaryBackground, width: 0.5.dp),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            /// Left back button
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Icon(Icons.arrow_back_rounded, size: 28.dp, color: theme.primaryText),
              ),
            ),

            /// Avatar, name, last seen at, online status
            Align(
              alignment: const Alignment(-0.5, 0),
              child: Row(
                spacing: 8.dp,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  /// Avatar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22.dp),
                    child: CachedNetworkImage(
                      imageUrl: '${constants.bucketEndpoint}/${chat.participant.avatarUrl}',
                      fit: BoxFit.cover,
                      width: 44.dp,
                      memCacheWidth: 44.cacheSize(context),
                      placeholder: (context, url) => Icon(Icons.account_circle_rounded, size: 44.dp, color: theme.primaryText),
                      errorWidget: (context, url, error) => Icon(Icons.account_circle_rounded, size: 44.dp, color: theme.primaryText),
                    ),
                  ),

                  /// Name, last seen at, online status
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chat.participant.name,
                        style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, fontWeight: FontWeight.w500, height: 0),
                      ),
                      Text(
                        chat.participant.isTyping
                            ? 'typing...'
                            : chat.participant.isOnline
                            ? 'Online'
                            : 'Offline',
                        style: GoogleFonts.quicksand(
                          color: chat.participant.isOnline ? Colors.deepOrangeAccent : theme.secondaryText,
                          fontSize: 12.dp,
                          fontWeight: FontWeight.w500,
                          height: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => showScreenStyleStateDialog(context, 'chats'),
                child: Icon(Icons.more_vert_rounded, color: theme.primaryText, size: 28.dp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
