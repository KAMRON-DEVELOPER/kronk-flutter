import 'dart:async';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = AutoDisposeAsyncNotifierProvider<AsyncConnectivityNotifier, bool>(() => AsyncConnectivityNotifier());

class AsyncConnectivityNotifier extends AutoDisposeAsyncNotifier<bool> {
  late Connectivity _connectivity;
  late StreamSubscription<List<ConnectivityResult>> _streamSubscription;

  @override
  Future<bool> build() async {
    _connectivity = Connectivity();

    ref.onDispose(() {
      _streamSubscription.cancel();
    });

    return _initializeConnection();
  }

  Future<bool> _initializeConnection() async {
    try {
      // Initialize the connection status
      List<ConnectivityResult> initialResults = await _connectivity.checkConnectivity();
      bool isOnline = initialResults.any((result) => result != ConnectivityResult.none);
      state = AsyncValue.data(isOnline);

      // Start listening to connectivity changes
      _streamSubscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
        isOnline = results.any((result) => result != ConnectivityResult.none);
        state = AsyncValue.data(isOnline);
      });

      return isOnline;
    } catch (e) {
      log('🌋 Error initializing connectivity: $e', level: 1000);
      return false;
    }
  }
}
