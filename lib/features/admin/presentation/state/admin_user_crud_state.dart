import 'package:equatable/equatable.dart';
import 'package:mentalwellness/features/admin/data/models/admin_user_model.dart';

enum AdminUserCrudStatus { initial, loading, success, error }

class AdminUserCrudState extends Equatable {
  final AdminUserCrudStatus status;
  final AdminUserModel? user;
  final String? message;

  const AdminUserCrudState({
    this.status = AdminUserCrudStatus.initial,
    this.user,
    this.message,
  });

  AdminUserCrudState copyWith({
    AdminUserCrudStatus? status,
    AdminUserModel? user,
    String? message,
  }) {
    return AdminUserCrudState(
      status: status ?? this.status,
      user: user ?? this.user,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, user, message];
}
