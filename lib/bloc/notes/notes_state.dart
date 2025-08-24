import 'package:equatable/equatable.dart';
import 'package:kronk/models/note_model.dart';

abstract class NotesState extends Equatable {
  const NotesState();
  @override
  List<Object?> get props => [];
}

class NotesStateLoading extends NotesState {
  final bool? mustRebuild;
  const NotesStateLoading({this.mustRebuild});

  @override
  List<Object?> get props => [mustRebuild];
}

class NotesStateSuccess extends NotesState {
  final List<NoteModel?> notesData;
  const NotesStateSuccess({required this.notesData});

  @override
  List<Object?> get props => [notesData];
}

class NotesStateFailure extends NotesState {
  final String notesFailureMessage;
  const NotesStateFailure({required this.notesFailureMessage});

  @override
  List<Object?> get props => [notesFailureMessage];
}
