import 'package:dio/dio.dart';
import 'package:kronk/models/chat_message_model.dart';
import 'package:kronk/models/chat_model.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/interceptors.dart';
import 'package:kronk/utility/my_logger.dart';

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

  Future<List<ChatModel>> getChats({int start = 0, int end = 20}) async {
    try {
      Response response = await _dio.get('');
      myLogger.i('🚀 response.data in getChats: ${response.data}  statusCode: ${response.statusCode}');
      final data = response.data['chats'] as List;
      return data.map((json) => ChatModel.fromJson(json)).toList();
    } catch (error) {
      myLogger.w('catch in getChats: ${error.toString()}');
      rethrow;
    }
  }

  Future<List<ChatMessageModel>> getMessages({required String chatId, int start = 0, int end = 20}) async {
    try {
      Response response = await _dio.get('/messages', queryParameters: {'chat_id': chatId});
      myLogger.i('🚀 response.data in getChats: ${response.data}  statusCode: ${response.statusCode}');
      final data = response.data['messages'];
      if (data is List) return data.map((json) => ChatMessageModel.fromJson(json)).toList();
      return [];
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
