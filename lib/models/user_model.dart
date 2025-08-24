import 'package:equatable/equatable.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/utility/extensions.dart';

@HiveType(typeId: 1, adapterName: 'UserModelAdapter')
class UserModel extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime createdAt;
  @HiveField(2)
  final DateTime updatedAt;
  @HiveField(3)
  final String name;
  @HiveField(4)
  final String username;
  @HiveField(5)
  final String email;
  @HiveField(8)
  final String? avatarUrl;
  @HiveField(9)
  final String? bannerUrl;
  @HiveField(10)
  final String? bannerColor;
  @HiveField(11)
  final DateTime? birthdate;
  @HiveField(12)
  final String? bio;
  @HiveField(13)
  final String? country;
  @HiveField(14)
  final String? city;
  @HiveField(15)
  final UserRole role;
  @HiveField(16)
  final UserStatus status;
  @HiveField(17)
  final FollowPolicy followPolicy;
  @HiveField(18)
  final int followersCount;
  @HiveField(19)
  final int followingsCount;
  @HiveField(20)
  final int feedsCount;

  final bool? isFollowing;

  const UserModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.bannerUrl,
    this.bannerColor,
    this.birthdate,
    this.bio,
    required this.country,
    required this.city,
    required this.role,
    required this.status,
    required this.followPolicy,
    required this.followersCount,
    required this.followingsCount,
    this.feedsCount = 0,
    this.isFollowing,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      createdAt: DateTime.fromMillisecondsSinceEpoch((double.tryParse(json['created_at'].toString()) ?? 0 * 1000).toInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch((double.tryParse(json['updated_at'].toString()) ?? 0 * 1000).toInt()),
      name: json['name'],
      username: json['username'],
      email: json['email'],
      avatarUrl: json['avatar_url'],
      bannerUrl: json['banner_url'],
      bannerColor: json['banner_color'],
      birthdate: json['birthdate'] != null ? DateTime.fromMillisecondsSinceEpoch((double.tryParse(json['birthdate'].toString()) ?? 0 * 1000).toInt()) : null,
      bio: json['bio'],
      country: json['country'],
      city: json['city'],
      role: UserRole.values.byName(json['role']),
      status: UserStatus.values.byName(json['status']),
      followPolicy: FollowPolicy.values.byName(json['follow_policy']),
      followersCount: json['followers_count'],
      followingsCount: json['followings_count'],
      feedsCount: json['feeds_count'] ?? 0,
      isFollowing: json['is_following'],
    );
  }

  static const _sentinel = Object();

  UserModel copyWith({
    Object? id = _sentinel,
    Object? createdAt = _sentinel,
    Object? updatedAt = _sentinel,
    Object? name = _sentinel,
    Object? username = _sentinel,
    Object? email = _sentinel,
    Object? bio = _sentinel,
    Object? country = _sentinel,
    Object? city = _sentinel,
    Object? birthdate = _sentinel,
    Object? avatarUrl = _sentinel,
    Object? bannerUrl = _sentinel,
    Object? role = _sentinel,
    Object? status = _sentinel,
    Object? followPolicy = _sentinel,
    Object? followersCount = _sentinel,
    Object? followingsCount = _sentinel,
    Object? feedsCount = _sentinel,
    Object? isFollowing = _sentinel,
  }) {
    return UserModel(
      id: id != _sentinel ? id as String : this.id,
      createdAt: createdAt != _sentinel ? createdAt as DateTime : this.createdAt,
      updatedAt: updatedAt != _sentinel ? updatedAt as DateTime : this.updatedAt,
      name: name != _sentinel ? name as String : this.name,
      username: username != _sentinel ? username as String : this.username,
      email: email != _sentinel ? email as String : this.email,
      bio: bio != _sentinel ? bio as String? : this.bio,
      country: country != _sentinel ? country as String? : this.country,
      city: city != _sentinel ? city as String? : this.city,
      birthdate: birthdate != _sentinel ? birthdate as DateTime? : this.birthdate,
      avatarUrl: avatarUrl != _sentinel ? avatarUrl as String? : this.avatarUrl,
      bannerUrl: bannerUrl != _sentinel ? bannerUrl as String? : this.bannerUrl,
      role: role != _sentinel ? role as UserRole : this.role,
      status: role != _sentinel ? status as UserStatus : this.status,
      followPolicy: followPolicy != _sentinel ? followPolicy as FollowPolicy : this.followPolicy,
      followersCount: followersCount != _sentinel ? followersCount as int : this.followersCount,
      followingsCount: followingsCount != _sentinel ? followingsCount as int : this.followingsCount,
      feedsCount: feedsCount != _sentinel ? feedsCount as int : this.feedsCount,
      isFollowing: isFollowing != _sentinel ? isFollowing as bool : this.isFollowing,
    );
  }

  UserModel fromMap({required Map<String, dynamic> data}) {
    return copyWith(
      name: data.containsKey('name') ? data['name'] : _sentinel,
      username: data.containsKey('username') ? data['username'] : _sentinel,
      email: data.containsKey('email') ? data['email'] : _sentinel,
      bio: data.containsKey('bio') ? data['bio'] : _sentinel,
      country: data.containsKey('country') ? data['country'] : _sentinel,
      city: data.containsKey('city') ? data['city'] : _sentinel,
      birthdate: data.containsKey('birthdate') ? (data['birthdate'] != null ? DateTime.fromMillisecondsSinceEpoch((data['birthdate'] as int) * 1000) : null) : _sentinel,
      followPolicy: data.containsKey('follow_policy') ? (data['follow_policy'] != null ? FollowPolicy.values.byName(data['follow_policy']) : null) : _sentinel,
      avatarUrl: data.containsKey('remove_avatar') ? null : (data.containsKey('avatar_url') ? data['avatar_url'] : _sentinel),
      bannerUrl: data.containsKey('remove_banner') ? null : (data.containsKey('banner_url') ? data['banner_url'] : _sentinel),
    );
  }

  @override
  List<Object?> get props => [id, createdAt, updatedAt, name, username, email, avatarUrl, bannerUrl, bannerColor, birthdate, bio, country, city, role, status, followPolicy];
}

