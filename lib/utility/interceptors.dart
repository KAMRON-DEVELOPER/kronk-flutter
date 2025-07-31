import 'package:dio/dio.dart';
import 'package:kronk/utility/storage.dart';

class VerifyTokenInterceptor extends Interceptor {
  final String verifyToken;

  const VerifyTokenInterceptor({required this.verifyToken});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    options.headers.addAll({'verify-token': verifyToken});
    handler.next(options);
  }
}

class ForgotPasswordTokenInterceptor extends Interceptor {
  final String forgotPasswordToken;

  const ForgotPasswordTokenInterceptor({required this.forgotPasswordToken});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    options.headers.addAll({'forgot-password-token': forgotPasswordToken});
    handler.next(options);
  }
}

class FirebaseIdTokenInterceptor extends Interceptor {
  final String? firebaseIdToken;

  FirebaseIdTokenInterceptor({required this.firebaseIdToken});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    options.headers.addAll({'firebase-id-token': firebaseIdToken});
    handler.next(options);
  }
}

class AccessTokenInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final Storage storage = Storage();
    String? accessToken = await storage.getAccessTokenAsync();

    if (accessToken == null) {
      handler.reject(DioException(requestOptions: options, message: 'You are not authenticated! 🥶', type: DioExceptionType.cancel), true);
      return;
    }

    options.headers.addAll({'Authorization': 'Bearer $accessToken'});
    handler.next(options);
  }
}
