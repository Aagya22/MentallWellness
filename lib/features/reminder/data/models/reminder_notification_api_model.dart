import 'package:mentalwellness/features/reminder/domain/entities/reminder_notification_entity.dart';

class ReminderNotificationApiModel {
  final String id;
  final String reminderId;
  final String title;
  final String type;
  final DateTime scheduledFor;
  final DateTime deliveredAt;
  final DateTime? readAt;

  const ReminderNotificationApiModel({
    required this.id,
    required this.reminderId,
    required this.title,
    required this.type,
    required this.scheduledFor,
    required this.deliveredAt,
    required this.readAt,
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

  factory ReminderNotificationApiModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      final parsed = DateTime.tryParse(value.toString());
      if (parsed == null) return DateTime.now();
      return parsed.isUtc ? parsed.toLocal() : parsed;
    }

    DateTime? parseNullable(dynamic value) {
      if (value == null) return null;
      final parsed = DateTime.tryParse(value.toString());
      if (parsed == null) return null;
      return parsed.isUtc ? parsed.toLocal() : parsed;
    }

    return ReminderNotificationApiModel(
      id: _idToString(json['_id'] ?? json['id']),
      reminderId: _idToString(json['reminderId']),
      title: json['title']?.toString() ?? '',
      type: json['type']?.toString() ?? 'journal',
      scheduledFor: parseDate(json['scheduledFor']),
      deliveredAt: parseDate(json['deliveredAt']),
      readAt: parseNullable(json['readAt']),
    );
  }

  ReminderNotificationEntity toEntity() {
    return ReminderNotificationEntity(
      id: id,
      reminderId: reminderId,
      title: title,
      type: type,
      scheduledFor: scheduledFor,
      deliveredAt: deliveredAt,
      readAt: readAt,
    );
  }
}
