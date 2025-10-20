import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginWithEmail {
  const LoginWithEmail(this._authRepository);

  final AuthRepository _authRepository;

  Future<User> call({
    required String email,
    required String password,
  }) async {
    // Validate email format
    if (!_isValidEmail(email)) {
      throw ArgumentError('Invalid email format');
    }

    // Validate password strength
    if (password.length < 8) {
      throw ArgumentError('Password must be at least 8 characters long');
    }

    return await _authRepository.loginWithEmail(
      email: email,
      password: password,
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}