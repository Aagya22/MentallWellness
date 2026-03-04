import 'package:mentalwellness/features/schedule/domain/entities/schedule_entity.dart';

class ScheduleApiModel {
  final String id;
  final String title;
  final String date;
  final String time;
  final String? description;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ScheduleApiModel({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    this.description,
    this.location,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ScheduleApiModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      return DateTime.tryParse(value.toString()) ?? DateTime.now();
    }

    return ScheduleApiModel(
      id: (json['_id'] ?? json['id']).toString(),
      title: json['title']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      description: json['description']?.toString(),
      location: json['location']?.toString(),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  ScheduleEntity toEntity() {
    return ScheduleEntity(
      id: id,
      title: title,
      date: date,
      time: time,
      description: description,
      location: location,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
