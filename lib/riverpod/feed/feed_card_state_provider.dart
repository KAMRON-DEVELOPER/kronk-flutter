import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/feed_model.dart';
import 'package:kronk/services/api_service/feed_service.dart';
import 'package:kronk/services/api_service/user_service.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:mime/mime.dart';
import 'package:visibility_detector/visibility_detector.dart';

final feedCardStateProvider = AutoDisposeNotifierProviderFamily<FeedCardStateNotifier, FeedModel, FeedModel>(() => FeedCardStateNotifier());

class FeedCardStateNotifier extends AutoDisposeFamilyNotifier<FeedModel, FeedModel> {
  Timer? _viewTimer;

  @override
  FeedModel build(FeedModel initialFeed) {
    ref.onDispose(() {
      myLogger.t('onDispose is working...');
      if (_viewTimer != null && _viewTimer!.isActive) _viewTimer?.cancel();
    });

    ref.onCancel(() {
      myLogger.t('onCancel is working...');
      if (_viewTimer != null && _viewTimer!.isActive) _viewTimer?.cancel();
    });

    return initialFeed;
  }

  void updateField({required FeedModel feed}) {
    myLogger.d('feed.id: ${feed.id}');
    myLogger.d('feed.body: ${feed.body}');
    myLogger.d('feed.author.name: ${feed.author.name}');
    myLogger.d('feed.author.username: ${feed.author.username}');
    myLogger.d('feed.imageFile?.path: ${feed.imageFile?.path}');
    myLogger.d('feed.imageUrl: ${feed.imageUrl}');
    state = feed;
  }

  Future<void> save() async {
    final FeedService service = FeedService();

    myLogger.d('SAVE');
    myLogger.d('state.body: ${state.body}');
    myLogger.d('state.author.name: ${state.author.name}');
    myLogger.d('state.imageFile.length: ${state.imageFile?.path}');
    myLogger.d('state.state.videoFile?.path: ${state.videoFile?.path}');

    try {
      final feed = state;
      final hasImage = feed.imageFile != null;
      final hasVideo = feed.videoFile != null;

      Map<String, dynamic> map = {
        if (feed.body != null) 'body': feed.body,
        if (feed.feedVisibility != null) 'feed_visibility': feed.feedVisibility?.name,
        if (feed.commentPolicy != null) 'commenting_policy': feed.commentPolicy?.name,
        if (feed.scheduledAt != null) 'scheduled_at': feed.scheduledAt,
      };

      if (hasVideo) {
        final String? mimeType = lookupMimeType(feed.videoFile!.path);
        map['video_file'] = await MultipartFile.fromFile(
          feed.videoFile!.path,
          filename: feed.videoFile!.path.split('/').last,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        );
      }

      if (hasImage) {
        final String? mimeType = lookupMimeType(feed.imageFile!.path);
        map['image_file'] = await MultipartFile.fromFile(
          feed.imageFile!.path,
          filename: feed.imageFile!.path.split('/').last,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        );
      }

      myLogger.d('map: $map');
      Response jsonResponse = await service.fetchCreateFeed(formData: FormData.fromMap(map));
      myLogger.d('jsonResponse.data: ${jsonResponse.data}, statusCode: ${jsonResponse.statusCode}');

      final Map<String, dynamic> data = jsonResponse.data;

      final createdFeed = state.copyWith(
        id: data['id'],
        createdAt: DateTime.fromMillisecondsSinceEpoch((data['created_at'] * 1000).toInt()),
        updatedAt: DateTime.fromMillisecondsSinceEpoch((data['updated_at'] * 1000).toInt()),
        body: data['body'],
        author: AuthorModel.fromJson(data['author']),
        feedVisibility: FeedVisibility.values.byName(data['feed_visibility']),
        commentPolicy: CommentingPolicy.values.byName(data['comment_policy']),
        feedMode: FeedMode.view,
      );

      state = createdFeed;
    } catch (error) {
      myLogger.e('error: $error');
      rethrow;
    }
  }

