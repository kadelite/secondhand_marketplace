import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:otp/otp.dart';
import 'package:uuid/uuid.dart';
import '../utils/jwt_service.dart';

enum AuthMethod {
  email,
  phone,
  google,
  apple,
  biometric,
  magicLink,
}

enum MFAMethod {
  sms,
  email,
  authenticatorApp,
  biometric,
}

class AdvancedAuthService {
  static final AdvancedAuthService _instance = AdvancedAuthService._internal();
  factory AdvancedAuthService() => _instance;
  AdvancedAuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final Uuid _uuid = const Uuid();

  // JWT and Session Management
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  User? _currentUser;

  // MFA State
  String? _pendingMFAUserId;
  String? _mfaSecret;
  bool _mfaRequired = false;

  // Getters
  bool get isAuthenticated => _accessToken != null && !_isTokenExpired();
  bool get mfaRequired => _mfaRequired;
  User? get currentUser => _currentUser;
  String? get accessToken => _accessToken;

  // Initialize authentication service
  Future<void> initialize() async {
    await _loadStoredTokens();
    await _checkBiometricAvailability();
    _setupAutoTokenRefresh();
  }

  // Email/Password Authentication
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return await _handleSuccessfulAuth(credential.user!, rememberMe);
      }

      return AuthResult(success: false, error: 'Authentication failed');
    } catch (e) {
      return _handleAuthError(e);
    }
  }

  // Phone Authentication with OTP
  Future<AuthResult> signInWithPhone({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
  }) async {
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          final result = await _firebaseAuth.signInWithCredential(credential);
          if (result.user != null) {
            await _handleSuccessfulAuth(result.user!, true);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          // Handle error
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );

      return AuthResult(success: true, requiresVerification: true);
    } catch (e) {
      return _handleAuthError(e);
    }
  }

  // Verify phone OTP
  Future<AuthResult> verifyPhoneOTP({
    required String verificationId,
    required String otp,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final result = await _firebaseAuth.signInWithCredential(credential);
      if (result.user != null) {
        return await _handleSuccessfulAuth(result.user!, true);
      }

      return AuthResult(success: false, error: 'Verification failed');
    } catch (e) {
      return _handleAuthError(e);
    }
  }

  // Google Sign-In
  Future<AuthResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult(success: false, error: 'Google sign-in cancelled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _firebaseAuth.signInWithCredential(credential);
      if (result.user != null) {
        return await _handleSuccessfulAuth(result.user!, true);
      }

      return AuthResult(success: false, error: 'Google authentication failed');
    } catch (e) {
      return _handleAuthError(e);
    }
  }

  // Biometric Authentication
  Future<AuthResult> signInWithBiometric() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) {
        return AuthResult(success: false, error: 'Biometric authentication not available');
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your account',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        // Load stored user credentials and sign in
        final storedCredentials = await _loadStoredBiometricCredentials();
        if (storedCredentials != null) {
          return await signInWithEmail(
            email: storedCredentials['email'],
            password: storedCredentials['password'],
            rememberMe: true,
          );
        }
      }

      return AuthResult(success: false, error: 'Biometric authentication failed');
    } catch (e) {
      return _handleAuthError(e);
    }
  }

  // Magic Link Authentication
  Future<AuthResult> sendMagicLink(String email) async {
    try {
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://yourapp.com/auth/verify',
        handleCodeInApp: true,
        androidPackageName: 'com.yourapp.secondhand_marketplace',
        iOSBundleId: 'com.yourapp.secondhandMarketplace',
      );

      await _firebaseAuth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );

      return AuthResult(success: true, requiresVerification: true);
    } catch (e) {
      return _handleAuthError(e);
    }
  }

  // Multi-Factor Authentication Setup
  Future<MFASetupResult> setupMFA(MFAMethod method) async {
    if (_currentUser == null) {
      return MFASetupResult(success: false, error: 'User not authenticated');
    }

    try {
      switch (method) {
        case MFAMethod.authenticatorApp:
          return await _setupTOTP();
        case MFAMethod.sms:
          return await _setupSMSMFA();
        case MFAMethod.email:
          return await _setupEmailMFA();
        case MFAMethod.biometric:
          return await _setupBiometricMFA();
      }
    } catch (e) {
      return MFASetupResult(success: false, error: e.toString());
    }
  }

  // TOTP Setup for Authenticator Apps
  Future<MFASetupResult> _setupTOTP() async {
    final secret = _generateTOTPSecret();
    final qrCode = _generateQRCode(secret);
    
    await _storeMFASecret(secret);
    
    return MFASetupResult(
      success: true,
      secret: secret,
      qrCode: qrCode,
    );
  }

  // Verify MFA Code
  Future<bool> verifyMFACode(String code, MFAMethod method) async {
    try {
      switch (method) {
        case MFAMethod.authenticatorApp:
          return _verifyTOTP(code);
        case MFAMethod.sms:
          return await _verifySMSCode(code);
        case MFAMethod.email:
          return await _verifyEmailCode(code);
        case MFAMethod.biometric:
          return await _verifyBiometric();
      }
    } catch (e) {
      return false;
    }
  }

  // Token Management
  Future<bool> refreshToken() async {
    if (_refreshToken == null) return false;

    try {
      // Call your backend API to refresh the token
      final response = await _callRefreshTokenAPI(_refreshToken!);
      
      if (response['success']) {
        _accessToken = response['access_token'];
        _refreshToken = response['refresh_token'];
        _tokenExpiry = DateTime.now().add(
          Duration(seconds: response['expires_in']),
        );
        
        await _storeTokens();
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // Sensitive Action Authentication
  Future<bool> authenticateForSensitiveAction({
    required String action,
    MFAMethod? preferredMethod,
  }) async {
    final userSettings = await _getUserSecuritySettings();
    final requiredMethods = userSettings['sensitive_actions'][action] ?? [];

    // Check if biometric is preferred and available
    if (preferredMethod == MFAMethod.biometric || 
        requiredMethods.contains('biometric')) {
      return await _verifyBiometric();
    }

    // Fallback to TOTP or SMS
    if (requiredMethods.contains('totp')) {
      // Prompt user for TOTP code
      return false; // This would trigger UI to collect TOTP
    }

    return false;
  }

  // Sign Out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
    await _clearStoredTokens();
    
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
    _currentUser = null;
    _mfaRequired = false;
  }

  // Private Helper Methods
  Future<AuthResult> _handleSuccessfulAuth(User user, bool rememberMe) async {
    _currentUser = user;
    
    // Check if MFA is required
    final mfaSettings = await _checkMFARequirement(user.uid);
    if (mfaSettings['required']) {
      _mfaRequired = true;
      _pendingMFAUserId = user.uid;
      return AuthResult(success: true, requiresMFA: true);
    }

    // Generate JWT tokens
    final tokens = await _generateTokens(user);
    _accessToken = tokens['access_token'];
    _refreshToken = tokens['refresh_token'];
    _tokenExpiry = DateTime.now().add(Duration(seconds: tokens['expires_in']));

    if (rememberMe) {
      await _storeTokens();
    }

    return AuthResult(success: true, user: user);
  }

  bool _isTokenExpired() {
    if (_tokenExpiry == null) return true;
    return DateTime.now().isAfter(_tokenExpiry!);
  }

  String _generateTOTPSecret() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _generateQRCode(String secret) {
    final issuer = 'SecondHand Marketplace';
    final accountName = _currentUser?.email ?? 'User';
    return 'otpauth://totp/$issuer:$accountName?secret=$secret&issuer=$issuer';
  }

  bool _verifyTOTP(String code) {
    if (_mfaSecret == null) return false;
    
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expectedCode = OTP.generateTOTPCodeString(
      _mfaSecret!,
      currentTime,
      algorithm: Algorithm.SHA1,
      digits: 6,
      interval: 30,
    );
    
    return code == expectedCode;
  }

  Future<bool> _verifyBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to continue',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  // Storage and Persistence
  Future<void> _storeTokens() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) {
      await prefs.setString('access_token', _accessToken!);
    }
    if (_refreshToken != null) {
      await prefs.setString('refresh_token', _refreshToken!);
    }
    if (_tokenExpiry != null) {
      await prefs.setString('token_expiry', _tokenExpiry!.toIso8601String());
    }
  }

  Future<void> _loadStoredTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
    
    final expiryString = prefs.getString('token_expiry');
    if (expiryString != null) {
      _tokenExpiry = DateTime.parse(expiryString);
    }
  }

  Future<void> _clearStoredTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('token_expiry');
  }

  // Placeholder methods for backend integration
  Future<Map<String, dynamic>> _generateTokens(User user) async {
    // This would call your backend API to generate JWT tokens
    return {
      'access_token': 'jwt_access_token',
      'refresh_token': 'jwt_refresh_token',
      'expires_in': 3600,
    };
  }

  Future<Map<String, dynamic>> _callRefreshTokenAPI(String refreshToken) async {
    // This would call your backend API to refresh the token
    return {'success': true};
  }

  Future<Map<String, dynamic>> _checkMFARequirement(String userId) async {
    // This would check backend for user's MFA settings
    return {'required': false};
  }

  Future<Map<String, dynamic>> _getUserSecuritySettings() async {
    // This would fetch user's security settings from backend
    return {
      'sensitive_actions': {
        'profile_update': ['biometric', 'totp'],
        'withdrawal': ['biometric', 'totp', 'sms'],
        'delete_account': ['biometric', 'totp', 'email'],
      }
    };
  }

  // Additional placeholder methods
  Future<void> _checkBiometricAvailability() async {}
  void _setupAutoTokenRefresh() {}
  Future<Map<String, String>?> _loadStoredBiometricCredentials() async => null;
  Future<MFASetupResult> _setupSMSMFA() async => MFASetupResult(success: false);
  Future<MFASetupResult> _setupEmailMFA() async => MFASetupResult(success: false);
  Future<MFASetupResult> _setupBiometricMFA() async => MFASetupResult(success: false);
  Future<bool> _verifySMSCode(String code) async => false;
  Future<bool> _verifyEmailCode(String code) async => false;
  Future<void> _storeMFASecret(String secret) async {}
  AuthResult _handleAuthError(dynamic error) => AuthResult(success: false, error: error.toString());
}

// Result Classes
class AuthResult {
  final bool success;
  final String? error;
  final User? user;
  final bool requiresMFA;
  final bool requiresVerification;

  AuthResult({
    required this.success,
    this.error,
    this.user,
    this.requiresMFA = false,
    this.requiresVerification = false,
  });
}

class MFASetupResult {
  final bool success;
  final String? error;
  final String? secret;
  final String? qrCode;

  MFASetupResult({
    required this.success,
    this.error,
    this.secret,
    this.qrCode,
  });
}