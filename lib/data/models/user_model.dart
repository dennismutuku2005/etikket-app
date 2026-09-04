import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    required super.role,
    required super.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? explicitToken}) {
    final Map<String, dynamic> userData = json.containsKey('user') && json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : json;

    final String token = explicitToken ?? (json['token']?.toString() ?? userData['token']?.toString() ?? '');

    return UserModel(
      id: int.tryParse(userData['id']?.toString() ?? '0') ?? 0,
      name: (userData['name'] ?? userData['full_name'] ?? 'Gate Staff').toString(),
      email: (userData['email'] ?? '').toString(),
      phone: userData['phone']?.toString(),
      role: (userData['role'] ?? 'gate_staff').toString(),
      token: token,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'token': token,
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      name: name,
      email: email,
      phone: phone,
      role: role,
      token: token,
    );
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      phone: entity.phone,
      role: entity.role,
      token: entity.token,
    );
  }
}
