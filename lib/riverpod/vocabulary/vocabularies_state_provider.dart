import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:kronk/models/vocabulary_model.dart';
import 'package:kronk/services/api_service/vocabulary_service.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:mime/mime.dart';

class VocabulariesState {
  final List<VocabularyModel> vocabularies;
  final int total;
  final bool hasMore;

  const VocabulariesState({this.vocabularies = const [], this.total = 0, this.hasMore = true});

  VocabulariesState copyWith({List<VocabularyModel>? vocabularies, int? total, bool? hasMore}) {
    return VocabulariesState(vocabularies: vocabularies ?? this.vocabularies, total: total ?? this.total, hasMore: hasMore ?? this.hasMore);
  }
}

final vocabulariesProvider = AutoDisposeAsyncNotifierProvider<VocabulariesNotifier, VocabulariesState>(VocabulariesNotifier.new);

class VocabulariesNotifier extends AutoDisposeAsyncNotifier<VocabulariesState> {
  int _offset = 0;
  final int _limit = 20;

  @override
  Future<VocabulariesState> build() async {
    final VocabularyService vocabularyService = VocabularyService();

    ref.onDispose(() => myLogger.f('onDispose vocabulariesProvider'));
    ref.onCancel(() => myLogger.f('onCancel vocabulariesProvider'));

    try {
      final response = await vocabularyService.getVocabularies(offset: 0, limit: _limit);
      _offset = response.item1.length;

      return VocabulariesState(vocabularies: response.item1, total: response.item2, hasMore: response.item1.length < response.item2);
    } catch (error) {
      throw Exception(error);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading) return;

    final currentState = state.value;
    state = const AsyncValue.loading();

    try {
      final VocabularyService vocabularyService = VocabularyService();
      final response = await vocabularyService.getVocabularies(offset: _offset, limit: _limit);

      final newVocabularies = [...?currentState?.vocabularies, ...response.item1];
      final newTotal = response.item2;

      _offset += response.item1.length;

      state = AsyncValue.data(VocabulariesState(vocabularies: newVocabularies, total: newTotal, hasMore: newVocabularies.length < newTotal));
    } catch (error, stackTrace) {
      state = AsyncValue<VocabulariesState>.error(error, stackTrace).copyWithPrevious(state);
    }
  }

  Future<void> refresh() async {
    final VocabularyService vocabularyService = VocabularyService();
    _offset = 0;
    state = const AsyncValue.loading();

    final response = await vocabularyService.getVocabularies(offset: _offset, limit: _limit);
    _offset = response.item1.length;

    state = AsyncValue.data(VocabulariesState(vocabularies: response.item1, total: response.item2, hasMore: response.item1.length < response.item2));
  }

  Future<void> createVocabularies({required List<File> images}) async {
    final VocabularyService vocabularyService = VocabularyService();
    try {
      final formData = FormData();

      for (final image in images) {
        final mimeType = lookupMimeType(image.path);
        final mediaType = mimeType != null ? MediaType.parse(mimeType) : null;

        formData.files.add(MapEntry('images', await MultipartFile.fromFile(image.path, filename: image.path.split('/').last, contentType: mediaType)));
      }

      final ok = await vocabularyService.createVocabularies(formData: formData);
      if (!ok) {
        state = AsyncError('Error occurred while creating vocabularies', StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteVocabularies({required List<String> vocabularyIds}) async {
    final VocabularyService vocabularyService = VocabularyService();
    try {
      final ok = await vocabularyService.deleteVocabularies(vocabularyIds: vocabularyIds);
      if (!ok) {
        state = AsyncError('Error occurred while deleting vocabularies', StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}
