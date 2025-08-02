import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:shimmer/shimmer.dart';

class FeedVideoShimmerWidget extends ConsumerWidget {
  const FeedVideoShimmerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTheme = ref.watch(themeProvider);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: activeTheme.primaryBackground,
      child: Shimmer.fromColors(
        baseColor: Colors.red,
        highlightColor: activeTheme.primaryText,
        child: const SizedBox(width: double.infinity, height: 200),
      ),
    );
  }
}
