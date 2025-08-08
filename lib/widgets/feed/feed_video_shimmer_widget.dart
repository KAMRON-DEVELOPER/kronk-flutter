import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/riverpod/general/screen_style_state_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:shimmer/shimmer.dart';

class FeedVideoShimmerWidget extends ConsumerWidget {
  final double aspectRatio;
  const FeedVideoShimmerWidget({super.key, required this.aspectRatio});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTheme = ref.watch(themeProvider);
    final ScreenStyleState screenStyle = ref.watch(screenStyleStateProvider('feeds'));
    final double videoWidth = Sizes.screenWidth - 40.dp;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: activeTheme.primaryBackground,
      child: Shimmer.fromColors(
        baseColor: Colors.red,
        highlightColor: activeTheme.primaryText.withValues(alpha: screenStyle.opacity),
        child: SizedBox(width: videoWidth, height: videoWidth / aspectRatio),
      ),
    );
  }
}
