import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JwtService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  /// Save access token to local storage
  static Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, token);
  }

  /// Save refresh token to local storage
  static Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, token);
  }

  /// Get access token from local storage
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// Get refresh token from local storage
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  /// Check if access token is expired
  static Future<bool> isAccessTokenExpired() async {
    final token = await getAccessToken();
    if (token == null) return true;

    try {
      return JwtDecoder.isExpired(token);
    } catch (e) {
      return true;
    }
  }

  /// Check if refresh token is expired
  static Future<bool> isRefreshTokenExpired() async {
    final token = await getRefreshToken();
    if (token == null) return true;

    try {
      return JwtDecoder.isExpired(token);
    } catch (e) {
      return true;
    }
  }

  /// Get user ID from access token
  static Future<String?> getUserId() async {
    final token = await getAccessToken();
    if (token == null) return null;

    try {
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      return decodedToken['sub'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Get token payload
  static Future<Map<String, dynamic>?> getTokenPayload() async {
    final token = await getAccessToken();
    if (token == null) return null;

    try {
      return JwtDecoder.decode(token);
    } catch (e) {
      return null;
    }
  }

  /// Clear all tokens
  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  /// Check if user is authenticated (has valid access token or valid refresh token)
  static Future<bool> isAuthenticated() async {
    final hasValidAccessToken = !(await isAccessTokenExpired());
    if (hasValidAccessToken) return true;

    final hasValidRefreshToken = !(await isRefreshTokenExpired());
    return hasValidRefreshToken;
  }

  /// Get remaining time until token expires (in minutes)
  static Future<int> getTokenExpirationTime() async {
    final token = await getAccessToken();
    if (token == null) return 0;

    try {
      final expirationDate = JwtDecoder.getExpirationDate(token);
      final now = DateTime.now();
      if (expirationDate.isBefore(now)) return 0;
      
      return expirationDate.difference(now).inMinutes;
    } catch (e) {
      return 0;
    }
  }
}