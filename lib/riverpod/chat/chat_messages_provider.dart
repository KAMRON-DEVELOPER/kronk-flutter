import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/models/chat_message_model.dart';
import 'package:kronk/services/api_service/chat_service.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/storage.dart';

final chatMessagesProvider = AutoDisposeAsyncNotifierProviderFamily<ChatMessagesNotifier, List<ChatMessageModel>, String>(ChatMessagesNotifier.new);

class ChatMessagesNotifier extends AutoDisposeFamilyAsyncNotifier<List<ChatMessageModel>, String> {
  late ChatService _chatService;
  late Connectivity _connectivity;
  late Storage _storage;
  int _start = 0;
  int _end = 20;

  @override
  Future<List<ChatMessageModel>> build(String chatId) async {
    _chatService = ChatService();
    _connectivity = Connectivity();
    _storage = Storage();

    ref.onDispose(() => myLogger.f('onDispose chatMessagesProvider'));

    try {
      final bool isOnlineAndAuthenticated = await _isOnlineAndAuthenticated();
      if (!isOnlineAndAuthenticated) return [];
      return await _getMessages(chatId: chatId);
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
      return [];
    }
  }

  Future<List<ChatMessageModel>> _getMessages({required String chatId}) async {
    try {
      final List<ChatMessageModel> messages = await _chatService.getMessages(chatId: chatId);
      return messages;
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
      rethrow;
    }
  }

  Future<void> addMessage({required ChatMessageModel message}) async {
    state = state.whenData((List<ChatMessageModel> messages) => [...messages, message]);
  }

  Future<List<ChatMessageModel>> refresh({required String chatId}) async {
    state = const AsyncValue.loading();
    final Future<List<ChatMessageModel>> chats = _getMessages(chatId: chatId);
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

  Future<void> loadMore({required String chatId}) async {
    _start = _end + 1;
    _end = _start + 20;

    final newMessages = await _chatService.getMessages(chatId: chatId, start: _start, end: _end);

    state = state.whenData((existing) => [...existing, ...newMessages]);
  }
}
