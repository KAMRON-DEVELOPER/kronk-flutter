import 'dart:async';
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

class VerifyScreen extends ConsumerStatefulWidget {
  const VerifyScreen({super.key});

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  String code = '';

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final MyTheme theme = ref.watch(themeProvider);
    final AsyncValue<bool> isOnline = ref.watch(connectivityNotifierProvider);

    isOnline.when(
      data: (bool isOnline) => !isOnline ? Timer(const Duration(seconds: 5), () => context.go('/welcome')) : null,
      error: (Object error, StackTrace stackTrace) {},
      loading: () {},
    );

    void onChanged() {
      isOnline.when(
        data: (bool isOnline) {
          if (!isOnline) {
            if (GoRouterState.of(context).path == '/auth/verify') {
              ScaffoldMessenger.of(context).showSnackBar(
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
          String code = _controllers.map((TextEditingController controller) => controller.text.trim()).join();
          if (code.length == 4) setState(() => this.code = code);
        },
        loading: () {},
        error: (Object err, StackTrace stack) {},
      );
    }

    return BlocConsumer<AuthenticationBloc, AuthenticationState>(
      listener: (BuildContext context, AuthenticationState state) {
        if (state is AuthLoading) {
        } else if (state is VerifySuccess) {
          if (GoRouterState.of(context).path == 'verify') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: theme.secondaryBackground,
                behavior: SnackBarBehavior.floating,
                dismissDirection: DismissDirection.horizontal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.dp)),
                margin: EdgeInsets.only(left: 28.dp, right: 28.dp, bottom: Sizes.screenHeight - 96.dp),
                content: Text(
                  '🎉 You are verified successfully.',
                  style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, height: 0),
                ),
              ),
            );
          }
          Timer(const Duration(seconds: 4), () => context.go('/settings'));
        } else if (state is AuthFailure) {
          if (GoRouterState.of(context).path == 'verify') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: theme.secondaryBackground,
                behavior: SnackBarBehavior.floating,
                dismissDirection: DismissDirection.horizontal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.dp)),
                margin: EdgeInsets.only(left: 28.dp, right: 28.dp, bottom: Sizes.screenHeight - 96.dp),
                content: Text(
                  '${state.failureMessage}',
                  style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, height: 0),
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
                    'Verify Code',
                    style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 40.dp, fontWeight: FontWeight.bold, height: 0),
                  ),

                  /// Code fields
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
                            hintText: '*',
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
                            onChanged();
                          },
                        ),
                      ),
                    ),
                  ),

                  /// Verify button
                  ElevatedButton(
                    onPressed: () {
                      log('code: $code');
                      context.read<AuthenticationBloc>().add(VerifySubmitEvent(code: code));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryText,
                      fixedSize: Size(Sizes.screenWidth - 56.dp, 52.dp),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.dp)),
                    ),
                    child: state == AuthLoading()
                        ? LoadingAnimationWidget.inkDrop(color: theme.primaryBackground, size: 24.dp)
                        : Text(
                            'Verify',
                            style: GoogleFonts.quicksand(color: theme.primaryBackground, fontSize: 18.dp, fontWeight: FontWeight.w700),
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
