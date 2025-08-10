import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/chat_message_model.dart';
import 'package:kronk/models/chat_model.dart';
import 'package:kronk/riverpod/chat/chat_messages_provider.dart';
import 'package:kronk/screens/chat/chat_screen.dart';
import 'package:kronk/services/api_service/chat_service.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/storage.dart';

final chatsProvider = AsyncNotifierProvider<ChatsNotifier, List<ChatModel>>(ChatsNotifier.new);

class ChatsNotifier extends AsyncNotifier<List<ChatModel>> {
  late ChatService _chatService;
  late Connectivity _connectivity;
  late Storage _storage;
  int _start = 0;
  int _end = 10;

  @override
  Future<List<ChatModel>> build() async {
    _chatService = ChatService();
    _connectivity = Connectivity();
    _storage = Storage();

    ref.onDispose(() => myLogger.f('onDispose chatsNotifierProvider'));

    try {
      final bool isOnlineAndAuthenticated = await _isOnlineAndAuthenticated();
      if (!isOnlineAndAuthenticated) return [];
      return await _getChats();
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
      return [];
    }
  }

  Future<List<ChatModel>> _getChats() async {
    try {
      final List<ChatModel> chats = await _chatService.getChats();
      return chats;
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
      return [];
    }
  }

  Future<List<ChatModel>> refresh() async {
    state = const AsyncValue.loading();
    final Future<List<ChatModel>> chats = _getChats();
    state = await AsyncValue.guard(() => chats);
    return chats;
  }

  Future<bool> _isOnlineAndAuthenticated() async {
    final connectivity = await _connectivity.checkConnectivity();
    final isOnline = connectivity.any((ConnectivityResult result) => result != ConnectivityResult.none);

    final accessToken = await _storage.getAccessTokenAsync();
    final bool isAuthenticated = accessToken != null ? true : false;

    return isOnline && isAuthenticated;
  }

  Future<void> loadMore() async {
    _start = _end + 1;
    _end = _start + 10;

    final newFeeds = await _chatService.getChats(start: _start, end: _end);

    state = state.whenData((existing) => [...existing, ...newFeeds]);
  }

  Future<ChatModel> createChat({required String message, required String participantId}) async {
    try {
      final ChatModel chat = await _chatService.createChatMessage(message: message, participantId: participantId);
      state = state.whenData((List<ChatModel> values) => [...values, chat]);
      return chat;
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
      rethrow;
    }
  }

  Future<void> handleWebsocketEvents({required Map<String, dynamic> data}) async {
    myLogger.w('data: $data type: ${data.runtimeType}');
    final sharedChatId = ref.read(sharedChatProvider.notifier).state?.id;

    final String chatId = data['id'] ?? '';
    final String? type = data['type'];

    final ChatEvent event = ChatEvent.values.firstWhere((chatEvent) => chatEvent.name.toSnakeCase() == type, orElse: () => ChatEvent.wrongType);

    switch (event) {
      case ChatEvent.goesOnline:
        state = state.whenData(
          (chats) => chats.map((chat) {
            if (chat.id == chatId) {
              if (chat.id == sharedChatId) {
                ref.read(sharedChatProvider.notifier).state = chat.copyWith(participant: chat.participant.copyWith(isOnline: true));
              }
              return chat.copyWith(participant: chat.participant.copyWith(isOnline: true));
            }
            return chat;
          }).toList(),
        );
        break;
      case ChatEvent.goesOffline:
        final sharedChatId = ref.read(sharedChatProvider.notifier).state?.id;
        state = state.whenData(
          (chats) => chats.map((chat) {
            if (chat.id == chatId) {
              if (chat.id == sharedChatId) {
                ref.read(sharedChatProvider.notifier).state = chat.copyWith(participant: chat.participant.copyWith(isOnline: false));
              }
              return chat.copyWith(participant: chat.participant.copyWith(isOnline: false));
            }
            return chat;
          }).toList(),
        );
        break;
      case ChatEvent.typingStart:
        state = state.whenData(
          (chats) => chats.map((chat) {
            if (chat.id == chatId) {
              if (chat.id == sharedChatId) {
                ref.read(sharedChatProvider.notifier).state = chat.copyWith(participant: chat.participant.copyWith(isTyping: true));
              }
              return chat.copyWith(participant: chat.participant.copyWith(isTyping: true));
            }
            return chat;
          }).toList(),
        );
        break;
      case ChatEvent.typingStop:
        state = state.whenData(
          (chats) => chats.map((chat) {
            if (chat.id == chatId) {
              if (chat.id == sharedChatId) {
                ref.read(sharedChatProvider.notifier).state = chat.copyWith(participant: chat.participant.copyWith(isTyping: false));
              }
              return chat.copyWith(participant: chat.participant.copyWith(isTyping: false));
            }
            return chat;
          }).toList(),
        );
        break;
      case ChatEvent.sentMessage:
        final lastMessageMap = Map<String, dynamic>.from(data['last_message'] ?? {});
        final ChatMessageModel lastMessage = ChatMessageModel.fromJson(lastMessageMap);

        ref.read(chatMessagesStateProvider(chatId).notifier).addMessage(lastMessage: lastMessage);
        state = state.whenData(
          (chats) => chats.map((chat) {
            if (chat.id == chatId) return chat.copyWith(lastMessage: lastMessage, lastActivityAt: DateTime.fromMillisecondsSinceEpoch((data['last_activity_at'] as int) * 1000));
            return chat;
          }).toList(),
        );
        break;
      case ChatEvent.createdChat:
        final ChatModel newChat = ChatModel.fromJson(data);
        state = state.whenData((chats) {
          final alreadyExists = chats.any((chat) => chat.id == newChat.id);
          if (alreadyExists) return chats;

          return [newChat, ...chats];
        });
        break;
      case ChatEvent.heartbeatAck:
        break;
      case ChatEvent.heartbeat:
        break;
      case ChatEvent.wrongType:
        break;
    }
  }
}
