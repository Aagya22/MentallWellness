import 'package:equatable/equatable.dart';

class ScheduleEntity extends Equatable {
  final String id;
  final String title;
  final String date; // YYYY-MM-DD
  final String time; // HH:mm
  final String? description;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ScheduleEntity({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    this.description,
    this.location,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    date,
    time,
    description,
    location,
    createdAt,
    updatedAt,
  ];
}
