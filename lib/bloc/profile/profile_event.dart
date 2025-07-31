//import 'package:equatable/equatable.dart';
//
//abstract class AuthenticationEvent extends Equatable {
//  const AuthenticationEvent();
//
//  @override
//  List<Object?> get props => [];
//}
//
//class RegisterSubmitEvent extends AuthenticationEvent {
//  final Map<String, String> registerData;
//
//  const RegisterSubmitEvent({required this.registerData});
//
//  @override
//  List<Object> get props => [registerData];
//}
//
//class VerifySubmitEvent extends AuthenticationEvent {
//  final Map<String, String> verifyData;
//
//  const VerifySubmitEvent({required this.verifyData});
//
//  @override
//  List<Object> get props => [verifyData];
//}
//
//class LoginSubmitEvent extends AuthenticationEvent {
//  final Map<String, String> loginData;
//
//  const LoginSubmitEvent({required this.loginData});
//
//  @override
//  List<Object> get props => [loginData];
//}
//
//class RequestResetPasswordEvent extends AuthenticationEvent {
//  final Map<String, String> emailData;
//
//  const RequestResetPasswordEvent({required this.emailData});
//
//  @override
//  List<Object> get props => [emailData];
//}
//
//class ResetPasswordEvent extends AuthenticationEvent {
//  final Map<String, String> resetPasswordData;
//
//  const ResetPasswordEvent({required this.resetPasswordData});
//
//  @override
//  List<Object> get props => [resetPasswordData];
//}
//
//class SocialAuthEvent extends AuthenticationEvent {}
