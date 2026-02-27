class AdminUserModel {
  final String id;
  final String fullName;
  final String email;
  final String username;
  final String phoneNumber;
  final String role;
  final String? imageUrl;
  final DateTime? createdAt;

  const AdminUserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.username,
    required this.phoneNumber,
    required this.role,
    this.imageUrl,
    this.createdAt,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    final createdRaw = json['createdAt'];
    DateTime? created;
    if (createdRaw is String && createdRaw.isNotEmpty) {
      created = DateTime.tryParse(createdRaw);
    }

    return AdminUserModel(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      fullName: (json['fullName'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      username: (json['username'] ?? '') as String,
      phoneNumber: (json['phoneNumber'] ?? '') as String,
      role: (json['role'] ?? 'user') as String,
      imageUrl: json['imageUrl'] as String?,
      createdAt: created,
    );
  }
}
