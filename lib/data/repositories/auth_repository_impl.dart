import '../../core/errors/exceptions.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<UserEntity> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final userModel = await remoteDataSource.login(
        identifier: identifier,
        password: password,
      );
      await localDataSource.saveUser(userModel);
      return userModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserEntity?> getSavedSession() async {
    try {
      final userModel = await localDataSource.getSavedUser();
      return userModel?.toEntity();
    } catch (e) {
      throw CacheException(message: 'Failed to read local session: $e');
    }
  }

  @override
  Future<void> saveSession(UserEntity user) async {
    final model = UserModel.fromEntity(user);
    await localDataSource.saveUser(model);
  }

  @override
  Future<void> clearSession() async {
    await localDataSource.clearUser();
  }
}
