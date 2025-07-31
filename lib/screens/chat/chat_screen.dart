import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/chat_message_model.dart';
import 'package:kronk/models/chat_model.dart';
import 'package:kronk/riverpod/chat/chat_messages_provider.dart';
import 'package:kronk/riverpod/chat/chat_state_provider.dart';
import 'package:kronk/riverpod/chat/chats_provider.dart';
import 'package:kronk/riverpod/chat/chats_screen_style_provider.dart';
import 'package:kronk/riverpod/chat/chats_ws_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/screens/chat/chats_screen.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/storage.dart';

final sharedChat = StateProvider<ChatModel?>((ref) => null);
final inputMessageProvider = StateProvider<String>((ref) => '');

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late Storage _storage;
  late String userId;

  @override
  void initState() {
    super.initState();
    _storage = Storage();
    final user = _storage.getUser();
    userId = user?.id ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final initialChat = ref.watch(sharedChat);
    final chat = ref.watch(chatStateProvider(initialChat!));
    final notifier = ref.watch(chatStateProvider(initialChat).notifier);

    final ChatsScreenDisplayState displayState = ref.watch(chatsScreenStyleProvider);
    final bool isFloating = displayState.screenStyle == ScreenStyle.floating;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: ChatAppBar(chat: chat),
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
                  cacheHeight: (Sizes.screenHeight - MediaQuery.of(context).padding.top - 56.dp).cacheSize(context),
                  cacheWidth: Sizes.screenWidth.cacheSize(context),
                ),
              ),
            ),

          /// Content
          Column(
            children: [
              /// messages
              Expanded(
                child: chat.id != null ? ChatMessagesWidget(userId: userId, chatId: chat.id!, notifier: notifier) : const InitialMessageWidget(),
              ),

              /// input bar
              ChatInputWidget(userId: userId, chat: chat, notifier: notifier),
            ],
          ),
        ],
      ),
    );
  }
}

class ChatMessagesWidget extends ConsumerStatefulWidget {
  final String userId;
  final String chatId;
  final ChatStateStateNotifier notifier;

  const ChatMessagesWidget({super.key, required this.userId, required this.chatId, required this.notifier});

  @override
  ConsumerState<ChatMessagesWidget> createState() => _ChatMessagesWidgetState();
}

class _ChatMessagesWidgetState extends ConsumerState<ChatMessagesWidget> {
  late ScrollController _scrollController;
  bool _shouldScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void didUpdateWidget(covariant ChatMessagesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _shouldScrollToBottom = true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);
    final AsyncValue<List<ChatMessageModel>> messages = ref.watch(chatMessagesProvider(widget.chatId));
    return messages.when(
      data: (List<ChatMessageModel> messages) {
        if (_shouldScrollToBottom) {
          _scrollToBottom();
          _shouldScrollToBottom = false;
        }

        return NotificationListener<ScrollEndNotification>(
          onNotification: (notification) {
            return false;
          },
          child: RefreshIndicator(
            color: theme.primaryText,
            backgroundColor: theme.secondaryBackground,
            onRefresh: () => ref.read(chatMessagesProvider(widget.chatId).notifier).refresh(chatId: widget.chatId),
            child: ListView.separated(
              itemCount: messages.length,
              padding: EdgeInsets.all(12.dp),
              itemBuilder: (context, index) => MessageBubble(userId: widget.userId, message: messages.elementAt(index)),
              separatorBuilder: (context, index) => SizedBox(height: 12.dp),
            ),
          ),
        );
      },
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
    );
  }
}

class MessageBubble extends ConsumerWidget {
  final String userId;
  final ChatMessageModel message;

  const MessageBubble({super.key, required this.userId, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    final ChatsScreenDisplayState displayState = ref.watch(chatsScreenStyleProvider);
    final isSentByUser = message.senderId == userId;

    return Row(
      mainAxisAlignment: isSentByUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.dp, vertical: 4.dp),
          alignment: isSentByUser ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: theme.primaryBackground.withValues(alpha: displayState.tileOpacity),
            borderRadius: BorderRadius.circular(12.dp),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
            child: Text(
              message.message,
              softWrap: true,
              overflow: TextOverflow.visible,
              style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class ChatInputWidget extends ConsumerStatefulWidget {
  final String userId;
  final ChatModel chat;
  final ChatStateStateNotifier notifier;

  const ChatInputWidget({super.key, required this.userId, required this.chat, required this.notifier});

  @override
  ConsumerState<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends ConsumerState<ChatInputWidget> {
  late TextEditingController messageController;

  @override
  void initState() {
    super.initState();
    messageController = TextEditingController();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);
    final String inputMessage = ref.watch(inputMessageProvider);
    return SafeArea(
      top: false,
      child: Container(
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
            Icon(Icons.emoji_emotions_rounded, size: 26.dp),
            Expanded(
              child: TextField(
                controller: messageController,
                onChanged: (value) {
                  ref.read(inputMessageProvider.notifier).state = value;
                  // ref.read(chatsWSNotifierProvider.notifier).handleTyping(chatId: widget.chat.id!, text: value); // TODO
                },
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

            if (inputMessage.isNotEmpty)
              GestureDetector(
                onTap: () async {
                  try {
                    if (widget.chat.id == null) {
                      myLogger.w('GoRouterState.of(context).path: ${GoRouterState.of(context).path}');
                      final ChatModel chat = await ref.read(chatsNotifierProvider.notifier).createChatMessage(message: inputMessage, participantId: widget.chat.participant.id);
                      myLogger.w('1 chat.id: ${chat.id}, chat.participant.name: ${chat.participant.name}, chat.lastMessage: ${chat.lastMessage}');
                      widget.notifier.updateField(chat: chat);
                      await ref.read(chatMessagesProvider(chat.id!).notifier).addMessage(message: chat.lastMessage!);
                    } else {
                      ref
                          .read(chatsWSNotifierProvider.notifier)
                          .sendMessage(chatId: widget.chat.id!, userId: widget.userId, participantId: widget.chat.participant.id, message: inputMessage);
                    }

                    messageController.clear();
                    ref.read(inputMessageProvider.notifier).state = '';
                  } catch (error) {
                    myLogger.e('Exception while creating chat, e: ${error.toString()}');
                  }
                },
                child: Icon(Icons.send_rounded, size: 26.dp),
              )
            else ...[
              Icon(Icons.attach_file_rounded, size: 26.dp),
              Icon(Icons.mic_rounded, size: 26.dp),
            ],
          ],
        ),
      ),
    );
  }
}

class ChatAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final ChatModel chat;

  const ChatAppBar({required this.chat, super.key});

  @override
  Size get preferredSize => Size(double.infinity, 56.5.dp);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
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
                        chat.participant.isOnline ? 'Online' : 'Offline',
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
                onTap: () => showChatsScreenSettingsDialog(context),
                child: Icon(Icons.more_vert_rounded, color: theme.primaryText, size: 28.dp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InitialMessageWidget extends ConsumerWidget {
  const InitialMessageWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Text(
        'Send Message 💬',
        style: GoogleFonts.quicksand(fontSize: 24.dp, fontWeight: FontWeight.w600),
      ),
    );
  }
}
