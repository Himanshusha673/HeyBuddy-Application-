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
  Future<AuthUserModel> login(String username, String password) async {
    final response = await apiClient.post(
      ApiEndpoints.login,
      body: {'username': username, 'password': password},
    );

    final data = response['data'];
    final token = data?['token'];
    final userData = data?['user'];

    if (token != null) {
      await secureStorage.saveToken(token);
    }

    if (userData != null && userData['_id'] != null) {
      await secureStorage.saveUserId(userData['_id']);
    }

    return AuthUserModel.fromJson(userData ?? {});
  }

  @override
  Future<AuthUserModel> register(
    String username,
    String email,
    String password,
  ) async {
    final response = await apiClient.post(
      ApiEndpoints.register,
      body: {'username': username, 'password': password},
    );

    final data = response['data'];
    final token = data?['token'];
    final userId = data?['userId'];

    if (token != null) {
      await secureStorage.saveToken(token);
    }
    if (userId != null) {
      await secureStorage.saveUserId(userId);
    }

    return AuthUserModel.fromJson({'_id': userId, 'username': username});
  }

  @override
  Future<void> logout() async {
    await secureStorage.clearAll();
  }
}
