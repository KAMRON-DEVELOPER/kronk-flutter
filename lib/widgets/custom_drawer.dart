import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/models/user_model.dart';
import 'package:kronk/riverpod/general/storage_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/riverpod/profile/profile_provider.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/url_launches.dart';

class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return Drawer(
      width: 280.dp,
      backgroundColor: theme.secondaryBackground,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(children: [DrawerHeader(), DrawerMain()]),

          DrawerFooter(),
        ],
      ),
    );
  }
}

class DrawerHeader extends ConsumerWidget {
  const DrawerHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final user = ref.watch(profileNotifierProvider((null)));
    final storage = ref.watch(storageProvider);

    return user.when(
      data: (data) => DrawerHeaderContent(user: data),
      error: (error, stackTrace) => Container(
        height: 100,
        decoration: BoxDecoration(color: theme.primaryBackground, borderRadius: BorderRadius.circular(12)),
        child: Text(error.toString(), style: GoogleFonts.quicksand(color: Colors.redAccent, fontSize: 12)),
      ),
      loading: () => DrawerHeaderContent(user: storage.getUser()),
    );
  }
}

/// DrawerHeaderContent
class DrawerHeaderContent extends ConsumerWidget {
  final UserModel user;

  const DrawerHeaderContent({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    final double avatarHeight = 96.dp;
    final double avatarRadius = avatarHeight / 2;
    return Container(
      width: double.infinity,
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
  }
}

/// DrawerMain
class DrawerMain extends ConsumerWidget {
  const DrawerMain({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.all(12.dp),
      child: Column(
        spacing: 4.dp,
        children: [
          DrawerMainContent(title: 'Welcome', iconData: Icons.account_tree_rounded, onTap: () {}),
          DrawerMainContent(title: 'Auth', iconData: Icons.login, onTap: () {}),
          DrawerMainContent(title: 'Settings', iconData: Icons.settings_rounded, onTap: () => context.push('/settings')),
        ],
      ),
    );
  }
}

/// DrawerMainContent
class DrawerMainContent extends ConsumerWidget {
  final String title;
  final IconData iconData;
  final void Function()? onTap;

  const DrawerMainContent({super.key, required this.title, required this.iconData, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        spacing: 12.dp,
        children: [
          /// Icon
          Icon(iconData, size: 24.dp),

          /// Title
          Text(
            title,
            style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 20.dp, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// DrawerFooter
class DrawerFooter extends ConsumerWidget {
  const DrawerFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return Padding(
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
    );
  }
}
