import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:kronk/models/vocabulary_model.dart';
import 'package:kronk/riverpod/general/connectivity_notifier_provider.dart';
import 'package:kronk/services/api_service/vocabulary_service.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:mime/mime.dart';
import 'package:tuple/tuple.dart';

final vocabulariesProvider = AutoDisposeAsyncNotifierProvider<ChatsNotifier, List<VocabularyModel>>(ChatsNotifier.new);

class ChatsNotifier extends AutoDisposeAsyncNotifier<List<VocabularyModel>> {
  late VocabularyService _vocabularyService;
  int _start = 0;
  int _end = 20;

  @override
  Future<List<VocabularyModel>> build() async {
    _vocabularyService = VocabularyService();

    ref.onDispose(() => myLogger.f('onDispose vocabulariesProvider'));
    ref.onCancel(() => myLogger.f('onCancel vocabulariesProvider'));

    try {
      final bool isOnline = ref.read(connectivityNotifierProvider).value ?? false;
      if (!isOnline) return [];
      return await _getVocabularies();
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
      return [];
    }
  }

  Future<List<VocabularyModel>> _getVocabularies() async {
    try {
      final Tuple2<List<VocabularyModel>, int> response = await _vocabularyService.getVocabularies();
      _end = response.item2;
      return response.item1;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return [];
    }
  }

  Future<List<VocabularyModel>> refresh() async {
    state = const AsyncValue.loading();
    final Future<List<VocabularyModel>> vocabularies = _getVocabularies();
    state = await AsyncValue.guard(() => vocabularies);
    return vocabularies;
  }

  Future<void> loadMore({int steps = 20}) async {
    _start = _end + 1;
    _end = _start + steps;

    final response = await _vocabularyService.getVocabularies(start: _start, end: _end);

    state = state.whenData((existing) => [...existing, ...response.item1]);
  }

  Future<void> createVocabularies({required List<File> images}) async {
    try {
      final formData = FormData();

      for (final image in images) {
        final mimeType = lookupMimeType(image.path);
        final mediaType = mimeType != null ? MediaType.parse(mimeType) : null;

        formData.files.add(MapEntry('images', await MultipartFile.fromFile(image.path, filename: image.path.split('/').last, contentType: mediaType)));
      }

      final ok = await _vocabularyService.createVocabularies(formData: formData);
      if (!ok) {
        state = AsyncError('Error occurred', StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteVocabularies({required List<String> vocabularyIds}) async {
    try {
      final ok = await _vocabularyService.deleteVocabularies(vocabularyIds: vocabularyIds);
      if (!ok) {
        state = AsyncError('Error occurred while deleting vocabularies', StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}
