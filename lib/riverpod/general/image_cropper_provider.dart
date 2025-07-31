import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/utility/classes.dart';
import 'package:mime/mime.dart';

final imageCropperNotifierProvider = NotifierProvider<ImageCropperNotifier, ImageCropperState>(ImageCropperNotifier.new);

class ImageCropperNotifier extends Notifier<ImageCropperState> {
  late CropController _cropController;

  @override
  ImageCropperState build() {
    _cropController = CropController();
    return ImageCropperState(cropController: _cropController);
  }

  void updateField({required ImageCropperState imageCropperState}) {
    state = imageCropperState;
  }

  Future<void> uploadImage({required CropImageFor cropImageFor, required int width, required int height}) async {
    try {
      final picker = ImagePicker();
      XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      Uint8List? bytes = await pickedFile.readAsBytes();

      Uint8List? resizedBytes = await resizeAndCompressImage(bytes, width, height);

      final String? mimeType = lookupMimeType(pickedFile.path);
      switch (cropImageFor) {
        case CropImageFor.avatar:
          state = state.copyWith(pickedAvatarName: pickedFile.name, pickedAvatarMimeType: mimeType, pickedAvatarBytes: resizedBytes);
        case CropImageFor.banner:
          state = state.copyWith(pickedBannerName: pickedFile.name, pickedBannerMimeType: mimeType, pickedBannerBytes: resizedBytes);
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<Uint8List> resizeAndCompressImage(Uint8List imageData, int width, int height) async {
    Uint8List compressedImage = await FlutterImageCompress.compressWithList(imageData, minWidth: width, minHeight: height, quality: 100);
    return compressedImage;
  }

  void crop({required CropImageFor cropImageFor}) {
    switch (cropImageFor) {
      case CropImageFor.avatar:
        if (state.pickedAvatarBytes == null) return;
        _cropController.cropCircle();
      case CropImageFor.banner:
        if (state.pickedBannerBytes == null) return;
        _cropController.crop();
    }
  }

  void clear({required CropImageFor cropImageFor}) {
    switch (cropImageFor) {
      case CropImageFor.avatar:
        state = state.copyWith(pickedAvatarBytes: null, croppedAvatarBytes: null);
      case CropImageFor.banner:
        state = state.copyWith(pickedBannerBytes: null, croppedBannerBytes: null);
    }
  }
}
