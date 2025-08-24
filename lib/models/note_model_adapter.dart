import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:kronk/models/note_model.dart';

class ChecklistModelAdapter extends TypeAdapter<ChecklistModel> {
  @override
  final int typeId = 3;

  @override
  ChecklistModel read(BinaryReader reader) {
    return ChecklistModel(
      id: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      text: reader.readString(),
      isDone: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, ChecklistModel obj) {
    writer.writeString(obj.id);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.updatedAt.millisecondsSinceEpoch);
    writer.writeString(obj.text);
    writer.writeBool(obj.isDone);
  }
}

class NoteModelAdapter extends TypeAdapter<NoteModel> {
  @override
  final int typeId = 2;

  @override
  NoteModel read(BinaryReader reader) {
    return NoteModel(
      id: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      title: () {
        final value = reader.readString();
        return value.isEmpty ? null : value;
      }(),
      body: () {
        final value = reader.readString();
        return value.isEmpty ? null : value;
      }(),
      pinned: reader.readBool(),
      archived: reader.readBool(),
      color: reader.readBool() ? reader.readInt() : null,
      reminderAt: reader.readBool() ? DateTime.fromMillisecondsSinceEpoch(reader.readInt()) : null,
      checklists: reader.readBool() ? reader.readList().cast<ChecklistModel>() : null,
      tags: reader.readBool() ? reader.readStringList() : null,
      collaborators: reader.readBool() ? reader.readStringList() : null,
      images: reader.readBool() ? reader.readStringList() : null,
    );
  }

  @override
  void write(BinaryWriter writer, NoteModel obj) {
    writer.writeString(obj.id);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.updatedAt.millisecondsSinceEpoch);
    writer.writeString(obj.title ?? '');
    writer.writeString(obj.body ?? '');
    writer.writeBool(obj.pinned);
    writer.writeBool(obj.archived);
    writer.writeBool(obj.color != null);
    if (obj.color != null) {
      writer.writeInt(obj.color!);
    }
    writer.writeBool(obj.reminderAt != null);
    if (obj.reminderAt != null) {
      writer.writeInt(obj.reminderAt!.millisecondsSinceEpoch);
    }
    writer.writeBool(obj.checklists != null);
    if (obj.checklists != null) {
      writer.writeList(obj.checklists!);
    }
    writer.writeBool(obj.tags != null);
    if (obj.tags != null) {
      writer.writeStringList(obj.tags!);
    }
    writer.writeBool(obj.collaborators != null);
    if (obj.collaborators != null) {
      writer.writeStringList(obj.collaborators!);
    }
    writer.writeBool(obj.images != null);
    if (obj.images != null) {
      writer.writeStringList(obj.images!);
    }
  }
}
