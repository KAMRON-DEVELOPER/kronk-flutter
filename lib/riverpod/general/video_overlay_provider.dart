import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/utility/classes.dart';

final videoOverlayStateProvider = AutoDisposeNotifierProviderFamily<VideoOverlayController, VideoOverlayState, String?>(() => VideoOverlayController());

class VideoOverlayController extends AutoDisposeFamilyNotifier<VideoOverlayState, String?> {
  Timer? _timer;

  @override
  VideoOverlayState build(String? initialChat) {
    ref.onDispose(() => _timer?.cancel());

    return VideoOverlayState();
  }

  void showPlayPause({required bool isPlaying}) {
    _timer?.cancel();
    state = state.copyWith(showPlayPauseOverlay: true, isPlay: isPlaying);
    _timer = Timer(const Duration(milliseconds: 500), () {
      state = state.copyWith(showPlayPauseOverlay: false, isCompleted: false);
    });
  }

  void showSkipOverlay({required bool right}) {
    _timer?.cancel();
    state = state.copyWith(showSkipOverlay: true, skipRight: right);
    _timer = Timer(const Duration(milliseconds: 500), () {
      state = state.copyWith(showSkipOverlay: false);
    });
  }

  void showMute({required bool isMuted}) {
    state = state.copyWith(showMuteOverlay: isMuted);
  }

  void showFast({required bool showFastForward, required bool forward}) {
    state = state.copyWith(showFastForward: showFastForward, fastForward: forward);
  }

  void whenCompleted() {
    state = state.copyWith(isCompleted: true);
  }
}
