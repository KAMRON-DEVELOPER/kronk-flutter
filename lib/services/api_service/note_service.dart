import 'package:dio/dio.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/note_model.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/interceptors.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:tuple/tuple.dart';

BaseOptions getNoteBaseOptions() {
  return BaseOptions(baseUrl: '${constants.apiEndpoint}/notes', contentType: 'application/json', validateStatus: (int? status) => true);
}

class NoteService {
  final Dio _dio;

  NoteService() : _dio = Dio(getNoteBaseOptions())..interceptors.add(AccessTokenInterceptor());

  Future<bool> createNote({required FormData formData}) async {
    try {
      Response response = await _dio.post('/create', data: formData);
      myLogger.i('🚀 response.data in createNote: ${response.data}  statusCode: ${response.statusCode}');
      return response.data['ok'] ?? false;
    } catch (error) {
      myLogger.w('catch in createNote: ${error.toString()}');
      rethrow;
    }
  }

  Future<bool> deleteNotes({required List<String> noteIds}) async {
    try {
      Response response = await _dio.post('/delete', data: noteIds);
      myLogger.i('🚀 response.data in deleteNotes: ${response.data}  statusCode: ${response.statusCode}');
      return response.statusCode == 204;
    } catch (error) {
      myLogger.w('catch in deleteNotes: ${error.toString()}');
      rethrow;
    }
  }

  Future<Tuple2<List<NoteModel>, int>> getNotes({required NoteScope noteScope, int offset = 0, int limit = 20}) async {
    try {
      Response response = await _dio.get('', queryParameters: {'note_scope': noteScope.name, 'offset': offset, 'limit': limit});
      final data = response.data['notes'] as List;
      final total = response.data['total'] as int;

      final vocabularies = data.map((json) => NoteModel.fromJson(json)).toList();
      return Tuple2(vocabularies, total);
    } catch (error) {
      myLogger.w('catch in getNotes: ${error.toString()}');
      rethrow;
    }
  }
}
