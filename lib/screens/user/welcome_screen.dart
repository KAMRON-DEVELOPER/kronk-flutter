import 'dart:ui';

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

final termsAgreementProvider = StateProvider<bool>((ref) => false);

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MyTheme theme = ref.watch(themeProvider);
    final termsAccepted = ref.watch(termsAgreementProvider);
    final AsyncValue<bool> isOnline = ref.watch(connectivityProvider);

    void onPressed() {
      isOnline.when(
        data: (bool isOnline) {
          if (!isOnline) {
            showToast(context, ref, ToastificationType.success, "Looks like you're offline! 🥺", showGlyph: false);
            return;
          }

          if (!termsAccepted) {
            showTermsAgreementDialog(context);
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
                        showTermsAgreementDialog(context);
                        return;
                      }

                      context.push('/settings');
                    },
                    child: Text(
                      'Set up later',
                      style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 18.dp, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showTermsAgreementDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          final theme = ref.watch(themeProvider);

          return AlertDialog(
            backgroundColor: theme.tertiaryBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.dp)),
            title: Text(
              'Terms of Service & Community Guidelines',
              style: GoogleFonts.quicksand(fontSize: 20.dp, fontWeight: FontWeight.bold, color: theme.primaryText),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Before using Kronk, please confirm you agree to the following:',
                    style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 14.dp, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 16.dp),
                  Container(
                    padding: EdgeInsets.all(12.dp),
                    decoration: BoxDecoration(color: theme.outline, borderRadius: BorderRadius.circular(8.dp)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zero Tolerance Policy',
                          style: GoogleFonts.quicksand(color: theme.primaryText, fontWeight: FontWeight.bold, fontSize: 14.dp),
                        ),
                        SizedBox(height: 8.dp),
                        Text(
                          '• No hate speech, threats, harassment, or illegal content\n'
                          '• Immediate action for violations, including content removal or bans\n'
                          '• Illegal activity may be reported to authorities',
                          style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 13.dp, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.dp),
                  Text(
                    'You must agree to:',
                    style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 14.dp, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8.dp),
                  Text(
                    '✓ Terms of Service\n'
                    '✓ Privacy Policy\n'
                    '✓ Community Guidelines\n'
                    '✓ Content Moderation Policies',
                    style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 13.5.dp, height: 1.6),
                  ),
                  SizedBox(height: 16.dp),
                  Text(
                    'Violations may result in:',
                    style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 14.dp, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8.dp),
                  Text(
                    '• Content removal\n'
                    '• Account suspension\n'
                    '• Permanent bans\n'
                    '• Legal action (if applicable)',
                    style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 13.5.dp, height: 1.5),
                  ),
                  SizedBox(height: 24.dp),
                  Center(
                    child: Text(
                      'By tapping "I Agree", you confirm that you have read and accepted our policies.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 12.dp, fontStyle: FontStyle.italic),
                    ),
                  ),
                  SizedBox(height: 20.dp),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () async => await customURLLauncher(isWebsite: true, url: 'https://api.kronk.uz/terms'),
                        child: Text(
                          'Terms',
                          style: GoogleFonts.quicksand(fontSize: 14.dp, color: theme.primaryText, decoration: TextDecoration.underline, decorationColor: theme.primaryText),
                        ),
                      ),
                      TextButton(
                        onPressed: () async => await customURLLauncher(isWebsite: true, url: 'https://api.kronk.uz/privacy'),
                        child: Text(
                          'Privacy',
                          style: GoogleFonts.quicksand(fontSize: 14.dp, color: theme.primaryText, decoration: TextDecoration.underline, decorationColor: theme.primaryText),
                        ),
                      ),
                      TextButton(
                        onPressed: () async => await customURLLauncher(isWebsite: true, url: 'https://api.kronk.uz/guidelines'),
                        child: Text(
                          'Guidelines',
                          style: GoogleFonts.quicksand(fontSize: 14.dp, color: theme.primaryText, decoration: TextDecoration.underline, decorationColor: theme.primaryText),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  'Decline',
                  style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16.dp, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(termsAgreementProvider.notifier).state = true;
                  Navigator.of(context).pop();
                  showToast(context, ref, ToastificationType.success, 'Thanks! You can now continue.');
                },
                child: Text(
                  'I Agree',
                  style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
