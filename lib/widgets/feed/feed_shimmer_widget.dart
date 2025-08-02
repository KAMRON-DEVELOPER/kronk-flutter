import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:shimmer/shimmer.dart';

class FeedShimmerWidget extends StatelessWidget {
  const FeedShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemBuilder: (context, index) => const FeedShimmerCard(),
      separatorBuilder: (context, index) => SizedBox(height: 8.dp),
    );
  }
}

class FeedShimmerCard extends ConsumerWidget {
  const FeedShimmerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTheme = ref.watch(themeProvider);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: activeTheme.primaryBackground.withValues(alpha: 0.5),
      child: Padding(
        padding: EdgeInsets.all(4.dp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header skeleton
            Row(
              children: [
                Shimmer.fromColors(
                  baseColor: activeTheme.secondaryBackground,
                  highlightColor: activeTheme.primaryText.withValues(alpha: 0.1),
                  child: const CircleAvatar(radius: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      2,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Shimmer.fromColors(
                          baseColor: activeTheme.secondaryBackground,
                          highlightColor: activeTheme.primaryText.withValues(alpha: 0.1),
                          child: Container(
                            width: double.infinity,
                            height: 8,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            /// Body text skeleton
            Shimmer.fromColors(
              baseColor: activeTheme.secondaryBackground,
              highlightColor: activeTheme.primaryText.withValues(alpha: 0.1),
              child: Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 8),
            Shimmer.fromColors(
              baseColor: activeTheme.secondaryBackground,
              highlightColor: activeTheme.primaryText.withValues(alpha: 0.1),
              child: Container(
                height: 12,
                width: MediaQuery.of(context).size.width * 0.6,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 12),

            /// Optional image skeleton
            Shimmer.fromColors(
              baseColor: activeTheme.secondaryBackground,
              highlightColor: activeTheme.primaryText.withValues(alpha: 0.1),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            /// Interaction row skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                3,
                (_) => Shimmer.fromColors(
                  baseColor: activeTheme.secondaryBackground,
                  highlightColor: activeTheme.primaryText.withValues(alpha: 0.1),
                  child: Container(height: 24, width: 60, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
