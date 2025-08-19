import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/constants/kronk_icon.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/models/feed_model.dart';
import 'package:kronk/riverpod/feed/feed_card_state_provider.dart';
import 'package:kronk/riverpod/feed/timeline_provider.dart';
import 'package:kronk/riverpod/general/screen_style_state_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/riverpod/general/video_controller_provider.dart';
import 'package:kronk/screens/feed/feeds_screen.dart';
import 'package:kronk/services/api_service/feed_service.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/storage.dart';
import 'package:kronk/widgets/feed/feed_video_error_widget.dart';
import 'package:kronk/widgets/feed/feed_video_shimmer_widget.dart';
import 'package:kronk/widgets/feed/video_overlay_widget.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:mime/mime.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// FeedCard
class FeedCard extends ConsumerStatefulWidget {
  final FeedModel initialFeed;
  final bool isRefreshing;

  const FeedCard({super.key, required this.initialFeed, required this.isRefreshing});

  @override
  ConsumerState<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends ConsumerState<FeedCard> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = ref.watch(themeProvider);
    final FeedModel feed = ref.watch(feedCardStateProvider(widget.initialFeed));
    final FeedCardStateNotifier notifier = ref.read(feedCardStateProvider(widget.initialFeed).notifier);

    final ScreenStyleState screenStyle = ref.watch(screenStyleStateProvider('feeds'));
    final bool isFloating = screenStyle.layoutStyle == LayoutStyle.floating;
    final bool isEditable = feed.feedMode == FeedMode.create || feed.feedMode == FeedMode.update;
    return VisibilityDetector(
      key: ValueKey('1-${feed.id}'),
      onVisibilityChanged: (info) async => await notifier.onVisibilityChanged(info: info),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.all(0),
        color: theme.primaryBackground.withValues(alpha: screenStyle.opacity),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isFloating ? screenStyle.borderRadius : 0),
          side: isFloating ? BorderSide(color: theme.secondaryBackground, width: 0.5) : BorderSide.none,
        ),
        child: Padding(
          padding: EdgeInsets.all(8.dp),
          child: Column(
            spacing: 8.dp,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FeedHeaderSection(feed: feed, notifier: notifier, isRefreshing: widget.isRefreshing),
              FeedBodySection(feed: feed, notifier: notifier),
              FeedMediaSection(feed: feed, notifier: notifier, isRefreshing: widget.isRefreshing),
              if (isEditable) FeedControl(initialFeed: widget.initialFeed),
              FeedActionSection(feed: feed, notifier: notifier),
            ],
          ),
        ),
      ),
    );
  }
}

/// FeedHeaderSection
class FeedHeaderSection extends ConsumerWidget {
  final FeedModel feed;
  final bool isRefreshing;
  final FeedCardStateNotifier notifier;

  const FeedHeaderSection({super.key, required this.feed, required this.isRefreshing, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    double blurSigma = isRefreshing ? 3 : 0;

    final String? avatarUrl = feed.author.avatarUrl;
    final bool isEditable = feed.feedMode == FeedMode.create || feed.feedMode == FeedMode.update;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Left side items (avatar + name + time)
        Expanded(
          child: Row(
            spacing: 8.dp,
            children: [
              /// Avatar
              GestureDetector(
                onTap: () {
                  final Storage storage = Storage();
                  final user = storage.getUser();
                  if (user.id == feed.author.id) {
                    context.go('/profile');
                  } else {
                    context.pushNamed('previewProfile', extra: feed.author.id);
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.dp),
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                    child: CachedNetworkImage(
                      imageUrl: '${constants.bucketEndpoint}/$avatarUrl',
                      fit: BoxFit.cover,
                      width: 32.dp,
                      memCacheWidth: 32.cacheSize(context),
                      placeholder: (context, url) => Icon(Icons.account_circle_rounded, size: 32.dp, color: theme.primaryText),
                      errorWidget: (context, url, error) => Icon(Icons.account_circle_rounded, size: 32.dp, color: theme.primaryText),
                    ),
                  ),
                ),
              ),

              /// Name
              Flexible(
                child: Text(
                  '${feed.author.name}',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, fontWeight: FontWeight.w600),
                ),
              ),

              /// timeAgoShort
              if (!isEditable)
                Text(
                  FeedModel.timeAgoShort(dateTime: feed.createdAt!),
                  style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16.dp, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),

        /// FeedCardMenuButton
        FeedCardThreeDotsButton(feed: feed, notifier: notifier),
      ],
    );
  }
}

