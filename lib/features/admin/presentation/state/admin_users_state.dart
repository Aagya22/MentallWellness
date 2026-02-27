import 'package:equatable/equatable.dart';
import 'package:mentalwellness/features/admin/data/models/admin_user_model.dart';

enum AdminUsersStatus { initial, loading, loaded, deleting, error }

class AdminUsersState extends Equatable {
  final AdminUsersStatus status;
  final List<AdminUserModel> users;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final String search;
  final String? errorMessage;

  const AdminUsersState({
    this.status = AdminUsersStatus.initial,
    this.users = const [],
    this.page = 1,
    this.limit = 10,
    this.total = 0,
    this.totalPages = 0,
    this.search = '',
    this.errorMessage,
  });

  AdminUsersState copyWith({
    AdminUsersStatus? status,
    List<AdminUserModel>? users,
    int? page,
    int? limit,
    int? total,
    int? totalPages,
    String? search,
    String? errorMessage,
  }) {
    return AdminUsersState(
      status: status ?? this.status,
      users: users ?? this.users,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      search: search ?? this.search,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    users,
    page,
    limit,
    total,
    totalPages,
    search,
    errorMessage,
  ];
}
