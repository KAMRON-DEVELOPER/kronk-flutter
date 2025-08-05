import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/riverpod/general/connectivity_notifier_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/url_launches.dart';
import 'package:kronk/widgets/my_toast.dart';
import 'package:rive/rive.dart';
import 'package:toastification/toastification.dart';

final termsAcceptedProvider = StateProvider<bool>((ref) => false);

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MyTheme theme = ref.watch(themeProvider);
    final termsAccepted = ref.watch(termsAcceptedProvider);
    final AsyncValue<bool> isOnline = ref.watch(connectivityProvider);

    void onPressed() {
      isOnline.when(
        data: (bool isOnline) {
          if (!isOnline) {
            showToast(context, ref, ToastificationType.success, "Looks like you're offline! 🥺", showGlyph: false);
            return;
          }

          if (!termsAccepted) {
            showToast(context, ref, ToastificationType.warning, 'You must accept the Terms of Service to continue.');
            return;
          }

          context.push('/auth');
        },
        loading: () {},
        error: (Object err, StackTrace stack) {},
      );
    }

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      body: Stack(
        children: [
          // Animation
          const RiveAnimation.asset('assets/animations/splash-bubble.riv'),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(color: theme.primaryBackground.withValues(alpha: 0.6)),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.only(left: 28.dp, right: 28.dp, bottom: 12.dp),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Kronk',
                    style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 40.dp, fontWeight: FontWeight.bold, height: 0),
                  ),
                  Text(
                    'it is meant to be yours',
                    style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 18.dp, fontWeight: FontWeight.w700, height: 0),
                  ),
                  SizedBox(height: 24.dp),
                  ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryText,
                      fixedSize: Size(Sizes.screenWidth - 56.dp, 52.dp),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.dp)),
                    ),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.quicksand(color: theme.primaryBackground, fontSize: 18.dp, fontWeight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(height: 8.dp),
                  TextButton(
                    onPressed: () {
                      if (!termsAccepted) {
                        showToast(context, ref, ToastificationType.warning, 'You must accept the Terms of Service to continue.');
                        return;
                      }

                      context.push('/settings');
                    },
                    child: Text(
                      'Set up later',
                      style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 18.dp, fontWeight: FontWeight.w700),
                    ),
                  ),

                  SizedBox(height: 8.dp),
                  const TermsAcceptanceWidget(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TermsAcceptanceWidget extends ConsumerWidget {
  const TermsAcceptanceWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MyTheme theme = ref.watch(themeProvider);
    final termsAccepted = ref.watch(termsAcceptedProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Transform.scale(
          scale: 0.85,
          child: Checkbox(
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            checkColor: theme.primaryText,
            activeColor: theme.secondaryText,
            side: BorderSide(color: theme.secondaryText),
            value: termsAccepted,
            onChanged: (value) => ref.read(termsAcceptedProvider.notifier).state = value ?? false,
          ),
        ),
        Flexible(
          child: Text.rich(
            TextSpan(
              style: GoogleFonts.quicksand(color: theme.secondaryText, decorationColor: theme.secondaryText, fontSize: 14),
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms',
                  style: const TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.w600),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      await customURLLauncher(isWebsite: true, url: 'https://api.kronk.uz/terms');
                    },
                ),
                const TextSpan(text: ' of Kronk.'),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
