import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:kronk/models/user_model.dart';
import 'package:kronk/riverpod/general/image_cropper_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/riverpod/general/update_data_provider.dart';
import 'package:kronk/riverpod/profile/profile_provider.dart';
import 'package:kronk/screens/user/profile_screen.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/widgets/custom_appbar.dart';
import 'package:kronk/widgets/date_selector.dart';
import 'package:kronk/widgets/profile/custom_painters.dart';

/// EditProfileScreen
class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    final UserModel? user = ref.watch(sharedUser);
    if (user == null) return const SizedBox.shrink();
    final updateData = ref.watch(updateDataNotifierProvider);
    final ImageCropperState imageCropperState = ref.watch(imageCropperNotifierProvider);

    final double avatarHeight = 96.dp;
    final double avatarRadius = avatarHeight / 2;
    return Scaffold(
      appBar: BaseAppBar(
        appBarHeight: 48.dp,
        bottomHeight: 0,
        bottomGap: 1,
        actionsSpacing: 8.dp,
        appBarPadding: EdgeInsets.only(left: 12.dp, right: 6.dp),
        bottomPadding: EdgeInsets.only(left: 12.dp, right: 12.dp, bottom: 4.dp),
        leading: TextButton(
          onPressed: () => context.pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, fontWeight: FontWeight.w600),
          ),
        ),
        title: Text(
          'Search',
          style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 24.dp, fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => ref.read(profileNotifierProvider(null).notifier).updateProfile(user: user, updateData: updateData, imageCropperState: imageCropperState),
            child: Text(
              'Save',
              style: GoogleFonts.quicksand(color: theme.tertiaryBackground, fontSize: 16.dp, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          spacing: avatarRadius + 12.dp,
          children: [
            /// Banner & avatar
            EditProfileImages(user: user),

            /// Fields
            EditProfileFields(user: user),
          ],
        ),
      ),
    );
  }
}

/// EditProfileImages
class EditProfileImages extends ConsumerWidget {
  final UserModel user;