/// FeedBodySection
class FeedBodySection extends ConsumerWidget {
  final FeedModel feed;
  final FeedCardStateNotifier notifier;

  const FeedBodySection({super.key, required this.feed, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final bool isEditable = feed.feedMode == FeedMode.create || feed.feedMode == FeedMode.update;

    if (isEditable) {
      return FeedBodyInputWidget(feed: feed, notifier: notifier);
    }
    return Text(
      feed.body!,
      style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, fontWeight: FontWeight.w600),
    );
  }
}

/// FeedBodyInputWidget
class FeedBodyInputWidget extends ConsumerStatefulWidget {
  final FeedModel feed;
  final FeedCardStateNotifier notifier;

  const FeedBodyInputWidget({super.key, required this.feed, required this.notifier});

  @override
  ConsumerState<FeedBodyInputWidget> createState() => _FeedBodyInputWidgetState();
}

class _FeedBodyInputWidgetState extends ConsumerState<FeedBodyInputWidget> {
  late TextEditingController textEditingController;

  @override
  void initState() {
    super.initState();
    textEditingController = TextEditingController(text: widget.feed.body);
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    return TextField(
      controller: textEditingController,
      style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: "What's on your mind?",
        hintStyle: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16.dp, fontWeight: FontWeight.w600),
        border: InputBorder.none,
        counter: null,
        counterStyle: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 12.dp),
      ),
      maxLength: 300,
      minLines: 1,
      maxLines: 6,
      cursorColor: theme.primaryText,
      onChanged: (value) {
        widget.notifier.updateField(feed: widget.feed.copyWith(body: value));
      },
    );
  }
}

/// FeedCardThreeDotsButton
class FeedCardThreeDotsButton extends ConsumerWidget {
  final FeedModel feed;
  final FeedCardStateNotifier notifier;

