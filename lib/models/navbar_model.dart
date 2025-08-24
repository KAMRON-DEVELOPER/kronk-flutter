import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:kronk/constants/kronk_icon.dart';

// @HiveType(typeId: 0, adapterName: 'NavbarModelAdapter')
class NavbarModel extends HiveObject {
  @HiveField(0)
  String route;

  @HiveField(1)
  bool isEnabled;

  @HiveField(2)
  bool isComingSoon;

  @HiveField(3)
  bool isPlanned;

  NavbarModel({required this.route, this.isEnabled = false, this.isComingSoon = false, this.isPlanned = false});

  IconData getIconData({required bool isActive}) => getNavbarIconByName(route: route, isActive: isActive);

  NavbarModel copyWith({bool? isEnabled, bool? isComingSoon, bool? isPlanned}) {
    return NavbarModel(route: route, isEnabled: isEnabled ?? this.isEnabled, isComingSoon: isComingSoon ?? this.isComingSoon, isPlanned: isPlanned ?? this.isPlanned);
  }
}