  const EditProfileImages({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final updateData = ref.watch(updateDataNotifierProvider);
    final ImageCropperState imageCropperState = ref.watch(imageCropperNotifierProvider);

    final double screenWidth = Sizes.screenWidth;
    final bannerHeight = screenWidth * 9 / 20;
    final double avatarHeight = 96.dp;
    final double avatarRadius = 48.dp;

    return DeferredPointerHandler(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          /// Banner
          SizedBox(
            height: bannerHeight,
            width: double.infinity,
            child: GestureDetector(
              onTap: () => context.push('/image_cropper/banner'),
              child: imageCropperState.croppedBannerBytes != null
                  ? Image.memory(
                      imageCropperState.croppedBannerBytes!,
                      width: screenWidth,
                      height: bannerHeight,
                      cacheWidth: screenWidth.cacheSize(context),
                      cacheHeight: bannerHeight.cacheSize(context),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(width: screenWidth, height: bannerHeight, color: theme.secondaryBackground),
                    )
                  : updateData.removeBanner
                  ? Container(width: screenWidth, height: bannerHeight, color: theme.secondaryBackground)
                  : CachedNetworkImage(
                      imageUrl: '${constants.bucketEndpoint}/${user.bannerUrl}',
                      width: screenWidth,
                      height: bannerHeight,
                      memCacheWidth: screenWidth.cacheSize(context),
                      memCacheHeight: bannerHeight.cacheSize(context),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(width: screenWidth, height: bannerHeight, color: theme.secondaryBackground),
                      errorWidget: (context, url, error) => Container(width: screenWidth, height: bannerHeight, color: theme.secondaryBackground),
                    ),
            ),
          ),

          /// Avatar
          Positioned(
            top: bannerHeight - avatarRadius,
            left: 16.dp,
            height: avatarHeight,
            child: CustomPaint(
              painter: AvatarPainter(borderColor: theme.primaryBackground, borderWidth: 8.dp),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(avatarRadius),
                child: DeferPointer(
                  child: GestureDetector(
                    onTap: () => context.push('/image_cropper/avatar'),
                    child: imageCropperState.croppedAvatarBytes != null
                        ? Image.memory(
                            imageCropperState.croppedAvatarBytes!,
                            width: avatarHeight,
                            height: avatarHeight,
                            cacheWidth: avatarHeight.cacheSize(context),
                            cacheHeight: avatarHeight.cacheSize(context),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: avatarHeight,
                              width: avatarHeight,
                              decoration: BoxDecoration(color: theme.secondaryBackground, shape: BoxShape.circle),
                            ),
                          )
                        : updateData.removeAvatar
                        ? Container(
                            width: avatarHeight,
                            height: avatarHeight,
                            decoration: BoxDecoration(color: theme.secondaryBackground, shape: BoxShape.circle),
                          )
                        : CachedNetworkImage(
                            imageUrl: '${constants.bucketEndpoint}/${user.avatarUrl}',
                            width: avatarHeight,
                            height: avatarHeight,
                            memCacheWidth: avatarHeight.cacheSize(context),
                            memCacheHeight: avatarHeight.cacheSize(context),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: avatarHeight,
                              width: avatarHeight,
                              decoration: BoxDecoration(color: theme.secondaryBackground, shape: BoxShape.circle),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: avatarHeight,
                              width: avatarHeight,
                              decoration: BoxDecoration(color: theme.secondaryBackground, shape: BoxShape.circle),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),

          /// Banner delete
          Positioned(
            top: 16.dp,
            right: 16.dp,
            child: GestureDetector(
              onTap: () {
                if (imageCropperState.croppedBannerBytes != null) {
                  ref.read(imageCropperNotifierProvider.notifier).updateField(imageCropperState: imageCropperState.copyWith(croppedBannerBytes: null, pickedBannerBytes: null));
                } else if (user.bannerUrl != null) {
                  ref.read(updateDataNotifierProvider.notifier).updateField(user: updateData.copyWith(removeBanner: !(updateData.removeBanner)));
                } else {
                  context.push('/image_cropper/banner');
                }
              },
              child: Container(
                height: 36.dp,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: theme.primaryBackground, shape: BoxShape.circle),
                child: FittedBox(
                  child: Icon(
                    imageCropperState.croppedBannerBytes != null
                        ? Icons.delete_outline_rounded
                        : user.bannerUrl != null
                        ? (updateData.removeBanner ? Icons.undo_rounded : Icons.delete_outline_rounded)
                        : Icons.add_rounded,
                    color: theme.secondaryText,
                  ),
                ),
              ),
            ),
          ),

          /// Avatar delete
          Positioned(
            left: 16.dp + avatarRadius + (avatarRadius * cos(pi / 4)) - 18.dp,
            bottom: (avatarRadius * sin(pi / 4)) - 18.dp,
            child: DeferPointer(
              child: GestureDetector(
                onTap: () {
                  myLogger.d('Avatar delete');
                  myLogger.d('Avatar croppedAvatarBytes: ${imageCropperState.croppedAvatarBytes?.length}');
                  myLogger.d('Avatar avatarUrl: ${user.avatarUrl}');
                  if (imageCropperState.croppedAvatarBytes != null) {
                    ref.read(imageCropperNotifierProvider.notifier).updateField(imageCropperState: imageCropperState.copyWith(croppedAvatarBytes: null, pickedAvatarBytes: null));
                  } else if (user.avatarUrl != null) {
                    myLogger.i('user.avatarUrl is not null | removeAvatar: ${!(updateData.removeAvatar)}');
                    ref.read(updateDataNotifierProvider.notifier).updateField(user: updateData.copyWith(removeAvatar: !(updateData.removeAvatar)));
                  } else {
                    context.push('/image_cropper/avatar');
                  }
                },
                child: Container(
                  height: 36.dp,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: theme.primaryBackground, shape: BoxShape.circle),
                  child: FittedBox(
                    child: Icon(
                      imageCropperState.croppedAvatarBytes != null
                          ? Icons.delete_outline_rounded
                          : user.avatarUrl != null
                          ? (updateData.removeAvatar ? Icons.undo_rounded : Icons.delete_outline_rounded)
                          : Icons.add_rounded,
                      color: theme.secondaryText,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// EditProfileFields
class EditProfileFields extends ConsumerWidget {
  final UserModel user;

  const EditProfileFields({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateData = ref.watch(updateDataNotifierProvider);
    final updateNotifier = ref.read(updateDataNotifierProvider.notifier);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.dp),
      child: Column(
        spacing: 12.dp,
        children: [
          /// Name
          EditProfileField(
            initialValue: user.name,
            hintText: 'name',
            onChanged: (name) => updateNotifier.updateField(user: updateData.copyWith(name: name)),
            autofillHints: AutofillHints.name,
          ),

          /// Username
          EditProfileField(
            initialValue: user.username,
            hintText: 'username',
            onChanged: (username) => updateNotifier.updateField(user: updateData.copyWith(username: username)),
            autofillHints: AutofillHints.newUsername,
          ),

          /// Email
          EditProfileField(
            initialValue: user.email,
            hintText: 'email',
            onChanged: (email) => updateNotifier.updateField(user: updateData.copyWith(email: email)),
            autofillHints: AutofillHints.email,
          ),

          /// Password
          EditProfileField(
            hintText: 'password',
            onChanged: (password) => updateNotifier.updateField(user: updateData.copyWith(password: password)),
            autofillHints: AutofillHints.newPassword,
          ),

          /// bio
          EditProfileField(
            initialValue: user.bio,
            hintText: 'bio',
            onChanged: (bio) => updateNotifier.updateField(user: updateData.copyWith(bio: bio)),
            isBio: true,
          ),

          /// country
          EditProfileField(
            initialValue: user.country,
            hintText: 'country',
            onChanged: (country) => updateNotifier.updateField(user: updateData.copyWith(country: country)),
            autofillHints: AutofillHints.countryName,
          ),

          /// city
          EditProfileField(
            initialValue: user.city,
            hintText: 'city',
            onChanged: (city) => updateNotifier.updateField(user: updateData.copyWith(city: city)),
            autofillHints: AutofillHints.addressCity,
          ),

          /// birthdate
          DatePicker(
            initialValue: user.birthdate,
            onDatePicked: (DateTime? birthdate) {
              updateNotifier.updateField(user: updateData.copyWith(birthdate: birthdate));
            },
          ),

          /// Bottom gap
          SizedBox(height: 12.dp),
        ],
      ),
    );
  }
}

/// FieldLabel
class FieldLabel extends ConsumerWidget {
  final String label;

  const FieldLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.quicksand(fontSize: 16.dp, color: theme.secondaryText, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

/// EditProfileField
class EditProfileField extends ConsumerStatefulWidget {
  final String? initialValue;
  final String hintText;
  final void Function(String)? onChanged;
  final String? autofillHints;
  final bool isPassword;
  final bool isBio;

  const EditProfileField({super.key, this.initialValue, required this.hintText, required this.onChanged, this.autofillHints, this.isPassword = false, this.isBio = false});

  @override
  ConsumerState<EditProfileField> createState() => _EditProfileFieldState();
}

class _EditProfileFieldState extends ConsumerState<EditProfileField> {
  late TextEditingController _controller;
  bool isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    return Column(
      children: [
        FieldLabel(label: widget.hintText),
        TextFormField(
          controller: _controller,
          style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16.dp, fontWeight: FontWeight.w500),
          cursorColor: theme.primaryText,
          onChanged: widget.onChanged,
          autofillHints: [?widget.autofillHints],
          obscureText: widget.isPassword ? !isPasswordVisible : false,
          maxLines: widget.isBio ? 4 : 1,
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.secondaryBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.dp), borderSide: BorderSide.none),
            hintText: widget.hintText,
            errorText: null,
            errorStyle: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16.dp, fontWeight: FontWeight.w500),
            hintStyle: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16.dp, fontWeight: FontWeight.w500),
            contentPadding: EdgeInsets.all(12.dp),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(isPasswordVisible ? Iconsax.eye_outline : Iconsax.eye_slash_outline, color: theme.secondaryText),
                    onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
