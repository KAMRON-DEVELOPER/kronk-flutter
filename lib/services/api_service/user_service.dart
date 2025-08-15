import 'package:dio/dio.dart';
import 'package:kronk/models/user_model.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/interceptors.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/storage.dart';
import 'package:tuple/tuple.dart';

BaseOptions getUsersBaseOptions() {
  return BaseOptions(baseUrl: '${constants.apiEndpoint}/users', contentType: 'application/json', validateStatus: (int? status) => true);
}

class UserService {
  final Dio _dio;
  final Storage _storage;

  UserService() : _dio = Dio(getUsersBaseOptions()), _storage = Storage();

  Future<Response> fetchRegister({required Map<String, String> data}) async {
    try {
      Response response = await _dio.post('/auth/register', data: data);
      myLogger.i('🚀 response.data in fetchRegister: ${response.data}  statusCode: ${response.statusCode}');
      return response;
    } catch (error) {
      myLogger.w('🌋 catch in fetchRegister: ${error.toString()}');
      rethrow;
    }
  }

  Future<Response> fetchVerify({required String code}) async {
    try {
      Tuple2<String?, bool> verifyTokenStatus = await _storage.getVerifyTokenAsync();
      final bool isExpiredVerifyToken = verifyTokenStatus.item2;
      final String? verifyToken = verifyTokenStatus.item1;

      if (verifyToken == null) {
        throw Exception('Verify token not found.');
      } else if (isExpiredVerifyToken) {
        throw Exception('Your verify token is expired.');
      }

      _dio.interceptors.add(VerifyTokenInterceptor(verifyToken: verifyToken));
      Response response = await _dio.post('/auth/verify', data: {'code': code});
      myLogger.i('🚀 response.data in fetchVerify: ${response.data}  statusCode: ${response.statusCode}');
      return response;
    } catch (error) {
      myLogger.w('🌋 catch in fetchVerify: ${error.toString()}');
      rethrow;
    }
  }

  Future<Response> fetchLogin({required Map<String, dynamic> data}) async {
    try {
      Response response = await _dio.post('/auth/login', data: data);
      myLogger.i('🚀 response.data in fetchLogin: ${response.data}  statusCode: ${response.statusCode}');
      return response;
    } catch (error) {
      myLogger.w('🌋 catch in fetchLogin: ${error.toString()}');
      rethrow;
    }
  }

  Future<void> fetchLogout() async {
    try {
      _dio.interceptors.add(AccessTokenInterceptor());
      Response response = await _dio.post('/auth/logout');
      myLogger.d('response.statusCode: ${response.statusCode}');
      myLogger.d('response.data: ${response.data}, data.runtimeType: ${response.data.runtimeType}');
    } catch (e) {
      myLogger.f('Something happened in fetchLogout...');
    }
  }

  Future<Response> fetchRequestForgotPassword({required String email}) async {
    try {
      Response response = await _dio.post('/auth/request-forgot-password', data: {'email': email});
      myLogger.i('🚀 response.data in fetchRequestForgotPassword: ${response.data}  statusCode: ${response.statusCode}');
      return response;
    } catch (error) {
      myLogger.w('🌋 catch in fetchRequestForgotPassword: ${error.toString()}');
      rethrow;
    }
  }

  Future<Response> fetchForgotPassword({required Map<String, String> data}) async {
    try {
      Tuple2<String?, bool> token = await _storage.forgotPasswordTokenAsync();
      final bool isExpiredResetPasswordToken = token.item2;
      final String? forgotPasswordToken = token.item1;

      if (forgotPasswordToken == null) {
        throw Exception('Reset password token is not found.');
      } else if (isExpiredResetPasswordToken) {
        throw Exception('Your reset password token is expired.');
      }

      _dio.interceptors.add(ForgotPasswordTokenInterceptor(forgotPasswordToken: forgotPasswordToken));
      Response response = await _dio.post('/auth/forgot-password', data: data);
      myLogger.i('🚀 response.data in fetchResetPassword: ${response.data}  statusCode: ${response.statusCode}');
      return response;
    } catch (error) {
      myLogger.w('🌋 catch in fetchResetPassword: ${error.toString()}');
      rethrow;
    }
  }

  Future<Response> fetchSocialAuth({String? idToken, String? authorizationCode, String? email, String? name}) async {
    try {
      Map<String, dynamic> queryParameters = {'id_token': idToken};
      if (authorizationCode != null) queryParameters['authorization_code'] = authorizationCode;
      if (authorizationCode != null) queryParameters['email'] = email;
      if (authorizationCode != null) queryParameters['name'] = name;
      Response response = await _dio.post('/auth/social', queryParameters: queryParameters);
      myLogger.i('🚀 response.data in fetchSocialAuth: ${response.data}  statusCode: ${response.statusCode}');
      return response;
    } catch (error) {
      myLogger.w('🥶 Error in fetchSocialAuth: ${error.toString()}');
      rethrow;
    }
  }