  const FeedCardThreeDotsButton({super.key, required this.feed, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final int tabIndex = ref.watch(feedsScreenTabIndexProvider);
    return GestureDetector(
      child: Icon(Icons.more_vert_rounded, color: feed.feedMode == FeedMode.view ? theme.primaryText : theme.secondaryText, size: 24.dp),
      onTap: () {
        if (feed.feedMode != FeedMode.view) return;
        final storage = Storage();
        final user = storage.getUser();
        if (feed.feedMode == FeedMode.create) return;

        if (feed.author.id == user.id) {
          showModalBottomSheet(
            context: context,
            backgroundColor: theme.secondaryBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12.dp))),
            builder: (context) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    splashColor: Colors.red,
                    iconColor: theme.primaryText,
                    titleTextStyle: GoogleFonts.quicksand(color: theme.primaryText),
                    subtitleTextStyle: GoogleFonts.quicksand(color: theme.primaryText),
                    leading: const Icon(Icons.edit_rounded),
                    title: const Text('Edit'),
                    // subtitle: const Text('subtitle'),
                    onTap: () {
                      notifier.updateField(feed: feed.copyWith(feedMode: FeedMode.update));
                      context.pop();
                    },
                  ),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    iconColor: theme.primaryText,
                    titleTextStyle: GoogleFonts.quicksand(color: theme.primaryText),
                    subtitleTextStyle: GoogleFonts.quicksand(color: theme.primaryText),
                    leading: const Icon(Icons.delete_outline_rounded),
                    title: const Text('Delete'),
                    // subtitle: const Text('subtitle'),
                    onTap: () async {
                      final communityServices = FeedService();
                      try {
                        final bool ok = await communityServices.fetchDeleteFeed(feedId: feed.id);
                        myLogger.d('ok: $ok');
                        if (ok) {
                          final timelineType = switch (tabIndex) {
                            0 => TimelineType.discover,
                            1 => TimelineType.following,
                            _ => TimelineType.discover,
                          };
                          ref.read(timelineNotifierProvider(timelineType).notifier).refresh(timelineType: timelineType);
                        }
                        if (!context.mounted) return;
                        context.pop();
                      } catch (error) {
                        String errorMessage;
                        if (error is List) {
                          errorMessage = error.join(', ');
                        } else if (error is Exception && error.toString().startsWith('Exception: [')) {
                          // Extract inner list string from Exception string: "Exception: [msg1, msg2]"
                          errorMessage = error.toString().replaceFirst('Exception: [', '').replaceFirst(']', '');
                        } else {
                          errorMessage = error.toString();
                        }

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: theme.tertiaryBackground,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.dp)),
                            content: Text(errorMessage, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.redAccent)),
                          ),
                        );
                      }
                    },
                  ),
                ],
              );
            },
          );
        } else {
          final future = Future.wait([notifier.blockUserStatus(blockedId: feed.author.id), notifier.reportStatuses(feedId: feed.id)]);
          showModalBottomSheet(
            context: context,
            backgroundColor: theme.secondaryBackground,
            isScrollControlled: true,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12.dp))),
            builder: (context) {
              return Padding(
                padding: MediaQuery.of(context).viewInsets,
                child: FutureBuilder(
                  future: future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return BlockUserAndReportWidget(
                        isBlocked: false,
                        isSymmetrical: false,
                        reportStatus: {
                          'copyright_infringement': false,
                          'spam': false,
                          'nudity_or_sexual_content': false,
                          'misinformation': false,
                          'harassment_or_bullying': false,
                          'hate_speech': false,
                          'violence_or_threats': false,
                          'self_harm_or_suicide': false,
                          'impersonation': false,
                          'other': false,
                        },
                        authorId: feed.author.id,
                        feedId: feed.id,
                        notifier: notifier,
                      );
                    }

                    if (snapshot.hasError) {
                      return ListTile(title: const Text('Error loading options'), subtitle: Text(snapshot.error.toString()));
                    }

                    final blockStatus = snapshot.data![0];
                    final reportStatus = snapshot.data![1];

                    final bool isBlocked = blockStatus['blocked'] ?? false;
                    final bool isSymmetrical = blockStatus['symmetrical'] ?? false;

                    return BlockUserAndReportWidget(
                      isBlocked: isBlocked,
                      isSymmetrical: isSymmetrical,
                      reportStatus: reportStatus,
                      authorId: feed.author.id,
                      feedId: feed.id,
                      notifier: notifier,
                    );
                  },
                ),
              );
            },
          );
        }
      },
    );
  }
}

/// BlockUserAndReportWidget
class BlockUserAndReportWidget extends ConsumerWidget {
  final bool isBlocked;
  final bool isSymmetrical;
  final Map<String, bool> reportStatus;
  final String? authorId;
  final String? feedId;
  final FeedCardStateNotifier notifier;