  Future<void> update() async {
    final FeedService service = FeedService();

    myLogger.d('UPDATE');
    myLogger.d('state.body: ${state.body}');
    myLogger.d('state.author.name: ${state.author.name}');
    myLogger.d('state.imageFile.length: ${state.imageFile?.path}');
    myLogger.d('state.state.videoFile?.path: ${state.videoFile?.path}');
    myLogger.d('state.removeImage: ${state.removeImage}');
    myLogger.d('state.removeVideo: ${state.removeVideo}');

    try {
      final feed = state;
      final hasImage = feed.imageFile != null;
      final hasVideo = feed.videoFile != null;

      Map<String, dynamic> map = {
        if (feed.body != null) 'body': feed.body,
        if (feed.feedVisibility != null) 'feed_visibility': feed.feedVisibility?.name,
        if (feed.commentPolicy != null) 'commenting_policy': feed.commentPolicy?.name,
        if (feed.scheduledAt != null) 'scheduled_at': feed.scheduledAt,
        if (feed.removeImage) 'remove_image': true,
        if (feed.removeVideo) 'remove_video': true,
      };

      if (hasVideo) {
        final String? mimeType = lookupMimeType(feed.videoFile!.path);
        map['video_file'] = await MultipartFile.fromFile(
          feed.videoFile!.path,
          filename: feed.videoFile!.path.split('/').last,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        );
      }

      if (hasImage) {
        final String? mimeType = lookupMimeType(feed.imageFile!.path);
        map['image_file'] = await MultipartFile.fromFile(
          feed.imageFile!.path,
          filename: feed.imageFile!.path.split('/').last,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        );
      }

      myLogger.d('map: $map');
      Response jsonResponse = await service.fetchUpdateFeed(feedId: feed.id, formData: FormData.fromMap(map));
      myLogger.d('jsonResponse.data: ${jsonResponse.data}, statusCode: ${jsonResponse.statusCode}');

      if (jsonResponse.statusCode == 400) {
        throw Exception(jsonResponse.data['detail']);
      }

      final data = jsonResponse.data as Map<String, dynamic>;

      myLogger.w('type of data: ${data.runtimeType}');
      final updatedFeed = FeedModel.fromJson(data);

      state = updatedFeed;
    } catch (error) {
      myLogger.e('error: $error');
      rethrow;
    }
  }

  Future<void> onVisibilityChanged({required VisibilityInfo info}) async {
    if ((state.feedMode.name == FeedMode.create.name) || (state.engagement.viewed ?? false)) return;

    final FeedService feedService = FeedService();

    final hasMedia = state.imageUrl != null || state.videoUrl != null;
    final isVisibleEnough = hasMedia ? info.visibleFraction > 0.25 : info.visibleFraction > 0;

    if (isVisibleEnough) {
      _viewTimer ??= Timer(const Duration(seconds: 2), () async {
        final EngagementModel engagement = await feedService.fetchSetEngagement(feedId: state.id, engagementType: EngagementType.views);
        state = state.copyWith(engagement: engagement);
      });
    } else {
      _viewTimer?.cancel();
      _viewTimer = null;
    }
  }

  Future<void> handleEngagement({required EngagementType engagementType}) async {
    final FeedService feedService = FeedService();
    try {
      final bool isSetInteraction = switch (engagementType) {
        EngagementType.likes => state.engagement.liked != true,
        EngagementType.bookmarks => state.engagement.bookmarked != true,
        EngagementType.reposts => state.engagement.reposted != true,
        EngagementType.quotes => state.engagement.quoted != true,
        EngagementType.views => state.engagement.viewed != true,
        EngagementType.feeds => throw UnimplementedError(),
      };

      final EngagementModel engagement = isSetInteraction
          ? await feedService.fetchSetEngagement(feedId: state.id, engagementType: engagementType)
          : await feedService.fetchRemoveEngagement(feedId: state.id, engagementType: engagementType);

      state = state.copyWith(engagement: engagement);
    } catch (error, _) {
      myLogger.e('catch in handleEngagement: ${error.toString()}');
    }
  }

  // response = {"blocked": false, "symmetrical": false}
  Future<Map<String, bool>> blockUserStatus({required String? blockedId}) async {
    final userService = UserService();
    try {
      return await userService.blockUserStatus(blockedId: blockedId);
    } catch (error) {
      myLogger.e('catch in blockUserStatus: ${error.toString()}');
      rethrow;
    }
  }

  Future<bool> toggleBlockUser({required String? blockedId, bool symmetrical = false}) async {
    final userService = UserService();
    try {
      return await userService.toggleBlockUser(blockedId: blockedId, symmetrical: symmetrical);
    } catch (error) {
      myLogger.e('catch in toggleBlockUser: ${error.toString()}');
      rethrow;
    }
  }

  // final response = {
  //   "copyright_infringement": false,
  //   "spam": false,
  //   "nudity_or_sexual_content": false,
  //   "misinformation": false,
  //   "harassment_or_bullying": false,
  //   "hate_speech": false,
  //   "violence_or_threats": false,
  //   "self_harm_or_suicide": false,
  //   "impersonation": false,
  //   "other": false
  // }
  Future<Map<String, bool>> reportStatuses({required String? feedId}) async {
    final FeedService feedService = FeedService();
    try {
      return await feedService.reportStatuses(feedId: feedId);
    } catch (error) {
      myLogger.e('Error fetching report status for feed $feedId: $error');
      rethrow;
    }
  }

  Future<bool> toggleReport({required String? feedId, required ReportReason reportReason}) async {
    final FeedService feedService = FeedService();
    try {
      return await feedService.toggleReport(feedId: feedId, reportReason: reportReason);
    } catch (error) {
      myLogger.e('catch in toggleReport: ${error.toString()}');
      rethrow;
    }
  }
}
