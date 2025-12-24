import '../entities/user.dart';

abstract class AuthRepository {
  Future<AuthUser> login(String email, String password);
  Future<AuthUser> register(String name, String email, String password);
  Future<void> logout();
  Future<AuthUser?> getCurrentUser();
}
