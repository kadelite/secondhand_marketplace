import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterWithEmail {
  const RegisterWithEmail(this._authRepository);

  final AuthRepository _authRepository;

  Future<User> call({
    required String email,
    required String password,
    required String name,
  }) async {
    // Validate email format
    if (!_isValidEmail(email)) {
      throw ArgumentError('Invalid email format');
    }

    // Validate password strength
    if (!_isStrongPassword(password)) {
      throw ArgumentError(
        'Password must be at least 8 characters long and contain uppercase, lowercase, number, and special character',
      );
    }

    // Validate name
    if (name.trim().isEmpty) {
      throw ArgumentError('Name cannot be empty');
    }

    if (name.length < 2) {
      throw ArgumentError('Name must be at least 2 characters long');
    }

    return await _authRepository.registerWithEmail(
      email: email,
      password: password,
      name: name.trim(),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isStrongPassword(String password) {
    if (password.length < 8) return false;

    bool hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    bool hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    bool hasNumbers = RegExp(r'[0-9]').hasMatch(password);
    bool hasSpecialCharacters = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

    return hasUppercase && hasLowercase && hasNumbers && hasSpecialCharacters;
  }
}