  const BlockUserAndReportWidget({
    super.key,
    required this.isBlocked,
    required this.isSymmetrical,
    required this.reportStatus,
    required this.authorId,
    required this.feedId,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(isBlocked ? Icons.block : Icons.block_outlined, size: 16.dp, color: isBlocked || isSymmetrical ? theme.primaryText : theme.secondaryText),
              title: Text(
                isBlocked ? 'Unblock user' : 'Block user',
                style: GoogleFonts.quicksand(color: isBlocked ? theme.primaryText : theme.secondaryText, fontSize: 16.dp),
              ),
              subtitle: isBlocked && isSymmetrical
                  ? Text(
                      'You both blocked each other',
                      style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 12.dp),
                    )
                  : isBlocked
                  ? Text(
                      'You blocked this user',
                      style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 12.dp),
                    )
                  : null,
              onTap: () async {
                await notifier.toggleBlockUser(blockedId: authorId, symmetrical: isSymmetrical);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            Divider(color: theme.outline),
            ...reportStatus.entries.map((entry) {
              final reason = entry.key;
              final isReported = entry.value;
              return CheckboxListTile(
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                checkColor: theme.primaryText,
                activeColor: theme.secondaryText,
                side: BorderSide(color: theme.secondaryText),
                title: Text(
                  reason.replaceAll('_', ' ').capitalize(),
                  style: GoogleFonts.quicksand(color: isReported ? theme.primaryText : theme.secondaryText, fontSize: 16.dp),
                ),
                value: isReported,
                onChanged: (_) async {
                  await notifier.toggleReport(feedId: feedId, reportReason: ReportReason.values.byName(reason));
                  if (context.mounted) Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// FeedMediaSection
class FeedMediaSection extends ConsumerWidget {
  final FeedModel feed;
  final FeedCardStateNotifier notifier;
  final bool isRefreshing;

  const FeedMediaSection({super.key, required this.feed, required this.isRefreshing, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isEditable = feed.feedMode == FeedMode.create || feed.feedMode == FeedMode.update;
    final showVideo = feed.videoFile != null ? true : feed.videoUrl != null && !feed.removeVideo;
    final bool showImage = feed.imageFile != null ? true : feed.imageUrl != null && !feed.removeImage;

    if (showVideo) return FeedVideoWidget(feed: feed, isRefreshing: isRefreshing, notifier: notifier);
    if (showImage) return FeedImageWidget(feed: feed, isRefreshing: isRefreshing, notifier: notifier);
    if (isEditable) return AddMediaWidget(feed: feed, notifier: notifier);
    return const SizedBox.shrink();
  }
}

/// FeedVideoWidget
class FeedVideoWidget extends ConsumerWidget {
  final FeedModel feed;
  final bool isRefreshing;
  final FeedCardStateNotifier notifier;

  const FeedVideoWidget({super.key, required this.feed, required this.isRefreshing, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final VideoSourceState videoSourceState = VideoSourceState(feedId: feed.id, videoUrl: feed.videoUrl, videoFile: feed.videoFile);
    final videoController = ref.watch(videoControllerProvider(videoSourceState));
    final videoControllerNotifier = ref.read(videoControllerProvider(videoSourceState).notifier);

    final bool isEditable = feed.feedMode == FeedMode.create || feed.feedMode == FeedMode.update;
    double blurSigma = isRefreshing ? 3 : 0;

    final videoAspectRatio = feed.videoAspectRatio!;
    final isTall = videoAspectRatio < 0.8;
    final aspectRatio = isTall ? 0.8 : videoAspectRatio;

    return videoController.when(
      data: (VideoPlayerController controller) => Stack(
        alignment: Alignment.center,
        children: [
          /// Actual Video
          ClipRRect(
            borderRadius: BorderRadius.circular(10.dp),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: isTall
                    ? FittedBox(
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.center,
                        child: SizedBox(width: controller.value.size.width, height: controller.value.size.height, child: VideoPlayer(controller)),
                      )
                    : VideoPlayer(controller),
              ),
            ),
          ),

          /// Animated icons layer
          VideoOverlayWidget(feedId: feed.id),

          /// Gesture handling layer
          Positioned.fill(
            child: Row(
              children: [
                /// Left double tap
                Expanded(
                  child: GestureDetector(
                    onTap: () async => await videoControllerNotifier.togglePlayPause(),
                    onLongPressStart: (details) async => await videoControllerNotifier.startFastForward(),
                    onLongPressEnd: (details) async => await videoControllerNotifier.stopFastForward(),
                    onDoubleTap: () async => await videoControllerNotifier.seekTo(duration: const Duration(seconds: 5), backward: true),
                  ),
                ),

                /// Right double tap
                Expanded(
                  child: GestureDetector(
                    onTap: () async => await videoControllerNotifier.togglePlayPause(),
                    onLongPressStart: (details) async => await videoControllerNotifier.startFastForward(),
                    onLongPressEnd: (details) async => await videoControllerNotifier.stopFastForward(),
                    onDoubleTap: () async => await videoControllerNotifier.seekTo(duration: const Duration(seconds: 5)),
                  ),
                ),
              ],
            ),
          ),

          /// Mute Button and video duration
          Positioned(
            bottom: 8,
            right: 8,
            child: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, VideoPlayerValue value, child) {
                String formatDuration(Duration d) {
                  final minutes = d.inMinutes.toString().padLeft(2, '0');
                  final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
                  return '$minutes:$seconds';
                }

                final positionText = formatDuration(value.position);
                final totalText = formatDuration(controller.value.duration);
                final durationText = '$positionText/$totalText';

                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.dp, vertical: 2.dp),
                  decoration: BoxDecoration(color: theme.primaryBackground.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    spacing: 8.dp,
                    children: [
                      Text(
                        durationText,
                        style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 12.dp),
                      ),
                      GestureDetector(
                        child: Icon(controller.value.volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: theme.secondaryText),
                        onTap: () async => await videoControllerNotifier.toggleMute(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          /// Delete button
          if (isEditable)
            Positioned(
              top: 8.dp,
              right: 8.dp,
              child: GestureDetector(
                onTap: () {
                  if (feed.videoFile != null) {
                    notifier.updateField(feed: feed.copyWith(videoFile: null, videoUrl: null));
                  } else {
                    notifier.updateField(feed: feed.copyWith(removeVideo: true));
                  }
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(color: theme.primaryBackground.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12.dp)),
                  child: Icon(Icons.close_rounded, color: theme.secondaryText, size: 24.dp),
                ),
              ),
            ),
        ],
      ),
      loading: () => AspectRatio(aspectRatio: aspectRatio, child: const FeedVideoShimmerWidget()),
      error: (error, _) {
        myLogger.e('error: $error');
        return const FeedVideoErrorWidget();
      },
    );
  }
}

/// FeedImageWidget
class FeedImageWidget extends ConsumerWidget {
  final FeedModel feed;
  final bool isRefreshing;
  final FeedCardStateNotifier notifier;

  const FeedImageWidget({super.key, required this.feed, required this.isRefreshing, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MyTheme theme = ref.watch(themeProvider);

    final bool isEditable = feed.feedMode == FeedMode.create || feed.feedMode == FeedMode.update;
    double blurSigma = isRefreshing ? 3 : 0;
    final double imageWidth = Sizes.screenWidth - 40.dp;

    final imageUrl = '${constants.bucketEndpoint}/${feed.imageUrl}';
    final imageAspectRatio = feed.imageAspectRatio!;
    final isTall = imageAspectRatio < 0.8;
    final aspectRatio = isTall ? 0.8 : imageAspectRatio;
    return Stack(
      children: [
        /// Actual image
        ClipRRect(
          borderRadius: BorderRadius.circular(10.dp),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: feed.removeImage || feed.imageFile != null
                ? Image.file(feed.imageFile!, width: imageWidth, cacheWidth: imageWidth.cacheSize(context))
                : SizedBox(
                    width: imageWidth,
                    height: imageWidth / aspectRatio,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      memCacheHeight: (imageWidth / aspectRatio).cacheSize(context),
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.topCenter,
                      placeholder: (context, url) => DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8.dp),
                          border: Border.all(color: theme.outline),
                        ),
                      ),
                      errorWidget: (context, url, error) => DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8.dp),
                          border: Border.all(color: theme.outline),
                        ),
                      ),
                    ),
                  ),
          ),
        ),

        /// Delete button
        if (isEditable)
          Positioned(
            top: 8.dp,
            right: 8.dp,
            child: GestureDetector(
              onTap: () {
                if (feed.imageFile != null) {
                  notifier.updateField(feed: feed.copyWith(imageFile: null, imageUrl: null));
                } else {
                  notifier.updateField(feed: feed.copyWith(removeImage: true));
                }
              },
              child: DecoratedBox(
                decoration: BoxDecoration(color: theme.primaryBackground.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12.dp)),
                child: Icon(Icons.close_rounded, color: theme.secondaryText, size: 24.dp),
              ),
            ),
          ),
      ],
    );
  }
}

