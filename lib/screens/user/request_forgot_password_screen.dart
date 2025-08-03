import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/bloc/authentication/authentication_bloc.dart';
import 'package:kronk/bloc/authentication/authentication_event.dart';
import 'package:kronk/bloc/authentication/authentication_state.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/riverpod/general/connectivity_notifier_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class RequestForgotPasswordScreen extends ConsumerStatefulWidget {
  const RequestForgotPasswordScreen({super.key});

  @override
  ConsumerState<RequestForgotPasswordScreen> createState() => _RequestForgotPasswordScreenState();
}

class _RequestForgotPasswordScreenState extends ConsumerState<RequestForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  String? _emailError;

  @override
  Widget build(BuildContext context) {
    final MyTheme theme = ref.watch(themeProvider);
    final AsyncValue<bool> asyncConnectivity = ref.watch(connectivityProvider);

    asyncConnectivity.when(
      data: (bool data) => log('🚧 asyncConnectivity data: $data'),
      error: (Object error, StackTrace stackTrace) => log('🚧 asyncConnectivity error: $error, $stackTrace'),
      loading: () => log('🚧 asyncConnectivity loading'),
    );

    return BlocConsumer<AuthenticationBloc, AuthenticationState>(
      listener: (BuildContext context, AuthenticationState state) async {
        log('🚨 listener: $state');
        if (state is AuthLoading) {
        } else if (state is RequestForgotPasswordSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Column(children: [Text('🎉 You have changed your password successfully.')]),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              dismissDirection: DismissDirection.horizontal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: EdgeInsets.only(bottom: 24.dp, left: 16.dp, right: 16.dp),
            ),
          );
          await Future.delayed(const Duration(seconds: 4), () {});
          if (!context.mounted) return;
          context.go('/auth/forgot_password');
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🌋 ${state.failureMessage!}'),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              dismissDirection: DismissDirection.horizontal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: EdgeInsets.only(bottom: 24.dp, left: 16.dp, right: 16.dp),
            ),
          );
        }
      },

      builder: (BuildContext context, AuthenticationState state) {
        log('🎄 state is $state in builder');
        return Scaffold(
          backgroundColor: theme.primaryBackground,
          body: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 28.dp),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 12.dp,
                children: [
                  /// Text
                  Text(
                    'Request Forgot Password',
                    style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 24, fontWeight: FontWeight.w600),
                  ),

                  /// Input
                  AutofillGroup(
                    child: TextFormField(
                      controller: _emailController,
                      style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, fontWeight: FontWeight.w500),
                      cursorColor: theme.primaryText,
                      onChanged: (String value) => setState(() => _emailError = value.trim().isValidEmail),
                      autofillHints: [AutofillHints.email],
                      decoration: InputDecoration(
                        hintText: 'email',
                        hintStyle: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16.dp, fontWeight: FontWeight.w500),
                        errorText: _emailError,
                        errorStyle: GoogleFonts.quicksand(color: Colors.red, fontSize: 12.dp, fontWeight: FontWeight.w500),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: theme.primaryText.withAlpha(128)),
                          borderRadius: BorderRadius.circular(12.dp),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: theme.primaryText),
                          borderRadius: BorderRadius.circular(12.dp),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.redAccent),
                          borderRadius: BorderRadius.circular(26.dp),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.redAccent.withAlpha(128)),
                          borderRadius: BorderRadius.circular(12.dp),
                        ),
                      ),
                    ),
                  ),

                  /// Button
                  ElevatedButton(
                    onPressed: () {
                      if (_emailController.text.trim().isValidEmail == null) {
                        context.read<AuthenticationBloc>().add(RequestForgotPasswordEvent(email: _emailController.text.trim()));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryText,
                      fixedSize: Size(Sizes.screenWidth - 56.dp, 52.dp),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.dp)),
                    ),
                    child: state == AuthLoading()
                        ? LoadingAnimationWidget.inkDrop(color: theme.primaryBackground, size: 36.dp)
                        : Text(
                            'Send code',
                            style: GoogleFonts.quicksand(color: theme.primaryBackground, fontSize: 24, fontWeight: FontWeight.w600),
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
