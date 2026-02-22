import 'package:equatable/equatable.dart';

class JournalEntity extends Equatable {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JournalEntity({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, title, content, date, createdAt, updatedAt];
}
