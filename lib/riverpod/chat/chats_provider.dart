import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/chat_message_model.dart';
import 'package:kronk/models/chat_model.dart';
import 'package:kronk/riverpod/chat/chat_messages_provider.dart';
import 'package:kronk/services/api_service/chat_service.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/storage.dart';

final chatsNotifierProvider = AsyncNotifierProvider<ChatsNotifier, List<ChatModel>>(ChatsNotifier.new);

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

  Future<ChatModel> createChatMessage({required String message, required String participantId}) async {
    try {
      final ChatModel chat = await _chatService.createChatMessage(message: message, participantId: participantId);
      state = state.whenData((List<ChatModel> values) => [...values, chat]);
      return chat;
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
      rethrow;
    }
  }

  Future<void> handleEvents({required Map<String, dynamic> data}) async {
    myLogger.w('data: $data type: ${data.runtimeType}');
    final String? type = data['type'];
    final ChatEvent event = ChatEvent.values.firstWhere((chatEvent) => chatEvent.name.toSnakeCase() == type, orElse: () => ChatEvent.wrongType);
    final String chatId = data['id'] ?? '';

    /*
    {
    "id": "51c3cb5c551148cdaab3023219f56481",
    "participant": {
      "id": "4884809a41e14a83a66882e0b0938ce5",
      "name": "Kamronbek Atajanov",
      "username": "kamronbek",
      "avatar_url": null,
      "last_seen_at": 1753288270,
      "is_online": true
    },
    "last_message": {
      "id": "d351ba6e07804dd6825f5bf90b7a856a",
      "sender_id": "96f90d7fda694128b27d0a0792600eae",
      "chat_id": "51c3cb5c551148cdaab3023219f56481",
      "message": "Hi brother.",
      "created_at": 1753288562
    },
    "last_activity_at": 1753288562
  }
  */

    switch (event) {
      case ChatEvent.typingStart:
        myLogger.w('ChatEvent.typingStart: data: $data');
        state = state.whenData(
          (chats) => chats.map((chat) {
            if (chat.id == chatId) {
              return chat.copyWith();
            }
            return chat;
          }).toList(),
        );
        break;
      case ChatEvent.typingStop:
        myLogger.w('ChatEvent.typingStop: data: $data');
        state = state.whenData(
          (chats) => chats.map((chat) {
            if (chat.id == chatId) {
              return chat.copyWith();
            }
            return chat;
          }).toList(),
        );
        break;
      case ChatEvent.goesOnline:
        myLogger.w('ChatEvent.goesOnline: data: $data');
        state = state.whenData((chats) {
          return chats.map((chat) {
            myLogger.d("is user found to modify? ${chat.participant.id == data['participant']['id']}");
            if (chat.participant.id == data['participant']['id']) {
              return chat.copyWith(participant: chat.participant.copyWith(isOnline: true, lastSeenAt: DateTime.now()));
            }
            return chat;
          }).toList();
        });
        break;

      case ChatEvent.goesOffline:
        myLogger.w('ChatEvent.goesOffline: data: $data');
        state = state.whenData((chats) {
          return chats.map((chat) {
            myLogger.d("is user found to modify? ${chat.participant.id == data['participant']['id']}");
            if (chat.participant.id == data['participant']['id']) {
              return chat.copyWith(participant: chat.participant.copyWith(isOnline: false, lastSeenAt: DateTime.now()));
            }
            return chat;
          }).toList();
        });
        break;
      case ChatEvent.enterChat:
        myLogger.w('ChatEvent.enterChat: data: $data');
        state = state.whenData(
          (chats) => chats.map((chat) {
            if (chat.id == chatId) {
              return chat.copyWith();
            }
            return chat;
          }).toList(),
        );
        break;
      case ChatEvent.exitChat:
        myLogger.w('ChatEvent.exitChat: data: $data');
        state = state.whenData(
          (chats) => chats.map((chat) {
            if (chat.id == chatId) {
              return chat.copyWith();
            }
            return chat;
          }).toList(),
        );
        break;
      case ChatEvent.sentMessage:
        myLogger.w('ChatEvent.sentMessage: data: $data');

        /*
        {
          "id": "51c3cb5c551148cdaab3023219f56481",
          "participant": {
            "id": "4884809a41e14a83a66882e0b0938ce5",
            "name": "Kamronbek Atajanov",
            "username": "kamronbek",
            "avatar_url": null,
            "last_seen_at": 1753288270,
            "is_online": true
          },
          "last_message": {
            "id": "d351ba6e07804dd6825f5bf90b7a856a",
            "sender_id": "96f90d7fda694128b27d0a0792600eae",
            "chat_id": "51c3cb5c551148cdaab3023219f56481",
            "message": "Hi brother.",
            "created_at": 1753288562
          },
          "last_activity_at": 1753288562
        }
      */

        final messageJson = Map<String, dynamic>.from(data['last_message']);
        final chatIdMessageCameFrom = data['id'] as String;

        final ChatMessageModel message = ChatMessageModel.fromJson(messageJson);

        // Update chat list state
        state = state.whenData((chats) {
          return chats.map((chat) {
            if (chat.id == chatIdMessageCameFrom) {
              return chat.copyWith(lastMessage: message, lastActivityAt: DateTime.fromMillisecondsSinceEpoch((data['last_activity_at'] as int) * 1000));
            }
            return chat;
          }).toList();
        });

        // 👇 Add message to message list too
        final messageNotifier = ref.read(chatMessagesProvider(chatIdMessageCameFrom).notifier);
        await messageNotifier.addMessage(message: message);
        break;
      case ChatEvent.createdChat:
        myLogger.w('ChatEvent.createdChat: data: $data');
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
