import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/riverpod/general/video_overlay_provider.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:video_player/video_player.dart';

final videoControllerProvider = AutoDisposeAsyncNotifierProviderFamily<VideoControllerNotifier, VideoPlayerController, VideoSourceState>(VideoControllerNotifier.new);

class VideoControllerNotifier extends AutoDisposeFamilyAsyncNotifier<VideoPlayerController, VideoSourceState> {
  late final VoidCallback _controllerListener;
  late final VideoSourceState _videoSource;

  @override
  Future<VideoPlayerController> build(VideoSourceState videoSource) async {
    myLogger.d('videoSource.videoUrl: ${videoSource.videoUrl}');
    _videoSource = videoSource;
    final url = '${constants.bucketEndpoint}/${videoSource.videoUrl}';
    final controller = videoSource.videoUrl != null ? VideoPlayerController.networkUrl(Uri.parse(url)) : VideoPlayerController.file(videoSource.videoFile!);

    await controller.initialize();

    _controllerListener = () {
      if (controller.value.position >= controller.value.duration - const Duration(milliseconds: 500)) {
        ref.read(videoOverlayStateProvider(_videoSource.feedId).notifier).whenCompleted();
      }
    };

    ref.onDispose(() {
      controller.removeListener(_controllerListener);
      controller.dispose();
    });

    controller.addListener(_controllerListener);

    return controller;
  }

  Future<void> togglePlayPause() async {
    final VideoPlayerController? controller = state.value;
    if (controller == null) return;
    final bool isPlaying = controller.value.isPlaying;

    if (isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }

    // Explicitly trigger state refresh
    state = AsyncData(controller);

    // Trigger overlay provider here directly
    ref.read(videoOverlayStateProvider(_videoSource.feedId).notifier).showPlayPause(isPlaying: isPlaying);
  }

  Future<void> seekTo({required Duration duration, backward = false}) async {
    final VideoPlayerController? controller = state.value;
    if (controller == null) return;
    final Duration? currentPosition = await controller.position;
    if (currentPosition == null) return;

    final newPosition = backward ? currentPosition - duration : currentPosition + duration;
    final maxPosition = controller.value.duration;
    final clampedPosition = newPosition < Duration.zero ? Duration.zero : (newPosition > maxPosition ? maxPosition : newPosition);

    await controller.seekTo(clampedPosition);
    await controller.play();

    // Explicitly trigger state refresh
    state = AsyncData(controller);

    // Trigger overlay provider here directly
    ref.read(videoOverlayStateProvider(_videoSource.feedId).notifier).showSkipOverlay(right: !backward);
  }

  Future<void> toggleMute() async {
    final controller = state.value;
    if (controller == null) return;
    await controller.setVolume(controller.value.volume == 0 ? 1 : 0);

    // Explicitly trigger state refresh
    state = AsyncData(controller);

    ref.read(videoOverlayStateProvider(_videoSource.feedId).notifier).showMute(isMuted: controller.value.volume == 0 ? true : false);
  }

  Future<void> startFastForward() async {
    final controller = state.value;
    if (controller == null) return;
    await controller.setPlaybackSpeed(2);

    // Explicitly trigger state refresh
    state = AsyncData(controller);

    ref.read(videoOverlayStateProvider(_videoSource.feedId).notifier).showFast(showFastForward: true, forward: true);
  }

  Future<void> stopFastForward() async {
    final controller = state.value;
    if (controller == null) return;
    await controller.setPlaybackSpeed(1);

    // Explicitly trigger state refresh
    state = AsyncData(controller);

    ref.read(videoOverlayStateProvider(_videoSource.feedId).notifier).showFast(showFastForward: false, forward: true);
  }
}
