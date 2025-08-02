import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/riverpod/general/image_cropper_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';

class ImageCropperScreen extends ConsumerWidget {
  final CropImageFor cropImageFor;

  const ImageCropperScreen({super.key, required this.cropImageFor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final ImageCropperState imageCropperState = ref.watch(imageCropperNotifierProvider);

    final double cropAreaWidth = Sizes.screenWidth;
    final double cropAreaHeight = cropImageFor == CropImageFor.avatar ? cropAreaWidth : cropAreaWidth * 9 / 20;
    final double fromViewport = cropImageFor == CropImageFor.avatar ? 24.dp : 0;
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          /// Image editing area
          if ((cropImageFor == CropImageFor.avatar ? imageCropperState.pickedAvatarBytes : imageCropperState.pickedBannerBytes) != null)
            Container(
              width: cropAreaWidth,
              height: cropAreaHeight,
              decoration: BoxDecoration(border: Border.all(color: theme.outline, width: 1)),
              child: Crop(
                controller: imageCropperState.cropController,
                image: cropImageFor == CropImageFor.avatar ? imageCropperState.pickedAvatarBytes! : imageCropperState.pickedBannerBytes!,
                aspectRatio: cropImageFor == CropImageFor.avatar ? 1 : 3 / 8,
                interactive: true,
                fixCropRect: true,
                radius: cropImageFor == CropImageFor.avatar ? (cropAreaWidth - 2 * 24.dp) / 2 : 0,
                baseColor: Colors.black87,
                maskColor: Colors.white.withValues(alpha: 0.3),
                onCropped: (CropResult cropResult) {
                  switch (cropResult) {
                    case CropSuccess(:final croppedImage):
                      switch (cropImageFor) {
                        case CropImageFor.avatar:
                          ref.read(imageCropperNotifierProvider.notifier).updateField(imageCropperState: imageCropperState.copyWith(croppedAvatarBytes: croppedImage));
                        case CropImageFor.banner:
                          ref.read(imageCropperNotifierProvider.notifier).updateField(imageCropperState: imageCropperState.copyWith(croppedBannerBytes: croppedImage));
                      }
                      // Safely pop after update
                      WidgetsBinding.instance.addPostFrameCallback((_) => context.pop());
                    case CropFailure():
                      return;
                  }
                },
                initialRectBuilder: InitialRectBuilder.withBuilder((Rect viewportRect, Rect imageRect) {
                  return Rect.fromLTRB(viewportRect.left + fromViewport, viewportRect.top + fromViewport, viewportRect.right - fromViewport, viewportRect.bottom - fromViewport);
                }),
                cornerDotBuilder: (size, edgeAlignment) => Container(color: Colors.transparent),
                progressIndicator: const CircularProgressIndicator(),
              ),
            )
          else
            Container(
              width: cropAreaWidth,
              height: cropAreaHeight,
              decoration: BoxDecoration(
                color: Colors.black54,
                border: Border.all(color: Colors.deepOrange, width: 1),
              ),
              child: const Icon(Iconsax.document_upload_bold, size: 64),
            ),

          /// Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if ((cropImageFor == CropImageFor.avatar ? imageCropperState.pickedAvatarBytes : imageCropperState.pickedBannerBytes) == null)
                MaterialButton(
                  onPressed: () => context.pop(),
                  color: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  child: const Text('Cancel'),
                )
              else
                MaterialButton(
                  onPressed: () => ref.read(imageCropperNotifierProvider.notifier).clear(cropImageFor: cropImageFor),
                  color: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  child: const Text('Clear'),
                ),
              if ((cropImageFor == CropImageFor.avatar ? imageCropperState.pickedAvatarBytes : imageCropperState.pickedBannerBytes) == null)
                MaterialButton(
                  onPressed: () => ref
                      .read(imageCropperNotifierProvider.notifier)
                      .uploadImage(cropImageFor: cropImageFor, width: cropAreaWidth.cacheSize(context), height: cropAreaHeight.cacheSize(context)),
                  color: Colors.greenAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  child: const Text('Upload'),
                )
              else
                MaterialButton(
                  onPressed: () => ref.read(imageCropperNotifierProvider.notifier).crop(cropImageFor: cropImageFor),
                  color: Colors.greenAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  child: const Text('Done'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
