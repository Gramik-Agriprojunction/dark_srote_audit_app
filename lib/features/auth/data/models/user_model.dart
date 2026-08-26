class UserModel {
  const UserModel({
    required this.id,
    this.name,
    this.fullName,
    this.email,
    this.role,
  });

  final int id;
  final String? name;
  final String? fullName;
  final String? email;
  final UserRoleModel? role;

  String get displayName => name ?? fullName ?? email ?? 'Gramik User';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString(),
      fullName: json['fullName']?.toString(),
      email: json['email']?.toString(),
      role: json['role'] is Map<String, dynamic>
          ? UserRoleModel.fromJson(json['role'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fullName': fullName,
        'email': email,
        'role': role?.toJson(),
      };
}

class UserRoleModel {
  const UserRoleModel({this.name});

  final String? name;

  factory UserRoleModel.fromJson(Map<String, dynamic> json) {
    return UserRoleModel(name: json['name']?.toString());
  }

  Map<String, dynamic> toJson() => {'name': name};
}
