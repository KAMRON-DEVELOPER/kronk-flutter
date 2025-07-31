import 'dart:io';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/foundation.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/feed_model.dart';

class VideoOverlayState {
  final bool showPlayPauseOverlay;
  final bool showSkipOverlay;
  final bool skipRight;
  final bool isPlay;
  final bool isCompleted;
  final bool showMuteOverlay;
  final bool fastForward;
  final bool showFastForward;

  VideoOverlayState({
    this.showPlayPauseOverlay = false,
    this.isPlay = false,
    this.showSkipOverlay = false,
    this.skipRight = false,
    this.isCompleted = false,
    this.showMuteOverlay = false,
    this.fastForward = false,
    this.showFastForward = false,
  });

  VideoOverlayState copyWith({
    bool? showPlayPauseOverlay,
    bool? isPlay,
    bool? showSkipOverlay,
    bool? skipRight,
    bool? isCompleted,
    bool? showMuteOverlay,
    bool? fastForward,
    bool? showFastForward,
  }) {
    return VideoOverlayState(
      showPlayPauseOverlay: showPlayPauseOverlay ?? this.showPlayPauseOverlay,
      isPlay: isPlay ?? this.isPlay,
      showSkipOverlay: showSkipOverlay ?? this.showSkipOverlay,
      skipRight: skipRight ?? this.skipRight,
      isCompleted: isCompleted ?? this.isCompleted,
      showMuteOverlay: showMuteOverlay ?? this.showMuteOverlay,
      fastForward: fastForward ?? this.fastForward,
      showFastForward: showFastForward ?? this.showFastForward,
    );
  }
}

class FeedScreenDisplayState {
  final ScreenStyle screenStyle;
  final double cardOpacity;
  final double cardBorderRadius;
  final String backgroundImagePath;

  FeedScreenDisplayState({required this.screenStyle, required this.cardOpacity, required this.cardBorderRadius, required this.backgroundImagePath});

  FeedScreenDisplayState copyWith({ScreenStyle? screenStyle, double? cardOpacity, double? cardBorderRadius, String? backgroundImagePath}) {
    return FeedScreenDisplayState(
      screenStyle: screenStyle ?? this.screenStyle,
      cardOpacity: cardOpacity ?? this.cardOpacity,
      cardBorderRadius: cardBorderRadius ?? this.cardBorderRadius,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
    );
  }

  factory FeedScreenDisplayState.from(
    FeedScreenDisplayState base, {
    ScreenStyle? feedScreenDisplayStyle,
    double? cardOpacity,
    double? cardBorderRadius,
    String? backgroundImagePath,
  }) {
    return FeedScreenDisplayState(
      screenStyle: feedScreenDisplayStyle ?? base.screenStyle,
      cardOpacity: cardOpacity ?? base.cardOpacity,
      cardBorderRadius: cardBorderRadius ?? base.cardBorderRadius,
      backgroundImagePath: backgroundImagePath ?? base.backgroundImagePath,
    );
  }
}

class ChatsScreenDisplayState {
  final ScreenStyle screenStyle;
  final double tileOpacity;
  final double tileBorderRadius;
  final String backgroundImagePath;

  ChatsScreenDisplayState({required this.screenStyle, required this.tileOpacity, required this.tileBorderRadius, required this.backgroundImagePath});

  ChatsScreenDisplayState copyWith({ScreenStyle? screenStyle, double? tileOpacity, double? tileBorderRadius, String? backgroundImagePath}) {
    return ChatsScreenDisplayState(
      screenStyle: screenStyle ?? this.screenStyle,
      tileOpacity: tileOpacity ?? this.tileOpacity,
      tileBorderRadius: tileBorderRadius ?? this.tileBorderRadius,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
    );
  }

  factory ChatsScreenDisplayState.from(ChatsScreenDisplayState base, {ScreenStyle? screenStyle, double? tileOpacity, double? tileBorderRadius, String? backgroundImagePath}) {
    return ChatsScreenDisplayState(
      screenStyle: screenStyle ?? base.screenStyle,
      tileOpacity: tileOpacity ?? base.tileOpacity,
      tileBorderRadius: tileBorderRadius ?? base.tileBorderRadius,
      backgroundImagePath: backgroundImagePath ?? base.backgroundImagePath,
    );
  }
}

class VideoSourceState {
  final String? feedId;
  final String? videoUrl;
  final File? videoFile;

  VideoSourceState({required this.feedId, this.videoUrl, this.videoFile});

  @override
  bool operator ==(Object other) {
    return other is VideoSourceState && other.videoUrl == videoUrl && other.videoFile?.path == videoFile?.path;
  }

  @override
  int get hashCode => Object.hash(videoUrl, videoFile?.path);
}

const _unset = Object();

class ImageCropperState {
  final CropController cropController;
  final String? pickedAvatarName;
  final String? pickedBannerName;
  final String? pickedAvatarMimeType;
  final String? pickedBannerMimeType;
  final Uint8List? pickedAvatarBytes;
  final Uint8List? pickedBannerBytes;
  final Uint8List? croppedAvatarBytes;
  final Uint8List? croppedBannerBytes;

  ImageCropperState({
    required this.cropController,
    this.pickedAvatarName,
    this.pickedBannerName,
    this.pickedAvatarMimeType,
    this.pickedBannerMimeType,
    this.pickedAvatarBytes,
    this.pickedBannerBytes,
    this.croppedAvatarBytes,
    this.croppedBannerBytes,
  });

  ImageCropperState copyWith({
    CropController? cropController,
    Object? pickedAvatarName = _unset,
    Object? pickedBannerName = _unset,
    Object? pickedAvatarMimeType = _unset,
    Object? pickedBannerMimeType = _unset,
    Object? pickedAvatarBytes = _unset,
    Object? pickedBannerBytes = _unset,
    Object? croppedAvatarBytes = _unset,
    Object? croppedBannerBytes = _unset,
  }) {
    return ImageCropperState(
      cropController: cropController ?? this.cropController,
      pickedAvatarName: pickedAvatarName == _unset ? this.pickedAvatarName : pickedAvatarName as String?,
      pickedBannerName: pickedBannerName == _unset ? this.pickedBannerName : pickedBannerName as String?,
      pickedAvatarMimeType: pickedAvatarMimeType == _unset ? this.pickedAvatarMimeType : pickedAvatarMimeType as String?,
      pickedBannerMimeType: pickedBannerMimeType == _unset ? this.pickedBannerMimeType : pickedBannerMimeType as String?,
      pickedAvatarBytes: pickedAvatarBytes == _unset ? this.pickedAvatarBytes : pickedAvatarBytes as Uint8List?,
      pickedBannerBytes: pickedBannerBytes == _unset ? this.pickedBannerBytes : pickedBannerBytes as Uint8List?,
      croppedAvatarBytes: croppedAvatarBytes == _unset ? this.croppedAvatarBytes : croppedAvatarBytes as Uint8List?,
      croppedBannerBytes: croppedBannerBytes == _unset ? this.croppedBannerBytes : croppedBannerBytes as Uint8List?,
    );
  }
}

class FeedCardState {
  final FeedModel feed;
  final FeedMode feedMode;
  final List<String> removeImageTargets;
  final String? removeVideoTarget;

  FeedCardState({required this.feed, this.feedMode = FeedMode.view, this.removeImageTargets = const [], this.removeVideoTarget});
}
