import 'package:dio/dio.dart';
import 'package:kronk/models/vocabulary_model.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/interceptors.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:tuple/tuple.dart';

BaseOptions getVocabularyBaseOptions() {
  return BaseOptions(baseUrl: '${constants.apiEndpoint}/vocabularies', contentType: 'application/json', validateStatus: (int? status) => true);
}

class VocabularyService {
  final Dio _dio;

  VocabularyService() : _dio = Dio(getVocabularyBaseOptions())..interceptors.add(AccessTokenInterceptor());

  Future<bool> createVocabularies({required FormData formData}) async {
    try {
      Response response = await _dio.post('/create', data: formData);
      myLogger.i('🚀 response.data in createVocabularies: ${response.data}  statusCode: ${response.statusCode}');
      return response.data['ok'] ?? false;
    } catch (error) {
      myLogger.w('catch in createVocabularies: ${error.toString()}');
      rethrow;
    }
  }

  Future<bool> deleteVocabularies({required List<String> vocabularyIds}) async {
    try {
      Response response = await _dio.post('/delete', queryParameters: {'vocabulary_ids': vocabularyIds});
      myLogger.i('🚀 response.data in deleteVocabulary: ${response.data}  statusCode: ${response.statusCode}');
      return response.statusCode == 204;
    } catch (error) {
      myLogger.w('catch in deleteVocabulary: ${error.toString()}');
      rethrow;
    }
  }

  Future<Tuple2<List<VocabularyModel>, int>> getVocabularies({int offset = 0, int limit = 20}) async {
    try {
      Response response = await _dio.get('', queryParameters: {'offset': offset, 'limit': limit});
      final data = response.data['vocabularies'] as List;
      final total = response.data['total'] as int;

      final vocabularies = data.map((json) => VocabularyModel.fromJson(json)).toList();
      return Tuple2(vocabularies, total);
    } catch (error) {
      myLogger.w('catch in VocabularyModel: ${error.toString()}');
      rethrow;
    }
  }

  Future<Tuple2<List<SentenceModel>, int>> getSentences({int offset = 0, int limit = 20}) async {
    try {
      Response response = await _dio.get('/sentences', queryParameters: {'offset': offset, 'limit': limit});
      myLogger.i('🚀 response.data in getSentences: ${response.data}  statusCode: ${response.statusCode}');
      final data = response.data['sentences'] as List;
      final total = response.data['total'] as int;
      final sentences = data.map((json) => SentenceModel.fromJson(json)).toList();
      return Tuple2(sentences, total);
    } catch (error) {
      myLogger.w('catch in getSentences: ${error.toString()}');
      rethrow;
    }
  }

  Future<bool> deleteSentences({required List<String> sentenceIds}) async {
    try {
      Response response = await _dio.post('/sentences/delete', queryParameters: {'sentence_ids': sentenceIds});
      myLogger.i('🚀 response.data in deleteSentence: ${response.data}  statusCode: ${response.statusCode}');
      return response.statusCode == 204;
    } catch (error) {
      myLogger.w('catch in deleteSentence: ${error.toString()}');
      rethrow;
    }
  }
}
