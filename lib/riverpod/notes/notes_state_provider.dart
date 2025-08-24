import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/note_model.dart';
import 'package:kronk/services/api_service/note_service.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:mime/mime.dart';

class NotesState {
  final List<NoteModel> notes;
  final int total;
  final bool hasMore;

  const NotesState({this.notes = const [], this.total = 0, this.hasMore = true});

  NotesState copyWith({List<NoteModel>? notes, int? total, bool? hasMore}) {
    return NotesState(notes: notes ?? this.notes, total: total ?? this.total, hasMore: hasMore ?? this.hasMore);
  }
}

final notesStateProvider = AutoDisposeAsyncNotifierProviderFamily<NotesStateNotifier, NotesState, NoteScope>(NotesStateNotifier.new);

class NotesStateNotifier extends AutoDisposeFamilyAsyncNotifier<NotesState, NoteScope> {
  int _offset = 0;
  final int _limit = 20;

  @override
  Future<NotesState> build(NoteScope noteScope) async {
    final NoteService noteService = NoteService();

    ref.onDispose(() => myLogger.f('onDispose vocabulariesProvider'));
    ref.onCancel(() => myLogger.f('onCancel vocabulariesProvider'));

    try {
      final response = await noteService.getNotes(noteScope: noteScope, offset: 0, limit: _limit);
      _offset = response.item1.length;

      return NotesState(notes: response.item1, total: response.item2, hasMore: response.item1.length < response.item2);
    } catch (error) {
      throw Exception(error);
    }
  }

  Future<void> loadMore(NoteScope noteScope) async {
    if (state.isLoading) return;

    final currentState = state.value;
    state = const AsyncValue.loading();

    try {
      final NoteService noteService = NoteService();
      final response = await noteService.getNotes(noteScope: noteScope, offset: _offset, limit: _limit);

      final newNotes = [...?currentState?.notes, ...response.item1];
      final newTotal = response.item2;

      _offset += response.item1.length;

      state = AsyncValue.data(NotesState(notes: newNotes, total: newTotal, hasMore: newNotes.length < newTotal));
    } catch (error, stackTrace) {
      state = AsyncValue<NotesState>.error(error, stackTrace).copyWithPrevious(state);
    }
  }

  Future<void> refresh(NoteScope noteScope) async {
    final NoteService noteService = NoteService();
    _offset = 0;
    state = const AsyncValue.loading();

    final response = await noteService.getNotes(noteScope: noteScope, offset: _offset, limit: _limit);
    _offset = response.item1.length;

    state = AsyncValue.data(NotesState(notes: response.item1, total: response.item2, hasMore: response.item1.length < response.item2));
  }

  Future<void> createVocabularies({required List<File> images}) async {
    final NoteService noteService = NoteService();
    try {
      final formData = FormData();

      for (final image in images) {
        final mimeType = lookupMimeType(image.path);
        final mediaType = mimeType != null ? MediaType.parse(mimeType) : null;

        formData.files.add(MapEntry('images', await MultipartFile.fromFile(image.path, filename: image.path.split('/').last, contentType: mediaType)));
      }

      final ok = await noteService.createNote(formData: formData);
      if (!ok) {
        state = AsyncError('Error occurred while creating vocabularies', StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteVocabularies({required List<String> noteIds}) async {
    final NoteService noteService = NoteService();
    try {
      final ok = await noteService.deleteNotes(noteIds: noteIds);
      if (!ok) {
        state = AsyncError('Error occurred while deleting vocabularies', StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}
