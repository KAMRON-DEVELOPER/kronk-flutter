import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _RequestResetPasswordScreenState();
}

class _RequestResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  late TextEditingController _passwordController;
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;
  String _code = '';
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _controllers = List.generate(4, (int index) => TextEditingController());
    _focusNodes = List.generate(4, (int index) => FocusNode());
  }

  @override
  void dispose() {
    for (TextEditingController controller in _controllers) {
      controller.dispose();
    }
    for (FocusNode focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    String code = _controllers.map((TextEditingController controller) => controller.text.trim()).join();

    if (code.length == 4) setState(() => _code = code);
  }

  @override
  Widget build(BuildContext context) {
    final MyTheme theme = ref.watch(themeNotifierProvider);
    final AsyncValue<bool> asyncConnectivity = ref.watch(connectivityNotifierProvider);

    asyncConnectivity.when(
      data: (bool data) => log('🚧 asyncConnectivity data: $data'),
      error: (Object error, StackTrace stackTrace) => log('🚧 asyncConnectivity error: $error, $stackTrace'),
      loading: () => log('🚧 asyncConnectivity loading'),
    );

    return BlocConsumer<AuthenticationBloc, AuthenticationState>(
      listener: (BuildContext context, AuthenticationState state) async {
        log('🚨 listener: $state');
        if (state is AuthLoading) {
        } else if (state is ForgotPasswordSuccess) {
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
          context.go('/settings');
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🌋 ${state.failureMessage!}'),
              duration: const Duration(seconds: 30),
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
                    'Last Step 😉',
                    style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 24.dp, fontWeight: FontWeight.w600),
                  ),

                  /// code input
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      4,
                      (int index) => Container(
                        width: 60.dp,
                        height: 60.dp,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.dp),
                          border: Border.all(color: theme.secondaryText, width: 1.dp),
                        ),
                        child: TextField(
                          controller: _controllers.elementAt(index),
                          focusNode: _focusNodes.elementAt(index),
                          maxLength: 1,
                          showCursor: false,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            // hintText: '*',
                            hintStyle: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16, fontWeight: FontWeight.w500),
                            counterText: '',
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (String value) {
                            if (value.isNotEmpty) {
                              if (index < 3) {
                                _focusNodes[index + 1].requestFocus();
                              } else {
                                _focusNodes[index].unfocus();
                              }
                            } else if (value.isEmpty && index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }

                            _onChanged();
                          },
                        ),
                      ),
                    ),
                  ),

                  /// Input
                  TextFormField(
                    controller: _passwordController,
                    style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, fontWeight: FontWeight.w500),
                    cursorColor: theme.primaryText,
                    onChanged: (String value) => setState(() => _passwordError = value.trim().isValidPassword),
                    decoration: InputDecoration(
                      hintText: 'new password',
                      hintStyle: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16.dp, fontWeight: FontWeight.w500),
                      errorText: _passwordError,
                      errorStyle: GoogleFonts.quicksand(color: Colors.red, fontSize: 12.dp, fontWeight: FontWeight.w500),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: theme.primaryText.withAlpha(128)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: theme.primaryText),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.redAccent),
                        borderRadius: BorderRadius.circular(25.dp),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.redAccent.withAlpha(128)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  /// Button
                  ElevatedButton(
                    onPressed: () {
                      if (_passwordController.text.trim().isValidPassword == null && _code.length == 4) {
                        context.read<AuthenticationBloc>().add(ForgotPasswordEvent(forgotPasswordData: {'code': _code, 'new_password': _passwordController.text.trim()}));
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
                            'change password',
                            style: GoogleFonts.quicksand(color: theme.primaryBackground, fontSize: 16.dp, fontWeight: FontWeight.w600),
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
