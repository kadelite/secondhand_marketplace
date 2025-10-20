import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseTestService {
  static final FirebaseTestService _instance = FirebaseTestService._internal();
  factory FirebaseTestService() => _instance;
  FirebaseTestService._internal();

  /// Test Firebase Core connection
  Future<bool> testFirebaseCore() async {
    try {
      final FirebaseApp app = Firebase.app();
      print('✅ Firebase Core: Connected to project ${app.options.projectId}');
      return true;
    } catch (e) {
      print('❌ Firebase Core: Connection failed - $e');
      return false;
    }
  }

  /// Test Firestore connection
  Future<bool> testFirestore() async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // Try to write a test document
      await firestore.collection('test').doc('connection_test').set({
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Firebase connection test successful',
      });
      
      // Try to read the document back
      final doc = await firestore.collection('test').doc('connection_test').get();
      
      if (doc.exists) {
        print('✅ Firestore: Connection successful, data: ${doc.data()}');
        return true;
      } else {
        print('❌ Firestore: Document not found');
        return false;
      }
    } catch (e) {
      print('❌ Firestore: Connection failed - $e');
      return false;
    }
  }

  /// Test Firebase Auth
  Future<bool> testFirebaseAuth() async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? user = auth.currentUser;
      
      if (user != null) {
        print('✅ Firebase Auth: User signed in - ${user.email ?? user.uid}');
      } else {
        print('✅ Firebase Auth: No user signed in (auth service working)');
      }
      
      return true;
    } catch (e) {
      print('❌ Firebase Auth: Connection failed - $e');
      return false;
    }
  }

  /// Test Firebase Messaging
  Future<bool> testFirebaseMessaging() async {
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      
      // Request permission (for iOS/web)
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        provisional: false,
        sound: true,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Firebase Messaging: Permission granted');
        
        // Get FCM token
        String? token = await messaging.getToken();
        if (token != null) {
          print('✅ Firebase Messaging: FCM Token received (length: ${token.length})');
          return true;
        } else {
          print('❌ Firebase Messaging: Failed to get FCM token');
          return false;
        }
      } else {
        print('❌ Firebase Messaging: Permission not granted');
        return false;
      }
    } catch (e) {
      print('❌ Firebase Messaging: Connection failed - $e');
      return false;
    }
  }

  /// Run all Firebase tests
  Future<Map<String, bool>> runAllTests() async {
    print('🔥 Starting Firebase Connection Tests...\n');
    
    final Map<String, bool> results = {
      'core': await testFirebaseCore(),
      'firestore': await testFirestore(),
      'auth': await testFirebaseAuth(),
      'messaging': await testFirebaseMessaging(),
    };
    
    print('\n📊 Firebase Test Results:');
    results.forEach((service, success) {
      final icon = success ? '✅' : '❌';
      print('$icon $service: ${success ? 'PASSED' : 'FAILED'}');
    });
    
    final allPassed = results.values.every((result) => result);
    print('\n🎯 Overall Status: ${allPassed ? "ALL TESTS PASSED" : "SOME TESTS FAILED"}');
    
    return results;
  }

  /// Get Firebase project info
  Future<Map<String, String>> getFirebaseInfo() async {
    final app = Firebase.app();
    return {
      'projectId': app.options.projectId ?? 'unknown',
      'appId': app.options.appId ?? 'unknown',
      'messagingSenderId': app.options.messagingSenderId ?? 'unknown',
      'apiKey': app.options.apiKey.substring(0, 10) + '...' // Show only first 10 chars for security
    };
  }
}