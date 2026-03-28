import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/api_client.dart';
import '../../data/services/auth_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.read(apiClientProvider)),
);

// Whether a valid JWT token exists (drives auth redirect in router)
final isLoggedInProvider = FutureProvider<bool>((ref) {
  return ref.read(authServiceProvider).isLoggedIn();
});

// Login notifier: exposes login/logout and loading/error state
class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.read(authServiceProvider).isLoggedIn();

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authServiceProvider).login(email, password).then((_) => true),
    );
  }

  Future<void> logout() async {
    await ref.read(authServiceProvider).logout();
    state = const AsyncData(false);
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, bool>(
  AuthNotifier.new,
);
