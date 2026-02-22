import 'package:mentalwellness/features/journal/domain/entities/journal_entity.dart';

class JournalApiModel {
  final String? id;
  final String title;
  final String content;
  final DateTime date;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  JournalApiModel({
    this.id,
    required this.title,
    required this.content,
    required this.date,
    this.createdAt,
    this.updatedAt,
  });

  factory JournalApiModel.fromJson(Map<String, dynamic> json) {
    final rawId = (json['id'] ?? json['_id']) as String?;
    return JournalApiModel(
      id: rawId,
      title: (json['title'] ?? '') as String,
      content: (json['content'] ?? '') as String,
      date: DateTime.parse((json['date'] as String)),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toCreateJson({DateTime? dateOverride}) {
    return {
      'title': title,
      'content': content,
      if (dateOverride != null) 'date': dateOverride.toIso8601String(),
    };
  }

  Map<String, dynamic> toUpdateJson({DateTime? dateOverride}) {
    return {
      'title': title,
      'content': content,
      if (dateOverride != null) 'date': dateOverride.toIso8601String(),
    };
  }

  JournalEntity toEntity() {
    final created = createdAt ?? date;
    final updated = updatedAt ?? created;
    return JournalEntity(
      id: id ?? '',
      title: title,
      content: content,
      date: date,
      createdAt: created,
      updatedAt: updated,
    );
  }

  static JournalApiModel fromEntity(JournalEntity entity) {
    return JournalApiModel(
      id: entity.id,
      title: entity.title,
      content: entity.content,
      date: entity.date,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
