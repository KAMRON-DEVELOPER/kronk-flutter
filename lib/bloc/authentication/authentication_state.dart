import 'package:equatable/equatable.dart';

abstract class AuthenticationState extends Equatable {
  const AuthenticationState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthenticationState {}

class AuthLoading extends AuthenticationState {}

class VerifySuccess extends AuthenticationState {}

class LoginSuccess extends AuthenticationState {}

class ForgotPasswordSuccess extends AuthenticationState {}

class RequestForgotPasswordSuccess extends AuthenticationState {}

class RegisterSuccess extends AuthenticationState {}

class GoogleAuthSuccess extends AuthenticationState {}

class AppleAuthSuccess extends AuthenticationState {}

class SignOutSuccess extends AuthenticationState {}

class GoogleSignOutSuccess extends AuthenticationState {}

class AppleSignOutSuccess extends AuthenticationState {}

class DeleteAccountSuccess extends AuthenticationState {}

class GoogleDeleteAccountSuccess extends AuthenticationState {}

class AppleDeleteAccountSuccess extends AuthenticationState {}

class AuthFailure extends AuthenticationState {
  final String? failureMessage;

  const AuthFailure({this.failureMessage});

  @override
  List<Object?> get props => [failureMessage];
}
