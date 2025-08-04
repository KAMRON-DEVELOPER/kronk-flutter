import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kronk/main.dart';
import 'package:kronk/models/user_model.dart';
import 'package:kronk/services/api_service/user_service.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/storage.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'authentication_event.dart';
import 'authentication_state.dart';

enum AuthProvider { email, google, apple }

class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  final UserService userService = UserService();
  final Storage storage = Storage();

  AuthenticationBloc() : super(AuthInitial()) {
    on<RegisterSubmitEvent>(_registerSubmitEvent);
    on<VerifySubmitEvent>(_verifySubmitEvent);
    on<LoginSubmitEvent>(_loginSubmitEvent);
    on<RequestForgotPasswordEvent>(_requestForgotPasswordEvent);
    on<ForgotPasswordEvent>(_forgotPasswordEvent);
    on<GoogleAuthEvent>(_googleAuthEvent);
    on<AppleAuthEvent>(_appleAuthEvent);
    on<LogoutEvent>(_signOutEvent);
    on<DeleteAccountEvent>(_deleteAccountEvent);
  }

  Future<void> _registerSubmitEvent(RegisterSubmitEvent event, Emitter<AuthenticationState> emit) async {
    emit(AuthLoading());

    try {
      final Response response = await userService.fetchRegister(data: event.registerData);

      if (response.statusCode! >= 400) {
        emit(AuthFailure(failureMessage: response.data['details'] is List ? (response.data['details'] as List).join(', ') : response.data['details'].toString()));
        return;
      }

      myLogger.d('response.data: ${response.data}');
      await storage.setSettingsAllAsync({...response.data});
      emit(RegisterSuccess());
    } catch (error) {
      emit(AuthFailure(failureMessage: error.toString()));
    }
  }

  Future<void> _verifySubmitEvent(VerifySubmitEvent event, Emitter<AuthenticationState> emit) async {
    emit(AuthLoading());

    try {
      final Response response = await userService.fetchVerify(code: event.code);

      if (response.statusCode! >= 400) {
        emit(AuthFailure(failureMessage: response.data['details'] is List ? (response.data['details'] as List).join(', ') : response.data['details'].toString()));
        return;
      }

      await storage.deleteAsyncSettingsAll(keys: ['verify_token', 'verify_token_expiration_date']);
      await storage.setSettingsAllAsync({...response.data['tokens'], 'isDoneWelcome': true, 'authProvider': AuthProvider.email.name});
      await storage.setUserAsync(user: UserModel.fromJson(response.data['user']));

      emit(VerifySuccess());
    } catch (e) {
      emit(AuthFailure(failureMessage: e.toString()));
    }
  }

  Future<void> _loginSubmitEvent(LoginSubmitEvent event, Emitter<AuthenticationState> emit) async {
    emit(AuthLoading());

    try {
      final Response response = await userService.fetchLogin(data: event.loginData);

      myLogger.d('response.data: ${response.data}, type: ${response.data.runtimeType}');

      if ([400, 404].contains(response.statusCode)) {
        emit(AuthFailure(failureMessage: response.data['details'] is List ? (response.data['details'] as List).join(', ') : response.data['details'].toString()));
        return;
      }

      await storage.setSettingsAllAsync({...response.data['tokens'], 'isDoneWelcome': true, 'authProvider': AuthProvider.email.name});
      await storage.setUserAsync(user: UserModel.fromJson(response.data['user']));

      final r = await storage.getRefreshTokenAsync();
      myLogger.d('getRefreshTokenAsync: $r, type: ${r.runtimeType}');
      emit(LoginSuccess());
    } catch (error) {
      emit(AuthFailure(failureMessage: error.toString()));
    }
  }

  Future<void> _requestForgotPasswordEvent(RequestForgotPasswordEvent event, Emitter<AuthenticationState> emit) async {
    emit(AuthLoading());

    try {
      final Response response = await userService.fetchRequestForgotPassword(email: event.email);

      if (response.statusCode! >= 400) {
        emit(AuthFailure(failureMessage: response.data['details'] is List ? (response.data['details'] as List).join(', ') : response.data['details'].toString()));
        return;
      }

      myLogger.d('response.data: ${response.data}');
      await storage.setSettingsAllAsync({...response.data});
      emit(RequestForgotPasswordSuccess());
    } catch (error) {
      emit(AuthFailure(failureMessage: error.toString()));
    }
  }

  Future<void> _forgotPasswordEvent(ForgotPasswordEvent event, Emitter<AuthenticationState> emit) async {
    emit(AuthLoading());

    try {
      final Response response = await userService.fetchForgotPassword(data: event.forgotPasswordData);

      if (response.statusCode! >= 400) {
        emit(AuthFailure(failureMessage: response.data['details'] is List ? (response.data['details'] as List).join(', ') : response.data['details'].toString()));
        return;
      }

      myLogger.d('response.data: ${response.data}');
      await storage.deleteAsyncSettingsAll(keys: ['forgot_password_token', 'forgot_password_token_expiration_date']);

      await storage.setSettingsAllAsync({...response.data['tokens'], 'isDoneWelcome': true, 'authProvider': AuthProvider.email.name});
      await storage.setUserAsync(user: UserModel.fromJson(response.data['user']));

      emit(ForgotPasswordSuccess());
    } catch (error) {
      emit(AuthFailure(failureMessage: error.toString()));
    }
  }

  Future<void> _googleAuthEvent(GoogleAuthEvent event, Emitter<AuthenticationState> emit) async {
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

    emit(AuthLoading());

    try {
      User? firebaseUser = firebaseAuth.currentUser;

      if (firebaseUser == null) {
        myLogger.i('🤡 firebaseUser is null');
        final GoogleSignInAccount googleSignInAccount = await googleSignIn.authenticate();

        final GoogleSignInAuthentication googleSignInAuthentication = googleSignInAccount.authentication;
        final OAuthCredential oAuthCredential = GoogleAuthProvider.credential(idToken: googleSignInAuthentication.idToken);

        final UserCredential userCredential = await firebaseAuth.signInWithCredential(oAuthCredential);
        firebaseUser = userCredential.user;

        if (firebaseUser == null) {
          emit(const AuthFailure(failureMessage: '🥶 Error occurred while signing in to Firebase.'));
          return;
        }
      }

      String? idToken = await firebaseUser.getIdToken();

      Response? response = await userService.fetchSocialAuth(idToken: idToken);

      if (response.statusCode == 200) {
        await storage.setSettingsAllAsync({...response.data['tokens'], 'isDoneWelcome': true, 'authProvider': AuthProvider.google.name});
        await storage.setUserAsync(user: UserModel.fromJson(response.data['user']));

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

  Future<void> _appleAuthEvent(AppleAuthEvent event, Emitter<AuthenticationState> emit) async {
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

    emit(AuthLoading());

    try {
      User? firebaseUser = firebaseAuth.currentUser;
      String? authorizationCode;

      if (firebaseUser == null) {
        myLogger.i('🤡 firebaseUser is null');
        if (Platform.isAndroid) {
          final appleProvider = AppleAuthProvider()
            ..addScope('email')
            ..addScope('name');

          final UserCredential userCredential = await firebaseAuth.signInWithProvider(appleProvider);
          authorizationCode = userCredential.additionalUserInfo?.authorizationCode;
          myLogger.d('userCredential.user?.displayName: ${userCredential.user?.displayName}');
          myLogger.d('userCredential.additionalUserInfo?.authorizationCode: ${userCredential.additionalUserInfo?.authorizationCode}');
        } else {
          final rawNonce = generateNonce();
          final nonce = _sha256ofString(rawNonce);
          final AuthorizationCredentialAppleID credential = await SignInWithApple.getAppleIDCredential(
            scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
            nonce: nonce,
          );

          myLogger.d('1 credential: $credential');
          myLogger.d('2 credential.email: ${credential.email}');
          myLogger.d('3 credential.givenName: ${credential.givenName}');
          myLogger.d('4 credential.authorizationCode: ${credential.authorizationCode}');
          myLogger.d('5 credential.identityToken: ${credential.identityToken}');

          final OAuthProvider oAuthProvider = OAuthProvider('apple.com');
          final OAuthCredential appleAuthCredential = oAuthProvider.credential(
            idToken: credential.identityToken,
            rawNonce: Platform.isIOS ? rawNonce : null,
            accessToken: credential.authorizationCode,
            // accessToken: Platform.isIOS ? null : credential.authorizationCode,
          );

          final UserCredential userCredential = await firebaseAuth.signInWithCredential(appleAuthCredential);
          authorizationCode = userCredential.additionalUserInfo?.authorizationCode;
          firebaseUser = userCredential.user;
          myLogger.d('userCredential.user?.displayName: ${userCredential.user?.displayName}');
          myLogger.d('userCredential.additionalUserInfo?.authorizationCode: ${userCredential.additionalUserInfo?.authorizationCode}');
        }
      }

      final String? idToken = await firebaseUser?.getIdToken();
      myLogger.d('idToken: $idToken');

      Response? response = await userService.fetchSocialAuth(idToken: idToken, authorizationCode: authorizationCode);

      if (response.statusCode == 200) {
        await storage.setSettingsAllAsync({...response.data['tokens'], 'isDoneWelcome': true, 'authProvider': AuthProvider.apple.name});
        await storage.setUserAsync(user: UserModel.fromJson(response.data['user']));

        emit(AppleAuthSuccess());
        return;
      } else {
        myLogger.w('🎃 social auth is failed!');
        emit(const AuthFailure(failureMessage: '🥶 Server error occurred while social auth.'));
      }
    } on GoogleSignInException catch (e) {
      myLogger.e('GoogleSignInException e: $e');
      emit(AuthFailure(failureMessage: 'GoogleSignInException e: ${e.toString()}'));
    } catch (e) {
      myLogger.w('🥶 Google Sign In Error: $e');
      emit(AuthFailure(failureMessage: '🥶 Google Sign In Error: ${e.toString()}'));
    }
  }

  Future<void> _signOutEvent(LogoutEvent event, Emitter<AuthenticationState> emit) async {
    try {
      final authProvider = await storage.getAuthProvider();

      switch (authProvider) {
        case AuthProvider.email:
          await storage.signOut();
          emit(SignOutSuccess());
          break;
        case AuthProvider.google:
          await googleSignIn.signOut();
          await FirebaseAuth.instance.signOut();
          await storage.signOut();
          emit(GoogleSignOutSuccess());
          break;
        case AuthProvider.apple:
          await FirebaseAuth.instance.signOut();
          // await FirebaseAuth.instance.revokeTokenWithAuthorizationCode(authorizationCode);
          await storage.signOut();
          emit(AppleSignOutSuccess());
          break;
      }
    } catch (e) {
      myLogger.w('Sign out failed, e: $e');
      emit(AuthFailure(failureMessage: 'Sign out failed, e: $e'));
    }
  }

  Future<void> _deleteAccountEvent(DeleteAccountEvent event, Emitter<AuthenticationState> emit) async {
    try {
      final authProvider = await storage.getAuthProvider();

      final deleted = await userService.fetchDeleteProfile();

      if (!deleted) {
        emit(const AuthFailure(failureMessage: "We couldn't delete your account at the moment. Please try again later."));
      }

      switch (authProvider) {
        case AuthProvider.email:
          await storage.signOut();
          emit(DeleteAccountSuccess());
          break;
        case AuthProvider.google:
          await googleSignIn.disconnect();
          await FirebaseAuth.instance.currentUser?.delete();
          await storage.signOut();
          emit(GoogleDeleteAccountSuccess());
          break;
        case AuthProvider.apple:
          await FirebaseAuth.instance.currentUser?.delete();
          await storage.signOut();
          emit(AppleDeleteAccountSuccess());
          break;
      }
    } on FirebaseAuthException catch (e) {
      myLogger.w('FirebaseAuthException: $e');
      emit(AuthFailure(failureMessage: 'FirebaseAuthException: $e'));
    } catch (e) {
      myLogger.w('Google Sign In Error: $e');
      emit(AuthFailure(failureMessage: 'Google Sign In Error: $e'));
    }
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
