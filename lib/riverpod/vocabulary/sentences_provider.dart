import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/models/vocabulary_model.dart';
import 'package:kronk/riverpod/general/connectivity_notifier_provider.dart';
import 'package:kronk/services/api_service/vocabulary_service.dart';
import 'package:kronk/utility/my_logger.dart';

class SentencesState {
  final List<SentenceModel> sentences;
  final int total;
  final bool hasMore;

  const SentencesState({this.sentences = const [], this.total = 0, this.hasMore = true});

  SentencesState copyWith({List<SentenceModel>? sentences, int? total, bool? hasMore}) {
    return SentencesState(sentences: sentences ?? this.sentences, total: total ?? this.total, hasMore: hasMore ?? this.hasMore);
  }
}

final sentencesProvider = AutoDisposeAsyncNotifierProvider<SentencesNotifier, SentencesState>(SentencesNotifier.new);

class SentencesNotifier extends AutoDisposeAsyncNotifier<SentencesState> {
  late VocabularyService _vocabularyService;
  int _offset = 0;
  final int _limit = 20;

  @override
  Future<SentencesState> build() async {
    _vocabularyService = VocabularyService();

    ref.onDispose(() => myLogger.f('onDispose sentencesProvider'));
    ref.onCancel(() => myLogger.f('onCancel sentencesProvider'));

    try {
      final bool isOnline = ref.read(connectivityProvider).value ?? false;
      if (!isOnline) {
        return const SentencesState(hasMore: false);
      }

      final response = await _vocabularyService.getSentences(offset: 0, limit: _limit);
      _offset = response.item1.length;

      return SentencesState(sentences: response.item1, total: response.item2, hasMore: response.item1.length < response.item2);
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
      return const SentencesState(hasMore: false);
    }
  }

  Future<void> loadMore() async {
    if (!state.value!.hasMore) return;

    state = const AsyncValue.loading();
    final currentState = state.value!;

    final response = await _vocabularyService.getSentences(offset: _offset, limit: _limit);

    final newItems = response.item1;
    final newTotal = response.item2;
    final newSentences = [...currentState.sentences, ...newItems];

    _offset += response.item1.length;

    state = AsyncValue.data(SentencesState(sentences: newSentences, total: newTotal, hasMore: newSentences.length < newTotal));
  }

  Future<void> refresh() async {
    _offset = 0;
    state = const AsyncValue.loading();

    final response = await _vocabularyService.getSentences(offset: _offset, limit: _limit);
    _offset = response.item1.length;

    state = AsyncValue.data(SentencesState(sentences: response.item1, total: response.item2, hasMore: response.item1.length < response.item2));
  }

  Future<void> deleteSentences({required List<String> sentenceIds}) async {
    try {
      final ok = await _vocabularyService.deleteSentences(sentenceIds: sentenceIds);
      if (!ok) {
        state = AsyncError('Error occurred while deleting sentences', StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}
