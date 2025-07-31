import 'package:hive_ce_flutter/hive_flutter.dart';

import 'note_model.dart';

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 2;

  @override
  Note read(BinaryReader reader) {
    return Note(id: reader.readString(), body: reader.readString(), category: reader.readString());
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer.writeString(obj.id ?? '');
    writer.writeString(obj.body ?? '');
    writer.writeString(obj.category ?? '');
  }
}
