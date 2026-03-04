import 'package:equatable/equatable.dart';
import 'package:mentalwellness/features/admin/data/models/admin_user_model.dart';

enum AdminDashboardStatus { initial, loading, loaded, error }

class AdminDashboardState extends Equatable {
  final AdminDashboardStatus status;
  final int totalUsers;
  final int totalAdmins;
  final int regularUsers;
  final int recentUsers30Days;
  final List<AdminUserModel> recentUsers;
  final String? errorMessage;

  const AdminDashboardState({
    this.status = AdminDashboardStatus.initial,
    this.totalUsers = 0,
    this.totalAdmins = 0,
    this.regularUsers = 0,
    this.recentUsers30Days = 0,
    this.recentUsers = const [],
    this.errorMessage,
  });

  AdminDashboardState copyWith({
    AdminDashboardStatus? status,
    int? totalUsers,
    int? totalAdmins,
    int? regularUsers,
    int? recentUsers30Days,
    List<AdminUserModel>? recentUsers,
    String? errorMessage,
  }) {
    return AdminDashboardState(
      status: status ?? this.status,
      totalUsers: totalUsers ?? this.totalUsers,
      totalAdmins: totalAdmins ?? this.totalAdmins,
      regularUsers: regularUsers ?? this.regularUsers,
      recentUsers30Days: recentUsers30Days ?? this.recentUsers30Days,
      recentUsers: recentUsers ?? this.recentUsers,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    totalUsers,
    totalAdmins,
    regularUsers,
    recentUsers30Days,
    recentUsers,
    errorMessage,
  ];
}
