import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/models/chat_model.dart';
import 'package:kronk/utility/my_logger.dart';

final chatTileStateProvider = AutoDisposeNotifierProviderFamily<ChatTileStateNotifier, ChatModel, ChatModel>(() => ChatTileStateNotifier());

class ChatTileStateNotifier extends AutoDisposeFamilyNotifier<ChatModel, ChatModel> {
  @override
  ChatModel build(ChatModel initialChat) {
    ref.onDispose(() {
      myLogger.t('onDispose is working...');
    });

    ref.onCancel(() {
      myLogger.t('onCancel is working...');
    });

    return initialChat;
  }

  void updateField({required ChatModel chat}) {
    state = chat;
  }
}
