import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/feed_model.dart';
import 'package:kronk/models/user_model.dart';
import 'package:kronk/services/api_service/feed_service.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/storage.dart';
import 'package:uuid/uuid.dart';

final timelineNotifierProvider = AsyncNotifierProviderFamily<TimelineNotifier, List<FeedModel>, TimelineType>(() => TimelineNotifier());

class TimelineNotifier extends FamilyAsyncNotifier<List<FeedModel>, TimelineType> {
  final FeedService _feedService = FeedService();
  final Connectivity _connectivity = Connectivity();
  final Storage _storage = Storage();
  int _end = 9;
  int _realEnd = 10;
  bool _isLoadingMore = false;

  @override
  Future<List<FeedModel>> build(TimelineType timelineType) async {
    _end = 9;
    _realEnd = 10;
    _isLoadingMore = false;

    ref.onDispose(() => myLogger.f('onDispose in timelineNotifierProvider'));

    try {
      final bool isOnlineAndAuthenticated = await _isOnlineAndAuthenticated();
      if (!isOnlineAndAuthenticated) {
        return [];
      }
      return await _fetchTimeline(timelineType: timelineType);
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
      return [];
    }
  }

  Future<List<FeedModel>> _fetchTimeline({required TimelineType timelineType}) async {
    try {
      final results = await _feedService.fetchTimeline(timelineType: timelineType);
      _realEnd = results.item2 - 1;
      return results.item1.isEmpty ? [] : results.item1;
    } catch (error) {
      rethrow;
    }
  }

  Future<List<FeedModel>> refresh({required TimelineType timelineType}) async {
    state = const AsyncValue.loading();
    _end = 9;
    _realEnd = 10;
    final Future<List<FeedModel>> feeds = _fetchTimeline(timelineType: timelineType);
    state = await AsyncValue.guard(() => feeds);
    return feeds;
  }

  Future<bool> _isOnlineAndAuthenticated() async {
    final connectivity = await _connectivity.checkConnectivity();
    final isOnline = connectivity.any((ConnectivityResult result) => result != ConnectivityResult.none);

    final accessToken = await _storage.getAccessTokenAsync();
    final bool isAuthenticated = accessToken != null ? true : false;

    return isOnline && isAuthenticated;
  }

  void createFeed() {
    final author = _storage.getUser();

    final placeholder = FeedModel(
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
      author: AuthorModel(id: author.id, name: author.name, username: author.username, avatarUrl: author.avatarUrl),
      body: null,
      feedMode: FeedMode.create,
      engagement: const EngagementModel(),
      feedVisibility: FeedVisibility.public,
      commentPolicy: CommentPolicy.everyone,
    );

    state = AsyncValue.data([placeholder, ...state.valueOrNull ?? []]);
  }

  void removeLast() {
    final currentFeeds = state.valueOrNull;

    if (currentFeeds == null || currentFeeds.isEmpty) return;

    // Check if the first feed is in create mode
    if (currentFeeds.first.feedMode == FeedMode.create) {
      final updatedFeeds = List<FeedModel>.from(currentFeeds)..removeAt(0);
      state = AsyncValue.data(updatedFeeds);
    }
  }

  Future<void> loadMore({required TimelineType timelineType}) async {
    if (_isLoadingMore || _end >= _realEnd) return;
    _isLoadingMore = true;

    try {
      final nextStart = _end + 1;
      int nextEnd = min(_realEnd, _end + 10);

      final results = await _feedService.fetchTimeline(timelineType: timelineType, start: nextStart, end: nextEnd);

      if (results.item1.isEmpty) return;

      _end = nextEnd;
      _realEnd = results.item2 - 1;

      state = AsyncValue.data([...?state.value, ...results.item1]);
    } finally {
      _isLoadingMore = false;
    }
  }
}

/// ------------------------------------------ Comment --------------------------------------- ///

final commentNotifierProvider = AsyncNotifierProviderFamily<CommentNotifier, List<FeedModel>, String?>(() => CommentNotifier());

class CommentNotifier extends FamilyAsyncNotifier<List<FeedModel>, String?> {
  final FeedService _feedService = FeedService();
  final Connectivity _connectivity = Connectivity();
  final Storage _storage = Storage();
  int _end = 9;
  int _realEnd = 10;
  bool _isLoadingMore = false;

  @override
  Future<List<FeedModel>> build(String? parentId) async {
    _end = 9;
    _realEnd = 10;

    ref.onDispose(() => myLogger.f('onDispose in commentNotifierProvider'));

    try {
      final bool isOnlineAndAuthenticated = await _isOnlineAndAuthenticated();
      if (!isOnlineAndAuthenticated) {
        return [];
      }
      return await _fetchComments(parentId: parentId);
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
      return [];
    }
  }

  Future<List<FeedModel>> _fetchComments({required String? parentId}) async {
    try {
      final results = await _feedService.fetchComments(parentId: parentId);
      myLogger.d('feeds in _fetchComments in commentNotifierProvider: ${results.item1}');
      _end = results.item2 - 1;
      return results.item1.isEmpty ? [] : results.item1;
    } catch (error) {
      // state = AsyncValue.error(error, StackTrace.current);
      rethrow;
    }
  }

  Future<List<FeedModel>> refresh({required String? parentId}) async {
    state = const AsyncValue.loading();
    _end = 9;
    _realEnd = 10;
    _isLoadingMore = false;
    final Future<List<FeedModel>> feeds = _fetchComments(parentId: parentId);
    state = await AsyncValue.guard(() => feeds);
    return feeds;
  }

  Future<bool> _isOnlineAndAuthenticated() async {
    final connectivity = await _connectivity.checkConnectivity();
    final isOnline = connectivity.any((ConnectivityResult result) => result != ConnectivityResult.none);

    final accessToken = await _storage.getAccessTokenAsync();
    final bool isAuthenticated = accessToken != null ? true : false;

    return isOnline && isAuthenticated;
  }

  void createComment() {
    final UserModel author = _storage.getUser();

    final placeholder = FeedModel(
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
      author: AuthorModel(id: author.id, name: author.name, username: author.username, avatarUrl: author.avatarUrl),
      body: null,
      feedMode: FeedMode.create,
      engagement: const EngagementModel(),
    );

    state = AsyncValue.data([placeholder, ...state.valueOrNull ?? []]);
  }

  Future<void> loadMore({required TimelineType timelineType}) async {
    if (_isLoadingMore || _end >= _realEnd) return;
    _isLoadingMore = true;

    try {
      final nextStart = _end + 1;
      int nextEnd = min(_realEnd, _end + 10);

      final results = await _feedService.fetchTimeline(timelineType: timelineType, start: nextStart, end: nextEnd);

      if (results.item1.isEmpty) return;

      _end = nextEnd;
      _realEnd = results.item2 - 1;

      state = AsyncValue.data([...?state.value, ...results.item1]);
    } finally {
      _isLoadingMore = false;
    }
  }
}
