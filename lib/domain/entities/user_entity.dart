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

  bool get isGateStaff => role == 'gate_staff' || role == 'gate_admin' || role == 'organizer' || role == 'admin';
}
