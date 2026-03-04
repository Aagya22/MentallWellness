import 'package:mentalwellness/features/reminder/domain/entities/reminder_entity.dart';

class ReminderApiModel {
  final String id;
  final String title;
  final String time;
  final String type;
  final List<int> daysOfWeek;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReminderApiModel({
    required this.id,
    required this.title,
    required this.time,
    required this.type,
    required this.daysOfWeek,
    required this.enabled,
    required this.createdAt,
    required this.updatedAt,
  });

  static String _idToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) {
      final oid = value[r'$oid'] ?? value['_id'] ?? value['id'];
      if (oid != null) return oid.toString();
    }
    return value.toString();
  }

  factory ReminderApiModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      return DateTime.tryParse(value.toString()) ?? DateTime.now();
    }

    final rawDays = json['daysOfWeek'];
    final days = <int>[];
    if (rawDays is List) {
      for (final d in rawDays) {
        final parsed = int.tryParse(d.toString());
        if (parsed != null && parsed >= 0 && parsed <= 6) days.add(parsed);
      }
    }

    return ReminderApiModel(
      id: _idToString(json['_id'] ?? json['id']),
      title: json['title']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      type: json['type']?.toString() ?? 'journal',
      daysOfWeek: days.isEmpty ? const [0, 1, 2, 3, 4, 5, 6] : days,
      enabled: json['enabled'] == true,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  ReminderEntity toEntity() {
    return ReminderEntity(
      id: id,
      title: title,
      time: time,
      type: type,
      daysOfWeek: daysOfWeek,
      enabled: enabled,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
