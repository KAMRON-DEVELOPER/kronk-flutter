import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/feed_model.dart';
import 'package:kronk/services/api_service/feed_service.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/storage.dart';
import 'package:tuple/tuple.dart';

final engagementFeedNotifierProvider = AsyncNotifierProviderFamily<EngagementFeedNotifier, List<FeedModel>, Tuple2<String?, EngagementType>>(EngagementFeedNotifier.new);

class EngagementFeedNotifier extends FamilyAsyncNotifier<List<FeedModel>, Tuple2<String?, EngagementType>> {
  final FeedService _feedService = FeedService();
  final Connectivity _connectivity = Connectivity();
  final Storage _storage = Storage();
  int _end = 9;
  int _realEnd = 10;
  bool _isLoadingMore = false;

  @override
  Future<List<FeedModel>> build(Tuple2<String?, EngagementType> key) async {
    _end = 9;
    _realEnd = 10;
    try {
      final bool isOnlineAndAuthenticated = await _isOnlineAndAuthenticated();
      if (!isOnlineAndAuthenticated) {
        return [];
      }
      return await _fetchEngagementFeeds(key: key);
    } catch (error) {
      rethrow;
    }
  }

  Future<List<FeedModel>> _fetchEngagementFeeds({required Tuple2<String?, EngagementType> key}) async {
    try {
      final results = await _feedService.fetchEngagementFeeds(key: key);
      _realEnd = results.item2 - 1;
      return results.item1;
    } catch (error) {
      rethrow;
    }
  }

  Future<List<FeedModel>> refresh({required Tuple2<String?, EngagementType> key}) async {
    state = const AsyncValue.loading();
    _end = 9;
    _realEnd = 10;
    _isLoadingMore = false;
    try {
      final Future<List<FeedModel>> feeds = _fetchEngagementFeeds(key: key);
      state = await AsyncValue.guard(() => feeds);
      return feeds;
    } catch (error) {
      rethrow;
    }
  }

  Future<bool> _isOnlineAndAuthenticated() async {
    final connectivity = await _connectivity.checkConnectivity();
    final isOnline = connectivity.any((ConnectivityResult result) => result != ConnectivityResult.none);

    final accessToken = await _storage.getAccessTokenAsync();
    final bool isAuthenticated = accessToken != null ? true : false;

    return isOnline && isAuthenticated;
  }

  Future<void> loadMore({required Tuple2<String?, EngagementType> key}) async {
    if (_isLoadingMore || _end >= _realEnd) return;
    _isLoadingMore = true;

    try {
      final nextStart = _end + 1;
      int nextEnd = min(_realEnd, _end + 10);
      myLogger.d('nextStart: $nextStart, nextEnd: $nextEnd');

      final results = await _feedService.fetchEngagementFeeds(key: key, start: nextStart, end: nextEnd);

      if (results.item1.isEmpty) return;

      _end = nextEnd;
      _realEnd = results.item2 - 1;

      state = AsyncValue.data([...?state.value, ...results.item1]);
    } finally {
      _isLoadingMore = false;
    }
  }
}
