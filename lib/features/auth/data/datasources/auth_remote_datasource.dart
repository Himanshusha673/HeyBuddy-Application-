import '../../../../core/config/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthUserModel> login(String email, String password);
  Future<AuthUserModel> register(String name, String email, String password);
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;
  final secureStorage = SecureStorage();

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<AuthUserModel> login(String email, String password) async {
    final response = await apiClient.post(
      ApiEndpoints.login,
      body: {'email': email, 'password': password},
    );

    await secureStorage.saveToken(response['token']);
    await secureStorage.saveUserId(response['user']['_id']);

    return AuthUserModel.fromJson(response['user']);
  }

  @override
  Future<AuthUserModel> register(
    String name,
    String email,
    String password,
  ) async {
    final response = await apiClient.post(
      ApiEndpoints.register,
      body: {'name': name, 'email': email, 'password': password},
    );

    await secureStorage.saveToken(response['token']);
    await secureStorage.saveUserId(response['user']['_id']);

    return AuthUserModel.fromJson(response['user']);
  }

  @override
  Future<void> logout() async {
    await secureStorage.clearAll();
  }
}
