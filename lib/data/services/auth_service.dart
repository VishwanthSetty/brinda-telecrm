import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _client;

  AuthService(this._client);

  Future<Token> login(String email, String password) async {
    final response = await _client.dio.post(
      '/api/auth/login',
      data: LoginRequest(email: email, password: password).toJson(),
    );
    final token = Token.fromJson(response.data as Map<String, dynamic>);
    await _client.saveToken(token.accessToken);
    return token;
  }

  Future<void> logout() async {
    try {
      await _client.dio.post('/api/auth/logout');
    } catch (_) {
      // Always clear token locally even if server call fails
    }
    await _client.clearToken();
  }

  Future<bool> isLoggedIn() => _client.hasToken();

  Future<List<User>> listUsers() async {
    final response = await _client.dio.get('/api/auth/users');
    final list = response.data as List;
    return list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }
}
