import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';

enum SupportedLanguage {
  english('en', 'US', 'English'),
  spanish('es', 'ES', 'Español'),
  french('fr', 'FR', 'Français'),
  german('de', 'DE', 'Deutsch'),
  italian('it', 'IT', 'Italiano'),
  portuguese('pt', 'BR', 'Português'),
  chinese('zh', 'CN', '中文'),
  japanese('ja', 'JP', '日本語'),
  korean('ko', 'KR', '한국어'),
  arabic('ar', 'SA', 'العربية'),
  hindi('hi', 'IN', 'हिन्दी'),
  russian('ru', 'RU', 'Русский');

  const SupportedLanguage(this.code, this.countryCode, this.displayName);
  final String code;
  final String countryCode;
  final String displayName;

  Locale get locale => Locale(code, countryCode);
}

enum CurrencyCode {
  usd('USD', '\$', 'US Dollar'),
  eur('EUR', '€', 'Euro'),
  gbp('GBP', '£', 'British Pound'),
  jpy('JPY', '¥', 'Japanese Yen'),
  cny('CNY', '¥', 'Chinese Yuan'),
  inr('INR', '₹', 'Indian Rupee'),
  brl('BRL', 'R\$', 'Brazilian Real'),
  cad('CAD', 'C\$', 'Canadian Dollar'),
  aud('AUD', 'A\$', 'Australian Dollar'),
  chf('CHF', 'CHF', 'Swiss Franc'),
  rub('RUB', '₽', 'Russian Ruble'),
  krw('KRW', '₩', 'South Korean Won');

  const CurrencyCode(this.code, this.symbol, this.displayName);
  final String code;
  final String symbol;
  final String displayName;
}

enum AccessibilityLevel {
  none,
  basic,
  enhanced,
  full,
}

class LocalizationService {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  // Text-to-Speech
  final FlutterTts _tts = FlutterTts();
  bool _ttsEnabled = false;
  
  // Current Settings
  SupportedLanguage _currentLanguage = SupportedLanguage.english;
  CurrencyCode _currentCurrency = CurrencyCode.usd;
  AccessibilityLevel _accessibilityLevel = AccessibilityLevel.basic;
  bool _rtlEnabled = false;
  
  // Accessibility Settings
  double _fontScale = 1.0;
  bool _highContrastEnabled = false;
  bool _reduceAnimationsEnabled = false;
  bool _screenReaderEnabled = false;
  bool _hapticFeedbackEnabled = true;

  // Getters
  SupportedLanguage get currentLanguage => _currentLanguage;
  CurrencyCode get currentCurrency => _currentCurrency;
  Locale get currentLocale => _currentLanguage.locale;
  bool get isRTL => _rtlEnabled;
  double get fontScale => _fontScale;
  bool get isHighContrastEnabled => _highContrastEnabled;
  bool get isScreenReaderEnabled => _screenReaderEnabled;
  AccessibilityLevel get accessibilityLevel => _accessibilityLevel;

  // Initialize the service
  Future<void> initialize() async {
    await _loadSavedSettings();
    await _initializeTTS();
    await _detectSystemSettings();
  }

  // Language Management
  Future<void> changeLanguage(SupportedLanguage language) async {
    _currentLanguage = language;
    _rtlEnabled = _isRTLLanguage(language);
    
    await _saveLanguageSettings();
    await _configureTTSLanguage();
    
    // Notify listeners about language change
    _notifyLanguageChange();
  }

  String translate(String key, {Map<String, dynamic>? params}) {
    final translations = _getTranslationsForLanguage(_currentLanguage);
    String translation = translations[key] ?? key;
    
    // Replace parameters if provided
    if (params != null) {
      params.forEach((paramKey, value) {
        translation = translation.replaceAll('{$paramKey}', value.toString());
      });
    }
    
    return translation;
  }

  // Currency Management
  Future<void> changeCurrency(CurrencyCode currency) async {
    _currentCurrency = currency;
    await _saveCurrencySettings();
    _notifyCurrencyChange();
  }

