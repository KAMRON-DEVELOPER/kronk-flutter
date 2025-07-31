import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/models/chat_model.dart';
import 'package:kronk/utility/my_logger.dart';

final chatStateProvider = AutoDisposeNotifierProviderFamily<ChatStateStateNotifier, ChatModel, ChatModel>(ChatStateStateNotifier.new);

class ChatStateStateNotifier extends AutoDisposeFamilyNotifier<ChatModel, ChatModel> {
  @override
  ChatModel build(ChatModel initialChat) {
    ref.onDispose(() {
      myLogger.t('onDispose in chatStateProvider');
    });

    return initialChat;
  }

  void updateField({required ChatModel chat}) {
    myLogger.d('chat.id: ${chat.id}');
    myLogger.d('chat.participant.name: ${chat.participant.name}');
    myLogger.d('chat.lastMessage: ${chat.lastMessage}');
    myLogger.d('chat.lastActivityAt: ${chat.lastActivityAt}');
    state = chat;
  }
}