class UpdateModel {
  static const Object _sentinel = Object();

  final Object? name;
  final Object? username;
  final Object? email;
  final Object? password;
  final Object? birthdate;
  final Object? bio;
  final Object? country;
  final Object? city;
  final Object? followPolicy;

  final bool removeAvatar;
  final bool removeBanner;

  const UpdateModel({
    this.name = _sentinel,
    this.username = _sentinel,
    this.email = _sentinel,
    this.password = _sentinel,
    this.birthdate = _sentinel,
    this.bio = _sentinel,
    this.country = _sentinel,
    this.city = _sentinel,
    this.followPolicy = _sentinel,
    this.removeAvatar = false,
    this.removeBanner = false,
  });

  UpdateModel copyWith({
    Object? name = _sentinel,
    Object? username = _sentinel,
    Object? email = _sentinel,
    Object? password = _sentinel,
    Object? birthdate = _sentinel,
    Object? bio = _sentinel,
    Object? country = _sentinel,
    Object? city = _sentinel,
    Object? followPolicy = _sentinel,
    bool? removeAvatar,
    bool? removeBanner,
  }) {
    return UpdateModel(
      name: name,
      username: username,
      email: email,
      password: password,
      birthdate: birthdate,
      bio: bio,
      country: country,
      city: city,
      followPolicy: followPolicy,
      removeAvatar: removeAvatar ?? this.removeAvatar,
      removeBanner: removeBanner ?? this.removeBanner,
    );
  }

  Map<String, dynamic> toJson({required UserModel user}) {
    final Map<String, dynamic> map = {};

    if (name != _sentinel && name != user.name) map['name'] = name;
    if (username != _sentinel && username != user.username) map['username'] = username;
    if (email != _sentinel && email != user.email) map['email'] = email;
    if (password != _sentinel && (password as String?)?.isNotEmpty == true) map['password'] = password;
    if (bio != _sentinel && bio != user.bio) map['bio'] = bio;
    if (birthdate != _sentinel && birthdate != user.birthdate) map['birthdate'] = ((birthdate as DateTime?)!.millisecondsSinceEpoch ~/ 1000);
    if (country != _sentinel && country != user.country) map['country'] = country;
    if (city != _sentinel && city != user.city) map['city'] = city;
    if (followPolicy != _sentinel && followPolicy != user.followPolicy) map['follow_policy'] = (followPolicy as FollowPolicy).name.toSnakeCase();
    if (removeAvatar) map['remove_avatar'] = true;
    if (removeBanner) map['remove_banner'] = true;

    return map;
  }
}
