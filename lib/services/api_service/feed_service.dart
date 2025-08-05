import 'package:dio/dio.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/feed_model.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/interceptors.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:tuple/tuple.dart';

BaseOptions getFeedBaseOptions() {
  return BaseOptions(baseUrl: '${constants.apiEndpoint}/feeds', contentType: 'application/json', validateStatus: (int? status) => true);
}

class FeedService {
  final Dio _dio;

  FeedService() : _dio = Dio(getFeedBaseOptions())..interceptors.add(AccessTokenInterceptor());

  Future<Tuple2<List<FeedModel>, int>> fetchTimeline({required TimelineType timelineType, int start = 0, int end = 9}) async {
    try {
      final path = switch (timelineType) {
        TimelineType.following => '/timeline/following',
        TimelineType.discover => '/timeline/discover',
      };

      final response = await _dio.get(path, queryParameters: {'start': start, 'end': end});

      final data = response.data;
      if (data['feeds'] is List) {
        return Tuple2((data['feeds'] as List).map<FeedModel>((json) => FeedModel.fromJson(json as Map<String, dynamic>)).toList(), data['end'] ?? 0);
      } else {
        return const Tuple2([], 0);
      }
    } catch (error) {
      myLogger.w('catch in fetchHomeTimeline: ${error.toString()}');
      rethrow;
    }
  }

  Future<Response> fetchCreateFeed({required FormData formData}) async {
    try {
      Response response = await _dio.post('/create', data: formData);
      myLogger.i('🚀 response.data in fetchCreateFeed: ${response.data}  statusCode: ${response.statusCode}');
      return response;
    } catch (error) {
      myLogger.w('🌋 catch in fetchCreateFeed: ${error.toString()}');
      rethrow;
    }
  }

  Future<Response> fetchUpdateFeed({required String? feedId, required FormData formData}) async {
    try {
      Response response = await _dio.patch('/update', data: formData, queryParameters: {'feed_id': feedId});
      myLogger.i('🚀 response.data in fetchUpdateFeed: ${response.data}  statusCode: ${response.statusCode}');
      return response;
    } catch (error) {
      myLogger.w('🌋 catch in fetchUpdateFeed: ${error.toString()}');
      rethrow;
    }
  }

  Future<bool> fetchDeleteFeed({required String? feedId}) async {
    try {
      Response response = await _dio.delete('/delete', queryParameters: {'feed_id': feedId});
      myLogger.i('🚀 response.data in fetchDeleteFeed: ${response.data}  statusCode: ${response.statusCode}');
      if (response.statusCode == 204) return true;
      throw Exception(response.data['details']);
    } catch (error) {
      myLogger.e('Error in fetchDeleteFeed: $error');
      rethrow;
    }
  }

  Future<Tuple2<List<FeedModel>, int>> fetchComments({required String? parentId, int start = 0, int end = 9}) async {
    try {
      final response = await _dio.get('/comments', queryParameters: {'feed_id': parentId, 'start': start, 'end': end});

      myLogger.i('🚀 response.data in fetchComments: ${response.data}  statusCode: ${response.statusCode}');
      final data = response.data;
      myLogger.d("data['feeds'] is List: ${data['feeds'] is List}");
      myLogger.d("data['end']: ${data['end']}");
      if (data['feeds'] is List) {
        return Tuple2((data['feeds'] as List).map<FeedModel>((json) => FeedModel.fromJson(json as Map<String, dynamic>)).toList(), data['end'] ?? end);
      } else {
        return const Tuple2([], 0);
      }
    } catch (error) {
      myLogger.w('catch in fetchComments: ${error.toString()}');
      rethrow;
    }
  }

  Future<Tuple2<List<FeedModel>, int>> fetchEngagementFeeds({required Tuple2<String?, EngagementType> key, int start = 0, int end = 9}) async {
    try {
      final Map<String, dynamic> queryParameters = {'engagement_type': key.item2.name.toSnakeCase(), 'start': start, 'end': end};
      if (key.item1 != null) queryParameters['user_id'] = key.item1;
      final response = await _dio.get('/timeline/user', queryParameters: queryParameters);

      final data = response.data;
      if (data['feeds'] is List) {
        return Tuple2((data['feeds'] as List).map<FeedModel>((json) => FeedModel.fromJson(json as Map<String, dynamic>)).toList(), data['end'] ?? end);
      } else {
        return const Tuple2([], 0);
      }
    } catch (error) {
      myLogger.w('catch in fetchEngagementFeeds: ${error.toString()}');
      rethrow;
    }
  }

