import 'package:hive_ce_flutter/hive_flutter.dart';

import 'navbar_model.dart';

class NavbarModelAdapter extends TypeAdapter<NavbarModel> {
  @override
  final int typeId = 0;

  @override
  NavbarModel read(BinaryReader reader) {
    final String route = reader.readString();
    final bool isEnabled = reader.readBool();
    final bool isUpcoming = reader.readBool();
    final bool isPending = reader.readBool();

    return NavbarModel(route: route, isEnabled: isEnabled, isComingSoon: isUpcoming, isPlanned: isPending);
  }

  @override
  void write(BinaryWriter writer, NavbarModel model) {
    writer.writeString(model.route);
    writer.writeBool(model.isEnabled);
    writer.writeBool(model.isComingSoon);
    writer.writeBool(model.isPlanned);
  }
}