/// AddMediaWidget
class AddMediaWidget extends ConsumerWidget {
  final FeedModel feed;
  final FeedCardStateNotifier notifier;

  const AddMediaWidget({super.key, required this.feed, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final ScreenStyleState screenStyle = ref.watch(screenStyleStateProvider('feeds'));
    return GestureDetector(
      onTap: () async {
        try {
          final picker = ImagePicker();
          final XFile? pickedFile = await picker.pickMedia();
          if (pickedFile == null) return;

          final bool isImage = lookupMimeType(pickedFile.path)?.startsWith('image/') ?? false;

          if (isImage) {
            final double imageAspectRatio = await getImageAspectRatio(pickedFile);
            notifier.updateField(
              feed: feed.copyWith(imageFile: File(pickedFile.path), imageAspectRatio: imageAspectRatio),
            );
          } else {
            final double videoAspectRatio = await getVideoAspectRatio(pickedFile);
            notifier.updateField(
              feed: feed.copyWith(videoFile: File(pickedFile.path), videoAspectRatio: videoAspectRatio),
            );
          }
        } catch (error) {
          myLogger.e('Error while getting file aspect ratio');
        }
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(screenStyle.borderRadius),
          border: BoxBorder.all(color: theme.outline),
        ),
        width: double.infinity,
        height: 220,
        child: Icon(Icons.add_rounded, size: 24, color: theme.secondaryText),
      ),
    );
  }
}

