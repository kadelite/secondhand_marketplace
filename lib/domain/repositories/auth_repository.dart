import '../entities/user.dart';

abstract class AuthRepository {
  /// Login with email and password
  Future<User> loginWithEmail({
    required String email,
    required String password,
  });

  /// Register with email and password
  Future<User> registerWithEmail({
    required String email,
    required String password,
    required String name,
  });

  /// Login with Google
  Future<User> loginWithGoogle();

  /// Login with Facebook
  Future<User> loginWithFacebook();

  /// Login with Apple
  Future<User> loginWithApple();

  /// Send magic link for passwordless login
  Future<void> sendMagicLink({required String email});

  /// Login with magic link token
  Future<User> loginWithMagicLink({required String token});

  /// Send OTP via SMS
  Future<void> sendOtpSms({required String phoneNumber});

  /// Send OTP via email
  Future<void> sendOtpEmail({required String email});

  /// Verify OTP
  Future<User> verifyOtp({
    required String identifier, // phone or email
    required String otp,
  });

  /// Biometric login (mobile only)
  Future<User> loginWithBiometrics();

  /// Send email verification
  Future<void> sendEmailVerification();

  /// Verify email with token
  Future<void> verifyEmail({required String token});

  /// Logout
  Future<void> logout();

  /// Get current user
  Future<User?> getCurrentUser();

  /// Check if user is authenticated
  Future<bool> isAuthenticated();

  /// Refresh authentication token
  Future<String> refreshToken();

  /// Update user profile
  Future<User> updateProfile({
    String? name,
    String? profileImageUrl,
    String? phoneNumber,
    String? address,
  });

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Reset password
  Future<void> resetPassword({required String email});

  /// Delete account
  Future<void> deleteAccount();
}