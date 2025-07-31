//import 'dart:developer';
//import 'package:dio/dio.dart';
//import 'package:firebase_auth/firebase_auth.dart';
//import 'package:flutter_bloc/flutter_bloc.dart';
//import 'package:google_sign_in/google_sign_in.dart';
//import 'package:kronk/models/user_model.dart';
//import 'package:logger/logger.dart';
//import '../../services/user_service.dart';
//import '../../utility/storage.dart';
//import 'authentication_event.dart';
//import 'authentication_state.dart';
//
//var logger = Logger(printer: PrettyPrinter(), level: Level.debug);
//
//class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
//  final UsersService _authApiService = UsersService();
//  final Storage _storage = Storage();
//
//  AuthenticationBloc() : super(AuthenticationInitial()) {
//    on<RegisterSubmitEvent>(_registerSubmitEvent);
//    on<VerifySubmitEvent>(_verifySubmitEvent);
//    on<LoginSubmitEvent>(_loginSubmitEvent);
//    on<RequestResetPasswordEvent>(_requestResetPasswordEvent);
//    on<ResetPasswordEvent>(_resetPasswordEvent);
//    on<SocialAuthEvent>(_socialAuthEvent);
//  }
//
//  Future<void> _registerSubmitEvent(RegisterSubmitEvent event, Emitter<AuthenticationState> emit) async {
//    emit(AuthenticationLoading());
//    await _handleApiResponse(
//      emit: emit,
//      apiCall: () async => await _authApiService.fetchRegister(registerData: event.registerData),
//      onSuccess: (Response<dynamic> response) async {
//        await _storage.setAsyncSettingsAll({...response.data});
//        emit(AuthenticationSuccess());
//      },
//      failureMessage: '🥶 unexpected error occurred while registering.',
//    );
//  }
//
//  Future<void> _verifySubmitEvent(VerifySubmitEvent event, Emitter<AuthenticationState> emit) async {
//    emit(AuthenticationLoading());
//    await _handleApiResponse(
//      emit: emit,
//      apiCall: () async => await _authApiService.fetchVerify(verifyData: event.verifyData),
//      onSuccess: (Response<dynamic> response) async {
//        await _storage.deleteAsyncSettingsAll(keys: ['verify_token', 'verify_token_expiration_date']);
//        await _storage.setAsyncSettingsAll({...response.data, 'isDoneSplash': true, 'isAuthenticated': true});
//        emit(AuthenticationSuccess());
//      },
//      failureMessage: '🥶 unexpected error occurred while verifying.',
//    );
//  }
//
//  Future<void> _loginSubmitEvent(LoginSubmitEvent event, Emitter<AuthenticationState> emit) async {
//    emit(AuthenticationLoading());
//    await _handleApiResponse(
//      emit: emit,
//      apiCall: () async => await _authApiService.fetchLogin(loginData: event.loginData),
//      onSuccess: (Response<dynamic> response) async {
//        await _storage.setAsyncSettingsAll({...response.data, 'isDoneSplash': true, 'isAuthenticated': true});
//        bool isAuthenticated = await _storage.getAsyncSettings(key: 'isAuthenticated');
//        log('🚀 isAuthenticated: $isAuthenticated');
//        emit(AuthenticationSuccess());
//      },
//      failureMessage: '🥶 unexpected error occurred while logging in.',
//    );
//  }
//
//  Future<void> _requestResetPasswordEvent(RequestResetPasswordEvent event, Emitter<AuthenticationState> emit) async {
//    await _handleApiResponse(
//      emit: emit,
//      apiCall: () async => await _authApiService.fetchRequestResetPassword(requestResetPasswordData: event.emailData),
//      onSuccess: (Response<dynamic> response) async {
//        await _storage.setAsyncSettingsAll({...response.data});
//      },
//      failureMessage: '🥶 unexpected error occurred in _requestResetPasswordEvent.',
//    );
//  }
//
//  Future<void> _resetPasswordEvent(ResetPasswordEvent event, Emitter<AuthenticationState> emit) async {
//    await _handleApiResponse(
//      emit: emit,
//      apiCall: () async => await _authApiService.fetchResetPassword(resetPasswordData: event.resetPasswordData),
//      onSuccess: (Response<dynamic> response) async {
//        await _storage.deleteAsyncSettingsAll(keys: ['reset_password_token', 'reset_password_token_expiration_date']);
//        await _storage.setAsyncSettingsAll({...response.data, 'isDoneSplash': true, 'isAuthenticated': true});
//        emit(AuthenticationSuccess());
//      },
//      failureMessage: '🥶 unexpected error occurred while verifying.',
//    );
//  }
//
//  Future<void> _socialAuthEvent(SocialAuthEvent event, Emitter<AuthenticationState> emit) async {
//    emit(AuthenticationLoading());
//
//
//    if (event.socialProvider == 'google') {
//      await _googleAuth(event, emit);
//    }
//  }
//
//  Future<void> _googleAuth(SocialAuthEvent event, Emitter<AuthenticationState> emit) async {
//    final GoogleSignIn googleSignIn = GoogleSignIn();
//    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
//
//    try {
//      final GoogleSignInAccount? selectedGoogleAccount = await googleSignIn.signIn();
//
//      if (selectedGoogleAccount == null) {
//        emit(const AuthenticationFailure(failureMessage: '🥶 Google sign-in canceled.'));
//        return;
//      }
//
//      final GoogleSignInAuthentication googleSignInAuthentication = await selectedGoogleAccount.authentication;
//      final AuthCredential googleAuthCredential = GoogleAuthProvider.credential(idToken: googleSignInAuthentication.idToken, accessToken: googleSignInAuthentication.accessToken);
//
//      await firebaseAuth.signInWithCredential(googleAuthCredential);
//
//      User? firebaseUser = firebaseAuth.currentUser;
//
//      if (firebaseUser == null) {
//        emit(const AuthenticationFailure(failureMessage: '🥶 Error occurred while sign in to firebase.'));
//        return;
//      }
//
//      String? firebaseUserIdToken = await firebaseUser.getIdToken();
//
//      Response? response = await _authApiService.fetchSocialAuth(firebaseUserIdToken: firebaseUserIdToken);
//      if (response != null && response.statusCode! < 400) {
//        logger.w('🚀 social auth is success!: response.data: ${response.data}');
//        await _storage.setAsyncSettingsAll({...response.data, 'isDoneSplash': true, 'isAuthenticated': true});
//        await _storage.setAsyncUser(user: UserModel.fromJson(response.data));
//
//        emit(AuthenticationSuccess());
//        return;
//      }
//      logger.w('🎃 social auth is failed!');
//      emit(const AuthenticationFailure(failureMessage: '🥶 Server error occurred while social auth.'));
//    } catch (e) {
//      logger.w('🥶 Google Sign-In Error: $e');
//      print('🥶 Google Sign-In Error: $e');
//      emit(AuthenticationFailure(failureMessage: '🥶 Google Sign-In Error Big Error: $e'));
//    }
//  }
//
//  Future<void> _handleApiResponse({required Emitter<AuthenticationState> emit, required Future<Response?> Function() apiCall, required Future<void> Function(Response response) onSuccess, required String failureMessage}) async {
//    try {
//      final Response? response = await apiCall();
//      if (response != null && response.statusCode! < 400) {
//        await onSuccess(response);
//      } else if (response != null) {
//        emit(AuthenticationFailure(failureMessage: response.data['detail']));
//      } else {
//        emit(AuthenticationFailure(failureMessage: failureMessage));
//      }
//    } catch (e) {
//      emit(AuthenticationFailure(failureMessage: '$failureMessage: $e'));
//    }
//  }
//}
