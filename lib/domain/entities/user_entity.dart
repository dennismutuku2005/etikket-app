class UserEntity {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String token;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.token,
  });

  bool get isGateStaff {
    final r = role.toLowerCase().trim();
    return r.contains('staff') ||
        r.contains('gate') ||
        r.contains('scanner') ||
        r.contains('admin') ||
        r.contains('organizer') ||
        token.isNotEmpty;
  }
}
