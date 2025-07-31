import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kronk/main.dart';
import 'package:kronk/models/user_model.dart';
import 'package:kronk/services/api_service/user_service.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/storage.dart';

import 'authentication_event.dart';
import 'authentication_state.dart';

class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  final UserService _authApiService = UserService();
  final Storage _storage = Storage();

  AuthenticationBloc() : super(AuthInitial()) {
    on<RegisterSubmitEvent>(_registerSubmitEvent);
    on<VerifySubmitEvent>(_verifySubmitEvent);
    on<LoginSubmitEvent>(_loginSubmitEvent);
    on<RequestForgotPasswordEvent>(_requestForgotPasswordEvent);
    on<ForgotPasswordEvent>(_forgotPasswordEvent);
    on<SocialAuthEvent>(_googleAuthEvent);
  }

  Future<void> _registerSubmitEvent(RegisterSubmitEvent event, Emitter<AuthenticationState> emit) async {
    emit(AuthLoading());

    try {
      final Response response = await _authApiService.fetchRegister(data: event.registerData);

      if (response.statusCode! >= 400) {
        emit(AuthFailure(failureMessage: response.data['details'] is List ? (response.data['details'] as List).join(', ') : response.data['details'].toString()));
        return;
      }

      myLogger.d('response.data: ${response.data}');
      await _storage.setSettingsAllAsync({...response.data});
      emit(RegisterSuccess());
    } catch (error) {
      emit(AuthFailure(failureMessage: error.toString()));
    }
  }

  Future<void> _verifySubmitEvent(VerifySubmitEvent event, Emitter<AuthenticationState> emit) async {
    emit(AuthLoading());

    try {
      final Response response = await _authApiService.fetchVerify(code: event.code);

      if (response.statusCode! >= 400) {
        emit(AuthFailure(failureMessage: response.data['details'] is List ? (response.data['details'] as List).join(', ') : response.data['details'].toString()));
        return;
      }

      await _storage.deleteAsyncSettingsAll(keys: ['verify_token', 'verify_token_expiration_date']);

      await _storage.setSettingsAllAsync({...response.data['tokens'], 'isDoneWelcome': true});
      await _storage.setUserAsync(user: UserModel.fromJson(response.data['user']));

      emit(VerifySuccess());
    } catch (e) {
      emit(AuthFailure(failureMessage: e.toString()));
    }
  }

  Future<void> _loginSubmitEvent(LoginSubmitEvent event, Emitter<AuthenticationState> emit) async {
    emit(AuthLoading());

    try {
      final Response response = await _authApiService.fetchLogin(data: event.loginData);

      myLogger.d('response.data: ${response.data}, type: ${response.data.runtimeType}');

      if ([400, 404].contains(response.statusCode)) {
        emit(AuthFailure(failureMessage: response.data['details'] is List ? (response.data['details'] as List).join(', ') : response.data['details'].toString()));
        return;
      }

      await _storage.setSettingsAllAsync({...response.data['tokens'], 'isDoneWelcome': true});
      await _storage.setUserAsync(user: UserModel.fromJson(response.data['user']));

      final r = await _storage.getRefreshTokenAsync();
      myLogger.d('getRefreshTokenAsync: $r, type: ${r.runtimeType}');
      emit(LoginSuccess());
    } catch (error) {
      emit(AuthFailure(failureMessage: error.toString()));
    }
  }

  Future<void> _requestForgotPasswordEvent(RequestForgotPasswordEvent event, Emitter<AuthenticationState> emit) async {
    emit(AuthLoading());

    try {
      final Response response = await _authApiService.fetchRequestForgotPassword(email: event.email);

      if (response.statusCode! >= 400) {
        emit(AuthFailure(failureMessage: response.data['details'] is List ? (response.data['details'] as List).join(', ') : response.data['details'].toString()));
        return;
      }

      myLogger.d('response.data: ${response.data}');
      await _storage.setSettingsAllAsync({...response.data});
      emit(RequestForgotPasswordSuccess());
    } catch (error) {
      emit(AuthFailure(failureMessage: error.toString()));
    }
  }

  Future<void> _forgotPasswordEvent(ForgotPasswordEvent event, Emitter<AuthenticationState> emit) async {
    emit(AuthLoading());

    try {
      final Response response = await _authApiService.fetchForgotPassword(data: event.forgotPasswordData);

      if (response.statusCode! >= 400) {
        emit(AuthFailure(failureMessage: response.data['details'] is List ? (response.data['details'] as List).join(', ') : response.data['details'].toString()));
        return;
      }

      myLogger.d('response.data: ${response.data}');
      await _storage.deleteAsyncSettingsAll(keys: ['forgot_password_token', 'forgot_password_token_expiration_date']);

      await _storage.setSettingsAllAsync({...response.data['tokens'], 'isDoneWelcome': true});
      await _storage.setUserAsync(user: UserModel.fromJson(response.data['user']));

      emit(ForgotPasswordSuccess());
    } catch (error) {
      emit(AuthFailure(failureMessage: error.toString()));
    }
  }

  Future<void> _googleAuthEvent(SocialAuthEvent event, Emitter<AuthenticationState> emit) async {
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

    emit(AuthLoading());

    try {
      User? firebaseUser = firebaseAuth.currentUser;

      if (firebaseUser == null) {
        myLogger.i('🤡 firebaseUser is null and we need to authenticate it.');

        final bool supportsAuthenticate = googleSignIn.supportsAuthenticate();

        myLogger.w('1 supportsAuthenticate: $supportsAuthenticate');
        if (!supportsAuthenticate) {
          myLogger.w('🥶 Google Sign-In not supported on this platform');
          emit(const AuthFailure(failureMessage: 'Google Sign-In not supported'));
          return;
        }

        // final GoogleSignInAuthorizationClient a = googleSignIn.authorizationClient;
        // final GoogleSignInClientAuthorization? z = await a.authorizationForScopes([]);
        // final GoogleSignInClientAuthorization x = await a.authorizeScopes([]);
        // final GoogleSignInServerAuthorization? c = await a.authorizeServer([]);
        // final googleSignInAccount = await googleSignIn.attemptLightweightAuthentication(reportAllExceptions: true);
        //
        // if (googleSignInAccount == null) {
        //   myLogger.e('googleSignInAccount is null');
        //   return;
        // }

        final GoogleSignInAccount googleSignInAccount = await googleSignIn.authenticate();

        final GoogleSignInAuthentication googleSignInAuthentication = googleSignInAccount.authentication;
        myLogger.w('3 googleSignInAuthentication.idToken: ${googleSignInAuthentication.idToken}');
        final OAuthCredential oAuthCredential = GoogleAuthProvider.credential(idToken: googleSignInAuthentication.idToken);

        // Sign in to Firebase with Google credentials
        final UserCredential userCredential = await firebaseAuth.signInWithCredential(oAuthCredential);
        firebaseUser = userCredential.user;

        if (firebaseUser == null) {
          emit(const AuthFailure(failureMessage: '🥶 Error occurred while signing in to Firebase.'));
          return;
        }
      }

      String? firebaseUserIdToken = await firebaseUser.getIdToken();

      Response? response = await _authApiService.fetchGoogleAuth(firebaseUserIdToken: firebaseUserIdToken);
      myLogger.w('7 response: $response');

      if (response.statusCode! < 400) {
        myLogger.i('🚀 social auth is success!: response.data: ${response.data}, runtimeType: ${response.data.runtimeType}');

        await _storage.setSettingsAllAsync({...response.data['tokens'], 'isDoneWelcome': true});
        await _storage.setUserAsync(user: UserModel.fromJson(response.data['user']));

        emit(GoogleAuthSuccess());
        return;
      }
      myLogger.w('🎃 social auth is failed!');
      emit(const AuthFailure(failureMessage: '🥶 Server error occurred while social auth.'));
    } on GoogleSignInException catch (e) {
      myLogger.e('GoogleSignInException e: ${e.toString()}');
      emit(const AuthFailure(failureMessage: 'Authentication cancelled by the user'));
    } catch (e) {
      myLogger.w('🥶 Google Sign-In Error: $e');
      emit(AuthFailure(failureMessage: '🥶 Google Sign-In Error: $e'));
    }
  }
}
