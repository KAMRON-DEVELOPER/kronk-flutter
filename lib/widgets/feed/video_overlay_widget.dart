import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/riverpod/general/video_overlay_provider.dart';

class VideoOverlayWidget extends ConsumerWidget {
  final String? feedId;

  const VideoOverlayWidget({super.key, required this.feedId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlayState = ref.watch(videoOverlayStateProvider(feedId));
    final activeTheme = ref.watch(themeNotifierProvider);
    final iconColor = activeTheme.primaryText.withValues(alpha: 0.75);

    return Stack(
      children: [
        /// Play & Pause
        if (overlayState.showPlayPauseOverlay) CenterIconAnimation(feedId: feedId),
        if (overlayState.isCompleted) Icon(Icons.play_arrow_rounded, size: 48, color: iconColor),

        /// Skip
        if (overlayState.showSkipOverlay)
          Align(
            alignment: overlayState.skipRight ? Alignment.centerRight : Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!overlayState.skipRight) Icon(Icons.replay_5_rounded, size: 48, color: iconColor),
                  if (overlayState.skipRight) Icon(Icons.forward_5_rounded, size: 48, color: iconColor),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// CenterIconAnimation
class CenterIconAnimation extends ConsumerStatefulWidget {
  final String? feedId;

  const CenterIconAnimation({super.key, required this.feedId});

  @override
  ConsumerState<CenterIconAnimation> createState() => _CenterIconAnimationState();
}

class _CenterIconAnimationState extends ConsumerState<CenterIconAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _scale = Tween(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = ref.watch(themeNotifierProvider);
    final iconColor = activeTheme.secondaryText;
    final overlayState = ref.watch(videoOverlayStateProvider(widget.feedId));
    return ScaleTransition(
      scale: _scale,
      child: Icon(overlayState.isPlay ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 64, color: iconColor),
    );
  }
}
