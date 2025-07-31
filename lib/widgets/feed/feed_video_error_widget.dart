import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart';

class FeedVideoErrorWidget extends ConsumerWidget {
  const FeedVideoErrorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SizedBox(height: 300, child: RiveAnimation.asset('assets/animations/error_glitch.riv'));
  }
}