/// FeedActionSection
class FeedActionSection extends ConsumerWidget {
  final FeedModel feed;
  final FeedCardStateNotifier notifier;

  const FeedActionSection({super.key, required this.feed, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: 24.dp,
          children: [
            /// Comments
            FeedActionRow(
              iconDataFill: KronkIcon.messageCircle1,
              iconDataOutline: KronkIcon.messageSquareLeft2,
              count: feed.engagement.comments,
              isViewing: feed.feedMode == FeedMode.view,
              onTap: () {
                ref.read(sharedFeed.notifier).state = feed;
                context.push('/feeds/feed');
              },
            ),

            /// Repost & quote
            FeedActionRow(
              iconDataFill: KronkIcon.repeat6,
              iconDataOutline: KronkIcon.repeat6,
              interacted: (feed.engagement.reposted == true) || (feed.engagement.quoted == true),
              count: feed.repostsAndQuotes,
              isViewing: feed.feedMode == FeedMode.view,
              onTap: feed.feedMode == FeedMode.create ? null : () async => notifier.handleEngagement(engagementType: EngagementType.reposts),
            ),

            /// Heart
            FeedActionRow(
              iconDataFill: KronkIcon.heartFill,
              iconDataOutline: KronkIcon.heartOutline,
              interacted: feed.engagement.liked ?? false,
              count: feed.engagement.likes,
              isViewing: feed.feedMode == FeedMode.view,
              onTap: feed.feedMode == FeedMode.create ? null : () async => notifier.handleEngagement(engagementType: EngagementType.likes),
            ),

            /// Views
            FeedActionRow(iconDataFill: KronkIcon.eyeOpen, iconDataOutline: KronkIcon.eyeOpen, count: feed.engagement.views, isViewing: feed.feedMode == FeedMode.view),
          ],
        ),

        /// Bookmark icons
        FeedActionRow(
          iconDataFill: KronkIcon.bookmarkFill5,
          iconDataOutline: KronkIcon.bookmarkOutline5,
          interacted: feed.engagement.bookmarked ?? false,
          isViewing: feed.feedMode == FeedMode.view,
          onTap: feed.feedMode == FeedMode.create ? null : () async => notifier.handleEngagement(engagementType: EngagementType.bookmarks),
        ),
      ],
    );
  }
}

