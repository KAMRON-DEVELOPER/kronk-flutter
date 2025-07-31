import 'package:hive_ce_flutter/hive_flutter.dart';

class MyTab extends HiveObject {
  @HiveField(0)
  String? id;
  @HiveField(1)
  String? name;

  MyTab({this.id, this.name});

  factory MyTab.fromJson(Map<String, String> json) {
    return MyTab(id: json['id'], name: json['name']);
  }

  Map<String, String> toJson() {
    return {'name': name ?? ''};
  }

  MyTab forUpdate(MyTab? tab) {
    return MyTab(name: tab?.name ?? name);
  }
}
