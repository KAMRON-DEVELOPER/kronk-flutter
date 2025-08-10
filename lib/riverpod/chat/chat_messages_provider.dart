import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/models/chat_message_model.dart';
import 'package:kronk/services/api_service/chat_service.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/storage.dart';

class ChatMessagesState {
  final List<ChatMessageModel> chatMessages;
  final int total;
  final bool hasMore;

  const ChatMessagesState({this.chatMessages = const [], this.total = 0, this.hasMore = true});

  ChatMessagesState copyWith({List<ChatMessageModel>? chatMessages, int? total, bool? hasMore}) {
    return ChatMessagesState(chatMessages: chatMessages ?? this.chatMessages, total: total ?? this.total, hasMore: hasMore ?? this.hasMore);
  }
}

final chatMessagesStateProvider = AutoDisposeAsyncNotifierProviderFamily<ChatMessagesNotifier, ChatMessagesState, String>(ChatMessagesNotifier.new);

class ChatMessagesNotifier extends AutoDisposeFamilyAsyncNotifier<ChatMessagesState, String> {
  late ChatService _chatService;
  late Connectivity _connectivity;
  late Storage _storage;
  int _offset = 0;
  final int _limit = 20;
  bool _isLoadingMore = false;

  @override
  Future<ChatMessagesState> build(String chatId) async {
    _chatService = ChatService();
    _connectivity = Connectivity();
    _storage = Storage();

    ref.onDispose(() => myLogger.f('onDispose chatMessagesProvider'));

    try {
      final bool isOnlineAndAuthenticated = await _isOnlineAndAuthenticated();
      if (!isOnlineAndAuthenticated) return const ChatMessagesState(hasMore: false);

      final response = await _chatService.getMessages(chatId: chatId, offset: 0, limit: _limit);
      _offset = response.item1.length;

      return ChatMessagesState(chatMessages: response.item1, total: response.item2, hasMore: response.item1.length < response.item2);
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
      return const ChatMessagesState(hasMore: false);
    }
  }

  Future<void> loadMore({required String chatId}) async {
    if (_isLoadingMore || !state.value!.hasMore) return;

    _isLoadingMore = true;

    final currentState = state.value!;
    final currentMessages = currentState.chatMessages;
    final offset = currentMessages.length;

    try {
      final response = await _chatService.getMessages(chatId: chatId, offset: offset, limit: _limit);
      final newMessages = response.item1;
      final total = response.item2;

      final combinedMessages = [...currentMessages, ...newMessages];

      state = AsyncValue.data(ChatMessagesState(chatMessages: combinedMessages, total: total, hasMore: combinedMessages.length < total));
    } catch (error, stackTrace) {
      myLogger.e('Error loading more messages: $error, stackTrace: $stackTrace');
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refresh({required String chatId}) async {
    _isLoadingMore = false;
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(seconds: 3));
    ref.invalidateSelf();
  }

  void addMessage({required ChatMessageModel lastMessage}) {
    state = state.whenData((value) => ChatMessagesState(chatMessages: [lastMessage, ...value.chatMessages]));
  }

  Future<bool> _isOnlineAndAuthenticated() async {
    final connectivity = await _connectivity.checkConnectivity();
    final isOnline = connectivity.any((ConnectivityResult result) => result != ConnectivityResult.none);

    final accessToken = await _storage.getAccessTokenAsync();
    final bool isAuthenticated = accessToken != null ? true : false;

    return isOnline && isAuthenticated;
  }
}
