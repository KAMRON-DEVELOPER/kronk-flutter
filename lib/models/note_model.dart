import 'package:equatable/equatable.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

@HiveType(typeId: 3, adapterName: 'ChecklistAdapter')
class ChecklistModel extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime createdAt;
  @HiveField(2)
  final DateTime updatedAt;
  @HiveField(3)
  final String text;
  @HiveField(4)
  final bool isDone;

  const ChecklistModel({required this.id, required this.createdAt, required this.updatedAt, required this.text, this.isDone = false});

  factory ChecklistModel.fromJson(Map<String, dynamic> json) {
    return ChecklistModel(
      id: json['id'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      text: json['text'] ?? '',
      isDone: json['is_done'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(), 'text': text, 'is_done': isDone};
  }

  ChecklistModel copyWith({String? id, DateTime? createdAt, DateTime? updatedAt, String? text, bool? isDone}) {
    return ChecklistModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      text: text ?? this.text,
      isDone: isDone ?? this.isDone,
    );
  }

  @override
  List<Object?> get props => [id, createdAt, updatedAt, text, isDone];
}

@HiveType(typeId: 2, adapterName: 'NoteAdapter')
class NoteModel extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime createdAt;
  @HiveField(2)
  final DateTime updatedAt;
  @HiveField(3)
  final String? title;
  @HiveField(4)
  final String? body;
  @HiveField(6)
  final bool pinned;
  @HiveField(7)
  final bool archived;
  @HiveField(8)
  final int? color;
  @HiveField(9)
  final DateTime? reminderAt;
  @HiveField(10)
  final List<ChecklistModel>? checklists;
  @HiveField(11)
  final List<String>? tags;
  @HiveField(12)
  final List<String>? collaborators;
  @HiveField(13)
  final List<String>? images;

  const NoteModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.title,
    this.body,
    this.pinned = false,
    this.archived = false,
    this.color,
    this.reminderAt,
    this.checklists,
    this.tags,
    this.collaborators,
    this.images,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch((double.tryParse(json['created_at'].toString()) ?? 0 * 1000).toInt()),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch((double.tryParse(json['updated_at'].toString()) ?? 0 * 1000).toInt()),
      title: json['title'],
      body: json['body'],
      pinned: json['pinned'] ?? false,
      archived: json['archived'] ?? false,
      color: json['color'],
      reminderAt: json['reminder_at'] != null ? DateTime.fromMillisecondsSinceEpoch((double.tryParse(json['reminder_at'].toString()) ?? 0 * 1000).toInt()) : null,
      checklists: (json['checklists'] as List<dynamic>?)?.map((c) => ChecklistModel.fromJson(c)).toList(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      collaborators: (json['collaborators'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'title': title,
      'body': body,
      'pinned': pinned,
      'archived': archived,
      'color': color,
      'reminder_at': reminderAt?.toIso8601String(),
      'checklists': checklists?.map((c) => c.toJson()).toList(),
      'tags': tags,
      'collaborators': collaborators,
      'images': images,
    };
  }

  static const _sentinel = Object();

  NoteModel copyWith({
    Object? id = _sentinel,
    Object? createdAt = _sentinel,
    Object? updatedAt = _sentinel,
    Object? title = _sentinel,
    Object? body = _sentinel,
    Object? pinned = _sentinel,
    Object? archived = _sentinel,
    Object? color = _sentinel,
    Object? reminderAt = _sentinel,
    Object? checklists = _sentinel,
    Object? tags = _sentinel,
    Object? collaborators = _sentinel,
    Object? images = _sentinel,
  }) {
    return NoteModel(
      id: id != _sentinel ? this.id : id as String,
      createdAt: createdAt != _sentinel ? this.createdAt : createdAt as DateTime,
      updatedAt: updatedAt != _sentinel ? this.updatedAt : updatedAt as DateTime,
      title: title != _sentinel ? this.title : title as String?,
      body: body != _sentinel ? this.body : body as String?,
      pinned: pinned != _sentinel ? this.pinned : pinned as bool,
      archived: archived != _sentinel ? this.archived : archived as bool,
      color: color != _sentinel ? this.color : color as int?,
      reminderAt: reminderAt != _sentinel ? this.reminderAt : reminderAt as DateTime?,
      checklists: checklists != _sentinel ? this.checklists : checklists as List<ChecklistModel>?,
      tags: tags != _sentinel ? this.tags : tags as List<String>?,
      collaborators: collaborators != _sentinel ? this.collaborators : collaborators as List<String>?,
      images: images != _sentinel ? this.images : images as List<String>?,
    );
  }

  @override
  List<Object?> get props => [id, createdAt, updatedAt, title, body, pinned, archived, color, reminderAt, checklists, tags, collaborators, images];
}
