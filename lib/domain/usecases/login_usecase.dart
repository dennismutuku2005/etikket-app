import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<UserEntity> call({
    required String identifier,
    required String password,
  }) {
    return repository.login(identifier: identifier, password: password);
  }
}
