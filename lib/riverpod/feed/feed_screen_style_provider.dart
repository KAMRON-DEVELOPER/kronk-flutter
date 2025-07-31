import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/storage.dart';

final feedsScreenStyleProvider = NotifierProvider<FeedScreenStyleNotifier, FeedScreenDisplayState>(() => FeedScreenStyleNotifier());

class FeedScreenStyleNotifier extends Notifier<FeedScreenDisplayState> {
  final Storage _storage = Storage();

  @override
  FeedScreenDisplayState build() => _storage.getFeedScreenDisplayStyle();

  Future<void> updateFeedScreenStyle({ScreenStyle? screenStyle, double? cardOpacity, double? cardBorderRadius, String? backgroundImagePath}) async {
    final newState = state.copyWith(screenStyle: screenStyle, cardOpacity: cardOpacity, cardBorderRadius: cardBorderRadius, backgroundImagePath: backgroundImagePath);
    state = newState;

    await _storage.setSettingsAllAsync({
      'feedScreenDisplayStyle': newState.screenStyle.name,
      'feedScreenBackgroundImagePath': newState.backgroundImagePath,
      'feedScreenCardOpacity': newState.cardOpacity,
      'feedScreenCardBorderRadius': newState.cardBorderRadius,
    });
  }
}
