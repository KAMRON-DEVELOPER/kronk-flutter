/// SentenceModel
class SentenceModel {
  final String id;
  final DateTime updatedAt;
  final DateTime createdAt;
  final String sentence;
  final String translation;
  final String targetLanguage;
  final String ownerId;
  final List<VocabularyModel> words;

  SentenceModel({
    required this.id,
    required this.updatedAt,
    required this.createdAt,
    required this.sentence,
    required this.translation,
    required this.targetLanguage,
    required this.ownerId,
    required this.words,
  });

  factory SentenceModel.fromJson(Map<String, dynamic> json) => SentenceModel(
    id: json['id'],
    updatedAt: DateTime.fromMillisecondsSinceEpoch((json['updated_at'] * 1000).round()),
    createdAt: DateTime.fromMillisecondsSinceEpoch((json['created_at'] * 1000).round()),
    sentence: json['sentence'],
    translation: json['translation'],
    targetLanguage: json['target_language'],
    ownerId: json['owner_id'],
    words: (json['words'] as List).map((e) => VocabularyModel.fromJson(e)).toList(),
  );

  Map<String, dynamic> toJson() => {
    'sentence': sentence,
    'translation': translation,
    'target_language': targetLanguage,
    'owner_id': ownerId,
    'words': words.map((e) => e.toJson()).toList(),
  };

  SentenceModel copyWith({
    String? id,
    DateTime? updatedAt,
    DateTime? createdAt,
    String? sentence,
    String? translation,
    String? targetLanguage,
    String? ownerId,
    List<VocabularyModel>? words,
  }) => SentenceModel(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    createdAt: createdAt ?? this.createdAt,
    sentence: sentence ?? this.sentence,
    translation: translation ?? this.translation,
    targetLanguage: targetLanguage ?? this.targetLanguage,
    ownerId: ownerId ?? this.ownerId,
    words: words ?? this.words,
  );
}

/// VocabularyModel
class VocabularyModel {
  final String id;
  final DateTime updatedAt;
  final DateTime createdAt;
  final String word;
  final String translation;
  final String targetLanguage;
  final List<PhoneticModel> phonetics;
  final List<MeaningModel> meanings;

  VocabularyModel({
    required this.id,
    required this.updatedAt,
    required this.createdAt,
    required this.word,
    required this.translation,
    required this.targetLanguage,
    required this.phonetics,
    required this.meanings,
  });

  factory VocabularyModel.fromJson(Map<String, dynamic> json) => VocabularyModel(
    id: json['id'],
    updatedAt: DateTime.fromMillisecondsSinceEpoch((json['updated_at'] * 1000).round()),
    createdAt: DateTime.fromMillisecondsSinceEpoch((json['created_at'] * 1000).round()),
    word: json['word'],
    translation: json['translation'],
    targetLanguage: json['target_language'],
    phonetics: (json['phonetics'] as List).map((e) => PhoneticModel.fromJson(e)).toList(),
    meanings: (json['meanings'] as List).map((e) => MeaningModel.fromJson(e)).toList(),
  );

  Map<String, dynamic> toJson() => {
    'word': word,
    'translation': translation,
    'target_language': targetLanguage,
    'phonetics': phonetics.map((e) => e.toJson()).toList(),
    'meanings': meanings.map((e) => e.toJson()).toList(),
  };

  VocabularyModel copyWith({
    String? id,
    DateTime? updatedAt,
    DateTime? createdAt,
    String? word,
    String? translation,
    String? targetLanguage,
    List<PhoneticModel>? phonetics,
    List<MeaningModel>? meanings,
  }) => VocabularyModel(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    createdAt: createdAt ?? this.createdAt,
    word: word ?? this.word,
    translation: translation ?? this.translation,
    targetLanguage: targetLanguage ?? this.targetLanguage,
    phonetics: phonetics ?? this.phonetics,
    meanings: meanings ?? this.meanings,
  );
}

/// PhoneticModel
class PhoneticModel {
  final String id;
  final DateTime updatedAt;
  final DateTime createdAt;
  final String text;
  final String? audio;

  PhoneticModel({required this.id, required this.updatedAt, required this.createdAt, required this.text, this.audio});

  factory PhoneticModel.fromJson(Map<String, dynamic> json) => PhoneticModel(
    id: json['id'],
    updatedAt: DateTime.fromMillisecondsSinceEpoch((json['updated_at'] * 1000).round()),
    createdAt: DateTime.fromMillisecondsSinceEpoch((json['created_at'] * 1000).round()),
    text: json['text'],
    audio: json['audio'],
  );

  Map<String, dynamic> toJson() => {'text': text, 'audio': audio};

  PhoneticModel copyWith({String? id, DateTime? updatedAt, DateTime? createdAt, String? text, String? audio}) =>
      PhoneticModel(id: id ?? this.id, updatedAt: updatedAt ?? this.updatedAt, createdAt: createdAt ?? this.createdAt, text: text ?? this.text, audio: audio ?? this.audio);
}

/// DefinitionModel
class DefinitionModel {
  final String id;
  final DateTime updatedAt;
  final DateTime createdAt;
  final String definition;
  final String? example;

  DefinitionModel({required this.id, required this.updatedAt, required this.createdAt, required this.definition, this.example});

  factory DefinitionModel.fromJson(Map<String, dynamic> json) => DefinitionModel(
    id: json['id'],
    updatedAt: DateTime.fromMillisecondsSinceEpoch((json['updated_at'] * 1000).round()),
    createdAt: DateTime.fromMillisecondsSinceEpoch((json['created_at'] * 1000).round()),
    definition: json['definition'],
    example: json['example'],
  );

  Map<String, dynamic> toJson() => {'definition': definition, 'example': example};

  DefinitionModel copyWith({String? id, DateTime? updatedAt, DateTime? createdAt, String? definition, String? example}) => DefinitionModel(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    createdAt: createdAt ?? this.createdAt,
    definition: definition ?? this.definition,
    example: example ?? this.example,
  );
}

/// MeaningModel
class MeaningModel {
  final String id;
  final DateTime updatedAt;
  final DateTime createdAt;
  final String partOfSpeech;
  final List<DefinitionModel> definitions;

  MeaningModel({required this.id, required this.updatedAt, required this.createdAt, required this.partOfSpeech, required this.definitions});

  factory MeaningModel.fromJson(Map<String, dynamic> json) => MeaningModel(
    id: json['id'],
    updatedAt: DateTime.fromMillisecondsSinceEpoch((json['updated_at'] * 1000).round()),
    createdAt: DateTime.fromMillisecondsSinceEpoch((json['created_at'] * 1000).round()),
    partOfSpeech: json['part_of_speech'],
    definitions: (json['definitions'] as List).map((e) => DefinitionModel.fromJson(e)).toList(),
  );

  Map<String, dynamic> toJson() => {'part_of_speech': partOfSpeech, 'definitions': definitions.map((e) => e.toJson()).toList()};

  MeaningModel copyWith({String? id, DateTime? updatedAt, DateTime? createdAt, String? partOfSpeech, List<DefinitionModel>? definitions}) => MeaningModel(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    createdAt: createdAt ?? this.createdAt,
    partOfSpeech: partOfSpeech ?? this.partOfSpeech,
    definitions: definitions ?? this.definitions,
  );
}
