import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/exceptions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/storage.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final feedsScreenScrollPositionProvider = StateProvider.autoDispose<double>((ref) => 0.0);

final feedNotificationNotifierProvider = AutoDisposeAsyncNotifierProvider<FeedNotificationNotifierNotifier, List<String>>(FeedNotificationNotifierNotifier.new);

class FeedNotificationNotifierNotifier extends AutoDisposeAsyncNotifier<List<String>> {
  Timer? _reconnectTimer;
  IOWebSocketChannel? _channel;
  final Duration _reconnectDelay = const Duration(seconds: 2);
  final Storage _storage = Storage();
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;

  @override
  Future<List<String>> build() async {
    ref.onDispose(() {
      myLogger.f('onDispose in feedNotificationNotifierProvider');
      _channel?.sink.close();
      _reconnectTimer?.cancel();
    });

    _listenWebSocket();

    return [];
  }

  Future<void> _listenWebSocket() async {
    try {
      final accessToken = await _storage.getAccessTokenAsync();
      if (accessToken == null) throw NoValidTokenException('No valid access token');

      final url = '${constants.websocketEndpoint}/feeds/timeline';
      _channel = IOWebSocketChannel.connect(Uri.parse(url), headers: {'Authorization': 'Bearer $accessToken'});

      // Listen for messages
      _channel?.stream.listen(
        (event) {
          try {
            myLogger.w('event: $event, type: ${event.runtimeType}');
            final decoded = jsonDecode(event as String);
            final avatarUrl = decoded['avatar_url'] as String?;
            if (avatarUrl != null) {
              final currentList = state.valueOrNull ?? [];
              state = AsyncData([avatarUrl, ...currentList].take(3).toList());
            }
          } catch (e) {
            // Handle message decoding errors
          }
        },
        onError: (error) => _handleWebSocketError(error),
        onDone: () => _scheduleReconnect(),
      );
    } catch (e) {
      _handleWebSocketError(e);
    }
  }

  void _handleWebSocketError(dynamic error) {
    myLogger.e('onError: (error) => _handleWebSocketError(error): $error');
    if (error is WebSocketChannelException) {
      if (error.message!.contains('403')) {
        state = AsyncError(NoValidTokenException('Token expired'), StackTrace.current);
        return;
      }
    }

    // Exponential backoff for reconnections
    final delay = Duration(seconds: _reconnectDelay.inSeconds * (_reconnectAttempts + 1));
    _reconnectTimer = Timer(delay, () {
      if (_reconnectAttempts < _maxReconnectAttempts) {
        _reconnectAttempts++;
        _listenWebSocket();
      }
    });
  }

  void _scheduleReconnect() {
    myLogger.d('onDone: () => _scheduleReconnect()');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      if (_reconnectAttempts < _maxReconnectAttempts) {
        _reconnectAttempts++;
        _listenWebSocket();
      }
    });
  }

  void clearNotifications() {
    state = const AsyncData([]);
  }
}
