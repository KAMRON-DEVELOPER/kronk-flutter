import 'package:equatable/equatable.dart';

abstract class AuthenticationEvent extends Equatable {
  const AuthenticationEvent();

  @override
  List<Object?> get props => [];
}

class RegisterSubmitEvent extends AuthenticationEvent {
  final Map<String, String> registerData;

  const RegisterSubmitEvent({required this.registerData});

  @override
  List<Object> get props => [registerData];
}

class VerifySubmitEvent extends AuthenticationEvent {
  final String code;

  const VerifySubmitEvent({required this.code});

  @override
  List<Object> get props => [code];
}

class LoginSubmitEvent extends AuthenticationEvent {
  final Map<String, String> loginData;

  const LoginSubmitEvent({required this.loginData});

  @override
  List<Object> get props => [loginData];
}

class RequestForgotPasswordEvent extends AuthenticationEvent {
  final String email;

  const RequestForgotPasswordEvent({required this.email});

  @override
  List<Object> get props => [email];
}

class ForgotPasswordEvent extends AuthenticationEvent {
  final Map<String, String> forgotPasswordData;

  const ForgotPasswordEvent({required this.forgotPasswordData});

  @override
  List<Object> get props => [forgotPasswordData];
}

class SocialAuthEvent extends AuthenticationEvent {}
