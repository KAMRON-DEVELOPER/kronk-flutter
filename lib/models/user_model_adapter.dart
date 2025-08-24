import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/user_model.dart';

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 1;

  @override
  UserModel read(BinaryReader reader) {
    return UserModel(
      id: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      name: reader.readString(),
      username: reader.readString(),
      email: reader.readString(),
      avatarUrl: () {
        final value = reader.readString();
        return value.isEmpty ? null : value;
      }(),
      bannerUrl: () {
        final value = reader.readString();
        return value.isEmpty ? null : value;
      }(),
      bannerColor: () {
        final value = reader.readString();
        return value.isEmpty ? null : value;
      }(),
      birthdate: reader.readBool() ? DateTime.fromMillisecondsSinceEpoch(reader.readInt()) : null,
      bio: () {
        final value = reader.readString();
        return value.isEmpty ? null : value;
      }(),
      country: () {
        final value = reader.readString();
        return value.isEmpty ? null : value;
      }(),
      city: () {
        final value = reader.readString();
        return value.isEmpty ? null : value;
      }(),
      role: UserRole.values.byName(reader.readString()),
      status: UserStatus.values.byName(reader.readString()),
      followPolicy: FollowPolicy.values.byName(reader.readString()),
      followersCount: reader.readInt(),
      followingsCount: reader.readInt(),
      feedsCount: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, UserModel userModel) {
    writer.writeString(userModel.id);
    writer.writeInt(userModel.createdAt.millisecondsSinceEpoch);
    writer.writeInt(userModel.updatedAt.millisecondsSinceEpoch);
    writer.writeString(userModel.name);
    writer.writeString(userModel.username);
    writer.writeString(userModel.email);
    writer.writeString(userModel.avatarUrl ?? '');
    writer.writeString(userModel.bannerUrl ?? '');
    writer.writeString(userModel.bannerColor ?? '');
    writer.writeBool(userModel.birthdate != null);
    if (userModel.birthdate != null) {
      writer.writeInt(userModel.birthdate!.millisecondsSinceEpoch);
    }
    writer.writeString(userModel.bio ?? '');
    writer.writeString(userModel.country ?? '');
    writer.writeString(userModel.city ?? '');
    writer.writeString(userModel.role.name);
    writer.writeString(userModel.status.name);
    writer.writeString(userModel.followPolicy.name);
    writer.writeInt(userModel.followersCount);
    writer.writeInt(userModel.followingsCount);
    writer.writeInt(userModel.feedsCount);
  }
}