  Future<UserModel> fetchGetProfile({String? targetUserId}) async {
    try {
      _dio.interceptors.add(AccessTokenInterceptor());
      final queryParameters = {if (targetUserId != null) 'target_user_id': targetUserId};
      final Response response = await _dio.get('/profile', queryParameters: queryParameters);
      return UserModel.fromJson(response.data);
    } catch (error) {
      myLogger.w('catch in fetchUserProfile: ${error.toString()}');
      rethrow;
    }
  }

  Future<bool> fetchUpdateProfile({required Map<String, dynamic> data}) async {
    try {
      Response response = await _dio.patch('/profile/update', data: data);
      myLogger.i('🚀 response.data in fetchUpdateProfile: ${response.data}  statusCode: ${response.statusCode}');
      return response.data['ok'];
    } catch (e) {
      myLogger.w('error in fetchUserProfile: ${e.toString()}');
      rethrow;
    }
  }

  Future<Tuple2<String?, String?>> fetchUpdateProfileImage({required FormData formData}) async {
    try {
      Response response = await _dio.patch('/profile/update/media', data: formData);
      myLogger.i('🚀 response.data in fetchUpdateProfileMedia: ${response.data}  statusCode: ${response.statusCode}');
      return Tuple2(response.data['avatar_url'], response.data['banner_url']);
    } catch (e) {
      myLogger.w('error in fetchUpdateProfileMedia: ${e.toString()}');
      rethrow;
    }
  }

  Future<bool> fetchDeleteProfile() async {
    try {
      _dio.interceptors.add(AccessTokenInterceptor());
      Response response = await _dio.delete('/profile/delete');
      return response.data['ok'] ?? false;
    } catch (e) {
      myLogger.w('error in fetchUserProfile: ${e.toString()}');
      rethrow;
    }
  }

  Future<Response?> fetchAccessTokens({required String refreshToken}) async {
    try {
      Response response = await _dio.post('/auth/access', options: Options(headers: {'Authorization': 'Bearer $refreshToken'}));
      return response;
    } catch (error) {
      myLogger.w('🌋 catch in fetchAccessTokens: ${error.toString()}');
      return null;
    }
  }

  Future<Response?> fetchRefreshTokens({required String refreshToken}) async {
    try {
      Response response = await _dio.post('/auth/refresh', options: Options(headers: {'Authorization': 'Bearer $refreshToken'}));
      return response;
    } catch (error) {
      myLogger.w('🌋 catch in fetchRefreshTokens: ${error.toString()}');
      return null;
    }
  }

  Future<Tuple2<List<UserModel>, int>> fetchUserSearch({required String query, int start = 0, int end = 9}) async {
    try {
      _dio.interceptors.add(AccessTokenInterceptor());
      Response response = await _dio.get('/search', queryParameters: {'query': query, 'offset': start, 'limit': (end + 1) - start});
      final data = response.data;
      if (data['users'] is List) {
        return Tuple2((data['users'] as List).map<UserModel>((json) => UserModel.fromJson(json as Map<String, dynamic>)).toList(), data['end'] ?? 0);
      } else {
        return const Tuple2([], 0);
      }
    } catch (error) {
      myLogger.e('Error in fetchUserSearch: $error');
      rethrow;
    }
  }

  Future<bool> fetchFollow({required String? followingId}) async {
    try {
      _dio.interceptors.add(AccessTokenInterceptor());
      Response response = await _dio.post('/follow', queryParameters: {'following_id': followingId});
      myLogger.i('🚀 response.data in fetchFollow: ${response.data}  statusCode: ${response.statusCode}');
      return response.data['ok'] ?? false;
    } catch (error) {
      myLogger.e('Error in fetchFollow: $error');
      rethrow;
    }
  }

  Future<bool> fetchUnfollow({required String? followingId}) async {
    try {
      _dio.interceptors.add(AccessTokenInterceptor());
      Response response = await _dio.post('/unfollow', queryParameters: {'following_id': followingId});
      myLogger.i('🚀 response.data in fetchUnfollow: ${response.data}  statusCode: ${response.statusCode}');
      return response.data['ok'] ?? false;
    } catch (error) {
      myLogger.e('Error in fetchUnfollow: $error');
      rethrow;
    }
  }

  Future<Map<String, bool>> blockUserStatus({required String? blockedId}) async {
    try {
      _dio.interceptors.add(AccessTokenInterceptor());
      Response response = await _dio.get('/block-user-status', queryParameters: {'blocked_id': blockedId});
      myLogger.i('🚀 response.data in blockUserStatus: ${response.data}  statusCode: ${response.statusCode}');
      return Map<String, bool>.from(response.data);
    } catch (error) {
      myLogger.e('Error in blockUserStatus in user service: $error');
      rethrow;
    }
  }

  Future<bool> toggleBlockUser({required String? blockedId, bool symmetrical = false}) async {
    try {
      _dio.interceptors.add(AccessTokenInterceptor());
      Response response = await _dio.post('/toggle-block-user', queryParameters: {'blocked_id': blockedId, 'symmetrical': symmetrical});
      myLogger.i('🚀 response.data in toggleBlockUser: ${response.data}  statusCode: ${response.statusCode}');
      return response.data['ok'] as bool;
    } catch (error) {
      myLogger.e('Error in toggleBlockUser: $error');
      rethrow;
    }
  }
}