/// FeedControl
class FeedControl extends ConsumerWidget {
  final FeedModel initialFeed;

  const FeedControl({super.key, required this.initialFeed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final feed = ref.watch(feedCardStateProvider(initialFeed));
    final notifier = ref.read(feedCardStateProvider(initialFeed).notifier);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        /// feed visibility & comment policy & scheduled time
        GestureDetector(
          onTap: () => showFeedAdditionalSettingsModal(context: context, initialFeed: initialFeed, backgroundColor: theme.secondaryBackground),
          child: Container(
            height: 24.dp,
            padding: EdgeInsets.symmetric(horizontal: 8.dp),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: theme.tertiaryBackground, borderRadius: BorderRadius.circular(8.dp)),
            child: Text(
              'additional settings',
              style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),

        /// cancel & save & update
        Row(
          spacing: 8.dp,
          children: [
            /// cancel
            GestureDetector(
              onTap: () {
                if (feed.isLoading) return;
                if (feed.feedMode == FeedMode.update) {
                  notifier.updateField(feed: feed.copyWith(feedMode: FeedMode.view));
                  return;
                }
                final currentIndex = ref.read(feedsScreenTabIndexProvider);
                final currentTimeline = currentIndex == 0 ? TimelineType.discover : TimelineType.following;
                ref.read(timelineNotifierProvider(currentTimeline).notifier).removeLast();
              },
              child: Container(
                width: 74.dp,
                height: 24.dp,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: theme.tertiaryBackground, borderRadius: BorderRadius.circular(8.dp)),
                child: Text(
                  'cancel',
                  style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            /// save & update
            GestureDetector(
              onTap: () async {
                if (feed.isLoading) return;
                try {
                  if (feed.body == null || feed.body == null || feed.body!.isEmpty) return;
                  if (feed.feedMode == FeedMode.create) await notifier.save();
                  if (feed.feedMode == FeedMode.update) await notifier.update();
                } catch (e) {
                  myLogger.w('catch while saving feed, e: $e');
                }
              },
              child: Container(
                width: 74.dp,
                height: 24.dp,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.tertiaryBackground,
                  borderRadius: BorderRadius.circular(8.dp),
                  border: Border.all(color: theme.outline, width: 0.2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!feed.isLoading)
                      Text(
                        feed.feedMode == FeedMode.create ? 'create' : 'update',
                        style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16, fontWeight: FontWeight.w600),
                      ),

                    if (feed.isLoading) LoadingAnimationWidget.threeArchedCircle(color: theme.primaryText, size: 14.dp),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// FeedActionRow
class FeedActionRow extends ConsumerWidget {
  final IconData iconDataFill;
  final IconData iconDataOutline;
  final bool interacted;
  final bool isViewing;
  final int? count;
  final void Function()? onTap;

  const FeedActionRow({super.key, required this.iconDataFill, required this.iconDataOutline, this.interacted = false, required this.isViewing, this.count, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    final IconData iconToUse = interacted ? iconDataFill : iconDataOutline;
    final Color color = interacted
        ? iconDataOutline.appropriateColor
        : isViewing
        ? theme.primaryText
        : theme.secondaryText;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        spacing: 4,
        children: [
          Icon(iconToUse, size: 20, color: color, weight: 600),
          if (count != null)
            AnimatedFlipCounter(
              hideLeadingZeroes: true,
              value: count!.toDouble(),
              textStyle: GoogleFonts.quicksand(color: color, fontSize: 16, height: 0),
            ),
        ],
      ),
    );
  }
}

Future<double> getVideoAspectRatio(XFile videoFile) async {
  final controller = VideoPlayerController.file(File(videoFile.path));

  try {
    await controller.initialize();

    final double aspectRatio = controller.value.aspectRatio;

    return aspectRatio;
  } catch (e) {
    myLogger.w('Error getting video aspect ratio: $e');
    return 16 / 9;
  } finally {
    await controller.dispose();
  }
}

Future<double> getImageAspectRatio(XFile imageFile) async {
  try {
    final Uint8List bytes = await imageFile.readAsBytes();

    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image image = frameInfo.image;

    if (image.height == 0) return 1.0;

    return image.width.toDouble() / image.height.toDouble();
  } catch (error) {
    rethrow;
  }
}

void showFeedAdditionalSettingsModal({required BuildContext context, required FeedModel initialFeed, required Color backgroundColor}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: backgroundColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(16.dp)),
    builder: (context) => Consumer(
      builder: (context, ref, child) {
        final theme = ref.watch(themeProvider);
        final feed = ref.watch(feedCardStateProvider(initialFeed));
        final notifier = ref.read(feedCardStateProvider(initialFeed).notifier);
        return Padding(
          padding: EdgeInsets.all(28.dp),
          child: Column(
            spacing: 12.dp,
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Feed Visibility
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feed visibility:',
                    style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 18.dp, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 4.dp),
                  ...FeedVisibility.values.map((v) {
                    final isActive = feed.feedVisibility == v;
                    return RadioListTile<FeedVisibility>(
                      value: v,
                      groupValue: feed.feedVisibility,
                      dense: true,
                      tileColor: theme.tertiaryBackground,
                      activeColor: theme.primaryText,
                      title: Text(
                        v.name,
                        style: GoogleFonts.quicksand(color: isActive ? theme.primaryText : theme.secondaryText, fontSize: 16.dp, fontWeight: FontWeight.w500),
                      ),
                      onChanged: (FeedVisibility? feedVisibility) => notifier.updateField(feed: feed.copyWith(feedVisibility: feedVisibility)),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(width: 0, color: Colors.transparent),
                        borderRadius: BorderRadius.vertical(
                          top: v == FeedVisibility.public ? Radius.circular(12.dp) : Radius.zero,
                          bottom: v == FeedVisibility.private ? Radius.circular(12.dp) : Radius.zero,
                        ),
                      ),
                    );
                  }),
                ],
              ),

              /// Comment Policy
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comment policy:',
                    style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 18.dp, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 4.dp),
                  ...CommentPolicy.values.map((v) {
                    final isActive = feed.commentPolicy == v;
                    return RadioListTile<CommentPolicy>(
                      value: v,
                      groupValue: feed.commentPolicy,
                      dense: true,
                      tileColor: theme.tertiaryBackground,
                      activeColor: theme.primaryText,
                      title: Text(
                        v.name,
                        style: GoogleFonts.quicksand(color: isActive ? theme.primaryText : theme.secondaryText, fontSize: 16.dp, fontWeight: FontWeight.w500),
                      ),
                      onChanged: (CommentPolicy? commentPolicy) => notifier.updateField(feed: feed.copyWith(commentPolicy: commentPolicy)),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(width: 0, color: Colors.transparent),
                        borderRadius: BorderRadius.vertical(
                          top: v == CommentPolicy.everyone ? Radius.circular(12.dp) : Radius.zero,
                          bottom: v == CommentPolicy.followers ? Radius.circular(12.dp) : Radius.zero,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}
