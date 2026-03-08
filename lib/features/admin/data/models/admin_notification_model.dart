import 'package:equatable/equatable.dart';

class AdminNotificationModel extends Equatable {
  final String id;
  final String type;
  final String message;
  final String userId;
  final String userFullName;
  final String userEmail;
  final DateTime? readAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminNotificationModel({
    required this.id,
    required this.type,
    required this.message,
    required this.userId,
    required this.userFullName,
    required this.userEmail,
    this.readAt,
    this.createdAt,
    this.updatedAt,
  });

  bool get isRead => readAt != null;

  AdminNotificationModel copyWith({
    String? id,
    String? type,
    String? message,
    String? userId,
    String? userFullName,
    String? userEmail,
    DateTime? readAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminNotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      message: message ?? this.message,
      userId: userId ?? this.userId,
      userFullName: userFullName ?? this.userFullName,
      userEmail: userEmail ?? this.userEmail,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AdminNotificationModel.fromJson(Map<String, dynamic> json) {
    return AdminNotificationModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      userFullName: (json['userFullName'] ?? '').toString(),
      userEmail: (json['userEmail'] ?? '').toString(),
      readAt: _parseDate(json['readAt']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  @override
  List<Object?> get props => [
    id,
    type,
    message,
    userId,
    userFullName,
    userEmail,
    readAt,
    createdAt,
    updatedAt,
  ];
}
