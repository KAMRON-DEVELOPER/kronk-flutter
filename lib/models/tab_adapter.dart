import 'package:hive_ce_flutter/hive_flutter.dart';

import 'tab_model.dart';

class TabAdapter extends TypeAdapter<MyTab> {
  @override
  final int typeId = 3;

  @override
  MyTab read(BinaryReader reader) {
    return MyTab(id: reader.readString(), name: reader.readString());
  }

  @override
  void write(BinaryWriter writer, MyTab obj) {
    writer.writeString(obj.id ?? '');
    writer.writeString(obj.name ?? '');
  }
}
