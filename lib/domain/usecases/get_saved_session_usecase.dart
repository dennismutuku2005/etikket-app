import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class GetSavedSessionUseCase {
  final AuthRepository repository;

  GetSavedSessionUseCase(this.repository);

  Future<UserEntity?> call() {
    return repository.getSavedSession();
  }
}
