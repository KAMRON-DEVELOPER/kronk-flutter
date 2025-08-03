import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:kronk/constants/kronk_icon.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/riverpod/general/connectivity_notifier_provider.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../bloc/authentication/authentication_bloc.dart';
import '../../bloc/authentication/authentication_event.dart';
import '../../bloc/authentication/authentication_state.dart';
import '../../riverpod/general/theme_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late TextEditingController _nameController, _passwordController, _usernameController, _emailController;
  bool isPasswordVisible = false;
  bool isLoginMode = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MyTheme theme = ref.watch(themeProvider);
    final AsyncValue<bool> isOnline = ref.watch(connectivityProvider);

    isOnline.when(
      data: (bool isOnline) => !isOnline ? Timer(const Duration(seconds: 5), () => context.go('/welcome')) : null,
      error: (Object error, StackTrace stackTrace) {},
      loading: () {},
    );

    void onPressed() {
      isOnline.when(
        data: (bool isOnline) {
          if (!isOnline) {
            if (GoRouterState.of(context).path == '/auth') {
              return ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: theme.secondaryBackground,
                  behavior: SnackBarBehavior.floating,
                  dismissDirection: DismissDirection.horizontal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.dp)),
                  margin: EdgeInsets.only(left: 28.dp, right: 28.dp, bottom: Sizes.screenHeight - 96.dp),
                  content: Text(
                    "Looks like you're offline! 🥺",
                    style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, height: 0),
                  ),
                ),
              );
            }
          }

          /// When online...
          final name = _nameController.text.trim();
          final username = _usernameController.text.trim();
          final email = _emailController.text.trim();
          final password = _passwordController.text.trim();

          final bool isNameEmpty = name.isEmpty;
          final bool isUsernameEmpty = username.isEmpty;
          final bool isEmailEmpty = email.isEmpty;
          final bool isPasswordEmpty = password.isEmpty;

          final loginData = {'username': username, 'password': password};

          if (isLoginMode && !isUsernameEmpty && !isPasswordEmpty) {
            context.read<AuthenticationBloc>().add(LoginSubmitEvent(loginData: loginData));
          } else if (!isNameEmpty && !isUsernameEmpty && !isEmailEmpty && !isPasswordEmpty) {
            final registerData = {...loginData, 'email': email, 'name': name};
            context.read<AuthenticationBloc>().add(RegisterSubmitEvent(registerData: registerData));
          }
        },
        loading: () {},
        error: (Object err, StackTrace stack) {},
      );
    }

    return BlocConsumer<AuthenticationBloc, AuthenticationState>(
      listener: (BuildContext context, AuthenticationState state) {
        if (state is AuthLoading) {
        } else if (state is LoginSuccess) {
          if (GoRouterState.of(context).path == '/auth') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: theme.secondaryBackground,
                behavior: SnackBarBehavior.floating,
                dismissDirection: DismissDirection.horizontal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.dp)),
                margin: EdgeInsets.only(left: 28.dp, right: 28.dp, bottom: Sizes.screenHeight - 96.dp),
                content: Text(
                  '🎉 You have logged in successfully',
                  style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, height: 0),
                ),
              ),
            );
          }
          Timer(const Duration(seconds: 4), () => context.go('/settings'));
        } else if (state is RegisterSuccess) {
          if (GoRouterState.of(context).path == '/auth') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: theme.secondaryBackground,
                behavior: SnackBarBehavior.floating,
                dismissDirection: DismissDirection.horizontal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.dp)),
                margin: EdgeInsets.only(left: 28.dp, right: 28.dp, bottom: Sizes.screenHeight - 96.dp),
                content: Text(
                  '🎉 You verification code sent.',
                  style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, height: 0),
                ),
              ),
            );
          }
          Timer(const Duration(seconds: 4), () => context.go('/auth/verify'));
        } else if (state is GoogleAuthSuccess) {
          if (GoRouterState.of(context).path == '/auth') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: theme.secondaryBackground,
                behavior: SnackBarBehavior.floating,
                dismissDirection: DismissDirection.horizontal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.dp)),
                margin: EdgeInsets.only(left: 28.dp, right: 28.dp, bottom: Sizes.screenHeight - 96.dp),
                content: Text(
                  '🎉 You have logged in successfully by Google',
                  style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, height: 0),
                ),
              ),
            );
          }
          Timer(const Duration(seconds: 4), () => context.go('/settings'));
        } else if (state is AuthFailure) {
          if (GoRouterState.of(context).path == '/auth') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: theme.secondaryBackground,
                behavior: SnackBarBehavior.floating,
                dismissDirection: DismissDirection.horizontal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.dp)),
                margin: EdgeInsets.only(left: 28.dp, right: 28.dp, bottom: Sizes.screenHeight - 96.dp),
                content: Text(
                  '🌋 ${state.failureMessage}',
                  style: GoogleFonts.quicksand(color: Colors.redAccent, fontSize: 16.dp, height: 0),
                ),
              ),
            );
          }
        }
      },
      builder: (BuildContext context, AuthenticationState state) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(automaticallyImplyLeading: false),
          body: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 28.dp),
              child: Column(
                spacing: 12.dp,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Title
                  Text(
                    isLoginMode ? 'Login' : 'Register',
                    style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 40.dp, fontWeight: FontWeight.bold, height: 0),
                  ),

                  /// Fields
                  AutofillGroup(
                    child: Column(
                      spacing: 8.dp,
                      children: [
                        /// Name
                        if (!isLoginMode)
                          TextFormField(
                            controller: _nameController,
                            style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, fontWeight: FontWeight.w500),
                            cursorColor: theme.primaryText,
                            autofillHints: [AutofillHints.name],
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: theme.secondaryBackground,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.dp), borderSide: BorderSide.none),
                              hintText: 'name',
                              errorText: null,
                              hintStyle: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16.dp, fontWeight: FontWeight.w500),
                              contentPadding: EdgeInsets.symmetric(vertical: 16.dp, horizontal: 20.dp),
                            ),
                          ),

                        /// Username
                        TextFormField(
                          controller: _usernameController,
                          style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, fontWeight: FontWeight.w500),
                          cursorColor: theme.primaryText,
                          autofillHints: [AutofillHints.username],
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: theme.secondaryBackground,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.dp), borderSide: BorderSide.none),
                            hintText: 'username',
                            hintStyle: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16.dp, fontWeight: FontWeight.w500),
                            contentPadding: EdgeInsets.symmetric(vertical: 16.dp, horizontal: 20.dp),
                          ),
                        ),

                        /// Email
                        if (!isLoginMode)
                          TextFormField(
                            controller: _emailController,
                            style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, fontWeight: FontWeight.w500),
                            cursorColor: theme.primaryText,
                            autofillHints: [AutofillHints.email],
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: theme.secondaryBackground,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.dp), borderSide: BorderSide.none),
                              hintText: 'email',
                              hintStyle: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16.dp, fontWeight: FontWeight.w500),
                              contentPadding: EdgeInsets.symmetric(vertical: 16.dp, horizontal: 20.dp),
                            ),
                          ),

                        /// Password
                        TextFormField(
                          controller: _passwordController,
                          style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, fontWeight: FontWeight.w500),
                          cursorColor: theme.primaryText,
                          autofillHints: [AutofillHints.password],
                          obscureText: !isPasswordVisible,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: theme.secondaryBackground,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.dp), borderSide: BorderSide.none),
                            hintText: isPasswordVisible ? '' : 'password',
                            hintStyle: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16.dp, fontWeight: FontWeight.w500),
                            contentPadding: EdgeInsets.symmetric(vertical: 16.dp, horizontal: 20.dp),
                            suffixIcon: IconButton(
                              icon: Icon(isPasswordVisible ? KronkIcon.eyeOpen : KronkIcon.eyeClose, color: theme.secondaryText),
                              onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                            ),
                          ),
                        ),

                        /// Request forgot password
                        if (isLoginMode)
                          GestureDetector(
                            onTap: () => context.push('/auth/request_forgot_password'),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Forgot password?',
                                  style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16.dp, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  /// Continue button
                  ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryText,
                      fixedSize: Size(Sizes.screenWidth - 56.dp, 52.dp),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.dp)),
                    ),
                    child: state == AuthLoading()
                        ? LoadingAnimationWidget.inkDrop(color: theme.primaryBackground, size: 24.dp)
                        : Text(
                            'Continue',
                            style: GoogleFonts.quicksand(color: theme.primaryBackground, fontSize: 18.dp, fontWeight: FontWeight.w700),
                          ),
                  ),

                  /// Or continue with
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: theme.secondaryText, thickness: 1.dp, endIndent: 8.dp),
                      ),
                      Text(
                        'or continue with',
                        style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16.dp, fontWeight: FontWeight.w500),
                      ),
                      Expanded(
                        child: Divider(color: theme.secondaryText, thickness: 1.dp, indent: 8.dp),
                      ),
                    ],
                  ),

                  /// Social auth
                  Row(
                    spacing: 28.dp,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.secondaryBackground,
                            fixedSize: Size.fromHeight(52.dp),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.dp)),
                          ),
                          onPressed: () => context.read<AuthenticationBloc>().add(SocialAuthEvent()),
                          child: Icon(IonIcons.logo_google, size: 28.dp, color: theme.primaryText),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.secondaryBackground,
                            fixedSize: Size.fromHeight(52.dp),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.dp)),
                          ),
                          onPressed: () => context.read<AuthenticationBloc>().add(SocialAuthEvent()),
                          child: Icon(IonIcons.logo_apple, size: 28.dp, color: theme.primaryText),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.dp),

                  /// Toggle Register & Login
                  GestureDetector(
                    onTap: () => setState(() => isLoginMode = !isLoginMode),
                    child: Text.rich(
                      TextSpan(
                        style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16.dp, fontWeight: FontWeight.w500),
                        children: [
                          TextSpan(text: isLoginMode ? "Don't have an account? " : 'Already have an account? '),
                          TextSpan(
                            text: isLoginMode ? 'Register' : 'Login',
                            style: TextStyle(color: theme.primaryText),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
