import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/models/user_model.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/riverpod/profile/profile_provider.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/url_launches.dart';

class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    return Drawer(
      width: 280.dp,
      backgroundColor: theme.secondaryBackground,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            /// Top Section: Profile + Options
            children: [ProfileDrawerWidget(), OptionsWidget()],
          ),

          /// Bottom Section: Links + Version
          Padding(
            padding: EdgeInsets.all(12.dp),
            child: Column(
              spacing: 8.dp,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await customURLLauncher(isWebsite: true, url: 'https://api.kronk.uz/privacy');
                      },
                      child: Text(
                        'Privacy Policy',
                        style: GoogleFonts.quicksand(
                          color: theme.primaryText,
                          fontSize: 14.dp,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: theme.primaryText,
                          decorationThickness: 1,
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: () async {
                        await customURLLauncher(isWebsite: true, url: 'https://api.kronk.uz/terms');
                      },
                      child: Text(
                        'Terms of Service',
                        style: GoogleFonts.quicksand(
                          color: theme.primaryText,
                          fontSize: 14.dp,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: theme.primaryText,
                          decorationThickness: 1,
                        ),
                      ),
                    ),
                  ],
                ),

                Text(
                  'version: 1.0.0 (beta)',
                  style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 14.dp, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileDrawerWidget extends ConsumerWidget {
  const ProfileDrawerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    final AsyncValue<UserModel?> asyncUser = ref.watch(profileNotifierProvider((null)));

    final double avatarHeight = 96.dp;
    final double avatarRadius = avatarHeight / 2;
    return asyncUser.when(
      data: (UserModel? user) {
        if (user == null) return const SizedBox.shrink();
        return Container(
          width: 280.dp,
          padding: EdgeInsets.only(left: 12.dp, top: MediaQuery.of(context).padding.top + 12.dp, bottom: 12.dp),
          decoration: BoxDecoration(color: theme.primaryBackground),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(avatarRadius),
                child: CachedNetworkImage(
                  imageUrl: '${constants.bucketEndpoint}/${user.avatarUrl}',
                  width: avatarHeight,
                  height: avatarHeight,
                  memCacheWidth: avatarHeight.cacheSize(context),
                  memCacheHeight: avatarHeight.cacheSize(context),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: avatarHeight,
                    decoration: BoxDecoration(color: theme.secondaryBackground, shape: BoxShape.circle),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: avatarHeight,
                    decoration: BoxDecoration(color: theme.secondaryBackground, shape: BoxShape.circle),
                  ),
                ),
              ),

              /// Name
              Text(
                user.name,
                style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, fontWeight: FontWeight.w500),
              ),

              /// Username
              Text(
                '@${user.username}',
                style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 12.dp, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      },
      error: (error, stackTrace) => Container(
        height: 100,
        decoration: BoxDecoration(color: theme.primaryBackground, borderRadius: BorderRadius.circular(12)),
        child: Text(error.toString(), style: GoogleFonts.quicksand(color: Colors.redAccent, fontSize: 12)),
      ),
      loading: () => Container(
        height: 100,
        decoration: BoxDecoration(color: theme.primaryBackground, borderRadius: BorderRadius.circular(12)),
        child: CircularProgressIndicator(color: theme.primaryText, constraints: const BoxConstraints(maxHeight: 50, maxWidth: 50)),
      ),
    );
  }
}

class OptionsWidget extends ConsumerWidget {
  const OptionsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.all(12.dp),
      child: const Column(children: [OptionWidget()]),
    );
  }
}

/// OptionWidget
class OptionWidget extends ConsumerWidget {
  const OptionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    return GestureDetector(
      onTap: () => context.push('/settings'),
      child: Row(
        spacing: 12.dp,
        children: [
          /// Icon
          const Icon(Icons.settings_rounded, size: 24),

          /// Title
          Text(
            'Settings',
            style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 20.dp, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
