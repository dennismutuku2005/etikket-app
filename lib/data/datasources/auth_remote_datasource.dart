import '../../core/constants/api_endpoints.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({
    required String identifier,
    required String password,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<UserModel> login({
    required String identifier,
    required String password,
  }) async {
    final dynamic response = await apiClient.post(
      ApiEndpoints.login,
      body: {
        'identifier': identifier.trim(),
        'password': password,
      },
    );

    if (response is Map<String, dynamic>) {
      final userModel = UserModel.fromJson(response);
      if (!userModel.isGateStaff) {
        throw AuthException(
          message: 'Access denied. Only gate staff, gate admins, or event organizers can sign in here.',
        );
      }
      return userModel;
    }

    throw ServerException(message: 'Invalid server response format.');
  }
}
