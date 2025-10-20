import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
// import 'core/services/push_notification_service.dart';
// import 'core/services/ai_recommendation_service.dart';
// import 'core/services/social_community_service.dart';
// import 'core/services/performance_monitoring_service.dart';
// import 'core/services/data_sync_service.dart';
import 'core/services/firebase_test_service.dart';
import 'presentation/themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Initialize services
  await _initializeServices();
  
  runApp(const SecondHandMarketplaceApp());
}

Future<void> _initializeServices() async {
  try {
    print('\ud83d\udd25 Starting Firebase initialization...');
    
    // Test Firebase connection
    await FirebaseTestService().runAllTests();
    
    print('\u2705 Firebase services initialized successfully');
    
  } catch (e) {
    print('\u274c Error initializing Firebase services: $e');
  }
}

class SecondHandMarketplaceApp extends StatelessWidget {
  const SecondHandMarketplaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SecondHand Marketplace',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