  /// ************************************************* Engagement ************************************************* ///

  Future<EngagementModel> fetchSetEngagement({String? feedId, String? commentId, required EngagementType engagementType}) async {
    try {
      final queryParameters = {'engagement_type': engagementType.name, if (feedId != null) 'feed_id': feedId, if (commentId != null) 'comment_id': commentId};
      Response response = await _dio.post('/engagement/set', queryParameters: queryParameters);
      myLogger.i('🚀 response.data in fetchSetEngagementType: ${response.data}  statusCode: ${response.statusCode}');
      if (response.statusCode == 200) return EngagementModel.fromJson(response.data);
      throw Exception('Something happened while setting engagement');
    } catch (error) {
      myLogger.w('catch in fetchSetEngagementType: ${error.toString()}');
      throw Exception('catch in fetchSetEngagementType: ${error.toString()}');
    }
  }

  Future<EngagementModel> fetchRemoveEngagement({required String? feedId, String? commentId, required EngagementType engagementType}) async {
    try {
      final queryParameters = {'engagement_type': engagementType.name, if (feedId != null) 'feed_id': feedId, if (commentId != null) 'comment_id': commentId};
      Response response = await _dio.post('/engagement/remove', queryParameters: queryParameters);
      myLogger.i('🚀 response.data in fetchRemoveEngagementType: ${response.data}  statusCode: ${response.statusCode}');
      if (response.statusCode == 200) return EngagementModel.fromJson(response.data);
      throw Exception('Something happened while removing engagement');
    } catch (error) {
      myLogger.w('🌋 catch in fetchRemoveEngagementType: ${error.toString()}');
      throw Exception('catch in fetchRemoveEngagementType: ${error.toString()}');
    }
  }

  /// ************************************************* Feed Search ************************************************* ///

  Future<Tuple2<List<FeedModel>, int>> fetchFeedSearch({required String query, int start = 0, int end = 9}) async {
    try {
      Response response = await _dio.get('/search', queryParameters: {'query': query, 'offset': start, 'limit': (end + 1) - start});
      myLogger.i('🚀 response.data in fetchFeedSearch: ${response.data}  statusCode: ${response.statusCode}');
      final data = response.data;
      myLogger.d("data['feeds'] is List: ${data['feeds'] is List}");
      if (data['feeds'] is List) {
        if ((data['feeds'] as List).isEmpty) return const Tuple2([], 0);
        return Tuple2((data['feeds'] as List).map<FeedModel>((json) => FeedModel.fromJson(json as Map<String, dynamic>)).toList(), data['end'] ?? 0);
      } else {
        return const Tuple2([], 0);
      }
    } catch (error) {
      myLogger.e('Error in fetchFeedSearch: $error');
      rethrow;
    }
  }

  Future<Map<String, bool>> reportStatuses({required String? feedId}) async {
    try {
      Response response = await _dio.get('/report-statuses', queryParameters: {'feed_id': feedId});
      myLogger.i('🚀 response.data in reportStatuses: ${response.data}  statusCode: ${response.statusCode}');
      return Map<String, bool>.from(response.data as Map);
    } catch (error) {
      myLogger.e('Error in reportStatuses: $error');
      rethrow;
    }
  }

  Future<bool> toggleReport({required String? feedId, required ReportReason reportReason}) async {
    try {
      Response response = await _dio.get('/toggle-report', queryParameters: {'feed_id': feedId, 'report_reason': reportReason.name});
      myLogger.i('🚀 response.data in toggleReport: ${response.data}  statusCode: ${response.statusCode}');
      return response.data['ok'] as bool;
    } catch (error) {
      myLogger.e('Error in toggleReport: $error');
      rethrow;
    }
  }
}
