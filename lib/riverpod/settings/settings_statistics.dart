import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/models/statistics_model.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final settingsStatisticsWsStreamProvider = StreamProvider.autoDispose<StatisticsModel>((ref) async* {
  final channel = IOWebSocketChannel.connect('${constants.websocketEndpoint}/admin/statistics');

  try {
    await channel.ready;
  } on SocketException catch (e) {
    throw Exception('🌋 WebSocket SocketException error: $e');
  } on WebSocketChannelException catch (e) {
    throw Exception('🌋 WebSocket WebSocketChannelException error: $e');
  }

  ref.onDispose(() => channel.sink.close());

  try {
    await for (final event in channel.stream) {
      myLogger.i('settingsStatisticsWsStreamProvider; event: $event, type: ${event.runtimeType}');
      final decoded = jsonDecode(event as String);
      final map = Map<String, dynamic>.from(decoded);
      yield StatisticsModel(
        weekly: Map<String, int>.from(map['weekly'] ?? []),
        monthly: Map<String, int>.from(map['monthly'] ?? {}),
        yearly: Map<String, int>.from(map['yearly'] ?? {}),
        total: map['total'] ?? 0,
      );
    }
  } catch (e) {
    throw Exception('🌋 WebSocket stream error: $e');
  }
});
