import 'package:dio/dio.dart';
import 'package:kronk/models/chat_message_model.dart';
import 'package:kronk/models/chat_model.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/interceptors.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:tuple/tuple.dart';

BaseOptions getChatBaseOptions() {
  return BaseOptions(baseUrl: '${constants.apiEndpoint}/chats', contentType: 'application/json', validateStatus: (int? status) => true);
}

class ChatService {
  final Dio _dio;

  ChatService() : _dio = Dio(getChatBaseOptions())..interceptors.add(AccessTokenInterceptor());

  Future<ChatModel> createChatMessage({required String message, required String participantId}) async {
    try {
      Response response = await _dio.post('/messages/create', data: {'message': message}, queryParameters: {'participant_id': participantId});
      myLogger.i('🚀 response.data in createChatMessage: ${response.data}  statusCode: ${response.statusCode}');
      return ChatModel.fromJson(response.data);
    } catch (error) {
      myLogger.w('catch in getChats: ${error.toString()}');
      rethrow;
    }
  }

  Future<bool> deleteChat({required String chatId}) async {
    try {
      Response response = await _dio.post('/delete', queryParameters: {'chat_id': chatId});
      myLogger.i('🚀 response.data in deleteChat: ${response.data}  statusCode: ${response.statusCode}');
      return response.data['ok'] ?? false;
    } catch (error) {
      myLogger.w('catch in deleteChat: ${error.toString()}');
      rethrow;
    }
  }

  Future<List<ChatModel>> getChats({int start = 0, int end = 40}) async {
    try {
      Response response = await _dio.get('');
      final data = response.data['chats'] as List;
      return data.map((json) => ChatModel.fromJson(json)).toList();
    } catch (error) {
      myLogger.w('catch in getChats: ${error.toString()}');
      rethrow;
    }
  }

  Future<Tuple2<List<ChatMessageModel>, int>> getMessages({required String chatId, int offset = 0, int limit = 20}) async {
    try {
      Response response = await _dio.get('/messages', queryParameters: {'chat_id': chatId, 'offset': offset, 'limit': limit});
      final data = response.data['messages'] as List;
      final total = response.data['total'] as int;

      final chatMessages = data.map((json) => ChatMessageModel.fromJson(json)).toList();
      return Tuple2(chatMessages, total);
    } catch (error) {
      myLogger.w('catch in getChats: ${error.toString()}');
      rethrow;
    }
  }

  Future<bool> deleteMessage({required List<String> messageIds}) async {
    try {
      Response response = await _dio.post('/messages/delete', queryParameters: {'message_ids': messageIds});
      myLogger.i('🚀 response.data in deleteMessage: ${response.data}  statusCode: ${response.statusCode}');
      return response.data['ok'] ?? false;
    } catch (error) {
      myLogger.w('catch in deleteMessage: ${error.toString()}');
      rethrow;
    }
  }
}