  String formatCurrency(double amount, {bool includeSymbol = true}) {
    final formatter = NumberFormat.currency(
      locale: _currentLanguage.code,
      symbol: includeSymbol ? _currentCurrency.symbol : '',
      name: _currentCurrency.code,
    );
    
    return formatter.format(amount);
  }

  Future<double> convertCurrency({
    required double amount,
    required CurrencyCode from,
    required CurrencyCode to,
  }) async {
    // In a real app, this would call a currency conversion API
    final exchangeRates = await _getExchangeRates();
    
    final fromRate = exchangeRates[from.code] ?? 1.0;
    final toRate = exchangeRates[to.code] ?? 1.0;
    
    return (amount / fromRate) * toRate;
  }

  // Accessibility Features
  Future<void> enableScreenReader(bool enabled) async {
    _screenReaderEnabled = enabled;
    
    if (enabled) {
      await _configureTTSForScreenReader();
      await _enableSemanticLabels();
    } else {
      await _tts.stop();
    }
    
    await _saveAccessibilitySettings();
  }

  Future<void> speakText(String text) async {
    if (_screenReaderEnabled && _ttsEnabled) {
      await _tts.speak(text);
    }
  }

  Future<void> setFontScale(double scale) async {
    _fontScale = scale.clamp(0.8, 2.0);
    await _saveAccessibilitySettings();
    _notifyFontScaleChange();
  }

  Future<void> enableHighContrast(bool enabled) async {
    _highContrastEnabled = enabled;
    await _saveAccessibilitySettings();
    _notifyContrastChange();
  }

  Future<void> enableReducedAnimations(bool enabled) async {
    _reduceAnimationsEnabled = enabled;
    await _saveAccessibilitySettings();
    _notifyAnimationChange();
  }

  Future<void> enableHapticFeedback(bool enabled) async {
    _hapticFeedbackEnabled = enabled;
    await _saveAccessibilitySettings();
  }

  void triggerHapticFeedback({HapticFeedbackType type = HapticFeedbackType.lightImpact}) {
    if (_hapticFeedbackEnabled) {
      switch (type) {
        case HapticFeedbackType.lightImpact:
          HapticFeedback.lightImpact();
          break;
        case HapticFeedbackType.mediumImpact:
          HapticFeedback.mediumImpact();
          break;
        case HapticFeedbackType.heavyImpact:
          HapticFeedback.heavyImpact();
          break;
        case HapticFeedbackType.selectionClick:
          HapticFeedback.selectionClick();
          break;
        case HapticFeedbackType.vibrate:
          HapticFeedback.vibrate();
          break;
      }
    }
  }

  // Date and Time Formatting
  String formatDate(DateTime date, {String? pattern}) {
    final formatter = DateFormat(
      pattern ?? DateFormat.yMMMd().pattern,
      _currentLanguage.code,
    );
    return formatter.format(date);
  }

  String formatTime(DateTime time) {
    final formatter = DateFormat.jm(_currentLanguage.code);
    return formatter.format(time);
  }

