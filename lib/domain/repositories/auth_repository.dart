import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login({
    required String identifier,
    required String password,
  });

  Future<UserEntity?> getSavedSession();

  Future<void> saveSession(UserEntity user);

  Future<void> clearSession();
}