  String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return formatDate(dateTime);
    } else if (difference.inDays > 0) {
      return translate('days_ago', {'count': difference.inDays});
    } else if (difference.inHours > 0) {
      return translate('hours_ago', {'count': difference.inHours});
    } else if (difference.inMinutes > 0) {
      return translate('minutes_ago', {'count': difference.inMinutes});
    } else {
      return translate('just_now');
    }
  }

  // Number Formatting
  String formatNumber(num number) {
    final formatter = NumberFormat.decimalPattern(_currentLanguage.code);
    return formatter.format(number);
  }

  String formatCompactNumber(num number) {
    final formatter = NumberFormat.compact(locale: _currentLanguage.code);
    return formatter.format(number);
  }

  // Theme Customization
  ThemeData getAccessibleTheme(ThemeData baseTheme) {
    ThemeData theme = baseTheme;
    
    // Apply font scale
    theme = theme.copyWith(
      textTheme: theme.textTheme.apply(fontSizeFactor: _fontScale),
      primaryTextTheme: theme.primaryTextTheme.apply(fontSizeFactor: _fontScale),
    );
    
    // Apply high contrast
    if (_highContrastEnabled) {
      theme = _applyHighContrastColors(theme);
    }
    
    // Apply RTL support
    if (_rtlEnabled) {
      theme = theme.copyWith(
        visualDensity: VisualDensity.standard,
      );
    }
    
    return theme;
  }

  // Auto-detect system settings
  Future<void> _detectSystemSettings() async {
    // Detect system locale
    final systemLocale = ui.window.locale;
    final matchingLanguage = SupportedLanguage.values
        .where((lang) => lang.code == systemLocale.languageCode)
        .firstOrNull;
    
    if (matchingLanguage != null && _currentLanguage == SupportedLanguage.english) {
      await changeLanguage(matchingLanguage);
    }
    
    // Detect accessibility settings
    final mediaQuery = MediaQueryData.fromWindow(ui.window);
    if (mediaQuery.accessibleNavigation) {
      _accessibilityLevel = AccessibilityLevel.enhanced;
      await enableScreenReader(true);
    }
    
    if (mediaQuery.highContrast) {
      await enableHighContrast(true);
    }
    
    if (mediaQuery.disableAnimations) {
      await enableReducedAnimations(true);
    }
    
    _fontScale = mediaQuery.textScaleFactor.clamp(0.8, 2.0);
  }

  // Private Helper Methods
  Future<void> _initializeTTS() async {
    _ttsEnabled = await _tts.isLanguageAvailable(_currentLanguage.code);
    
    if (_ttsEnabled) {
      await _tts.setLanguage(_currentLanguage.code);
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);
    }
  }

  Future<void> _configureTTSLanguage() async {
    if (_ttsEnabled) {
      await _tts.setLanguage(_currentLanguage.code);
    }
  }

  Future<void> _configureTTSForScreenReader() async {
    await _tts.setSpeechRate(0.6);
    await _tts.setPitch(1.0);
    await _tts.setVolume(0.8);
  }

  bool _isRTLLanguage(SupportedLanguage language) {
    return language == SupportedLanguage.arabic;
  }

  Map<String, String> _getTranslationsForLanguage(SupportedLanguage language) {
    // In a real app, this would load from JSON files or a translation service
    switch (language) {
      case SupportedLanguage.english:
        return _englishTranslations;
      case SupportedLanguage.spanish:
        return _spanishTranslations;
      case SupportedLanguage.french:
        return _frenchTranslations;
      // Add other languages...
      default:
        return _englishTranslations;
    }
  }

  Future<Map<String, double>> _getExchangeRates() async {
    // In a real app, this would call a currency API
    return {
      'USD': 1.0,
      'EUR': 0.85,
      'GBP': 0.73,
      'JPY': 110.0,
      'CNY': 6.45,
      'INR': 74.5,
      'BRL': 5.2,
      'CAD': 1.25,
      'AUD': 1.35,
      'CHF': 0.92,
      'RUB': 75.0,
      'KRW': 1180.0,
    };
  }

  ThemeData _applyHighContrastColors(ThemeData theme) {
    return theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(
        primary: Colors.black,
        secondary: Colors.white,
        surface: Colors.white,
        background: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.black,
        onBackground: Colors.black,
      ),
      cardColor: Colors.white,
      scaffoldBackgroundColor: Colors.white,
    );
  }

  // Storage Methods
  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final languageCode = prefs.getString('language_code');
    if (languageCode != null) {
      _currentLanguage = SupportedLanguage.values
          .where((lang) => lang.code == languageCode)
          .firstOrNull ?? SupportedLanguage.english;
    }
    
    final currencyCode = prefs.getString('currency_code');
    if (currencyCode != null) {
      _currentCurrency = CurrencyCode.values
          .where((curr) => curr.code == currencyCode)
          .firstOrNull ?? CurrencyCode.usd;
    }
    
    _fontScale = prefs.getDouble('font_scale') ?? 1.0;
    _highContrastEnabled = prefs.getBool('high_contrast') ?? false;
    _reduceAnimationsEnabled = prefs.getBool('reduce_animations') ?? false;
    _screenReaderEnabled = prefs.getBool('screen_reader') ?? false;
    _hapticFeedbackEnabled = prefs.getBool('haptic_feedback') ?? true;
    _rtlEnabled = _isRTLLanguage(_currentLanguage);
  }

  Future<void> _saveLanguageSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', _currentLanguage.code);
    await prefs.setBool('rtl_enabled', _rtlEnabled);
  }

  Future<void> _saveCurrencySettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_code', _currentCurrency.code);
  }

  Future<void> _saveAccessibilitySettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_scale', _fontScale);
    await prefs.setBool('high_contrast', _highContrastEnabled);
    await prefs.setBool('reduce_animations', _reduceAnimationsEnabled);
    await prefs.setBool('screen_reader', _screenReaderEnabled);
    await prefs.setBool('haptic_feedback', _hapticFeedbackEnabled);
  }

  // Notification Methods (implement with your preferred state management)
  void _notifyLanguageChange() {
    // Implement with your state management solution
  }
  
  void _notifyCurrencyChange() {
    // Implement with your state management solution
  }
  
  void _notifyFontScaleChange() {
    // Implement with your state management solution
  }
  
  void _notifyContrastChange() {
    // Implement with your state management solution
  }
  
  void _notifyAnimationChange() {
    // Implement with your state management solution
  }

  Future<void> _enableSemanticLabels() async {
    // Enable semantic labels for screen readers
  }

  // Sample Translations (In a real app, load from JSON files)
  static const Map<String, String> _englishTranslations = {
    'welcome': 'Welcome',
    'login': 'Login',
    'register': 'Register',
    'email': 'Email',
    'password': 'Password',
    'forgot_password': 'Forgot Password?',
    'days_ago': '{count} days ago',
    'hours_ago': '{count} hours ago',
    'minutes_ago': '{count} minutes ago',
    'just_now': 'Just now',
    'search': 'Search',
    'categories': 'Categories',
    'profile': 'Profile',
    'settings': 'Settings',
    'logout': 'Logout',
    'product_not_found': 'Product not found',
    'loading': 'Loading...',
    'error': 'Error',
    'try_again': 'Try Again',
    'cancel': 'Cancel',
    'confirm': 'Confirm',
    'delete': 'Delete',
    'edit': 'Edit',
    'save': 'Save',
    'add_to_cart': 'Add to Cart',
    'buy_now': 'Buy Now',
    'price': 'Price',
    'description': 'Description',
    'seller': 'Seller',
    'condition': 'Condition',
    'location': 'Location',
    'message_seller': 'Message Seller',
    'report_item': 'Report Item',
    'share': 'Share',
    'favorite': 'Favorite',
  };

  static const Map<String, String> _spanishTranslations = {
    'welcome': 'Bienvenido',
    'login': 'Iniciar Sesión',
    'register': 'Registrarse',
    'email': 'Correo Electrónico',
    'password': 'Contraseña',
    'forgot_password': '¿Olvidaste tu contraseña?',
    'days_ago': 'Hace {count} días',
    'hours_ago': 'Hace {count} horas',
    'minutes_ago': 'Hace {count} minutos',
    'just_now': 'Ahora mismo',
    // Add more Spanish translations...
  };

  static const Map<String, String> _frenchTranslations = {
    'welcome': 'Bienvenue',
    'login': 'Se connecter',
    'register': 'S\'inscrire',
    'email': 'E-mail',
    'password': 'Mot de passe',
    'forgot_password': 'Mot de passe oublié?',
    'days_ago': 'Il y a {count} jours',
    'hours_ago': 'Il y a {count} heures',
    'minutes_ago': 'Il y a {count} minutes',
    'just_now': 'À l\'instant',
    // Add more French translations...
  };
}

enum HapticFeedbackType {
  lightImpact,
  mediumImpact,
  heavyImpact,
  selectionClick,
  vibrate,
}