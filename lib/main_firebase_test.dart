import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/services/firebase_test_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const FirebaseTestApp());
}

class FirebaseTestApp extends StatelessWidget {
  const FirebaseTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Connection Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const FirebaseTestPage(),
    );
  }
}

class FirebaseTestPage extends StatefulWidget {
  const FirebaseTestPage({super.key});

  @override
  State<FirebaseTestPage> createState() => _FirebaseTestPageState();
}

class _FirebaseTestPageState extends State<FirebaseTestPage> {
  Map<String, bool>? testResults;
  bool isLoading = false;
  Map<String, String>? firebaseInfo;

  @override
  void initState() {
    super.initState();
    _loadFirebaseInfo();
  }

  Future<void> _loadFirebaseInfo() async {
    try {
      final info = await FirebaseTestService().getFirebaseInfo();
      setState(() {
        firebaseInfo = info;
      });
    } catch (e) {
      print('Error loading Firebase info: $e');
    }
  }

  Future<void> _runFirebaseTests() async {
    setState(() {
      isLoading = true;
      testResults = null;
    });

    try {
      final results = await FirebaseTestService().runAllTests();
      setState(() {
        testResults = results;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error running tests: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔥 Firebase Connection Test'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Firebase Project Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📊 Firebase Project Info',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (firebaseInfo != null) ...[
                      _buildInfoRow('Project ID', firebaseInfo!['projectId']!),
                      _buildInfoRow('App ID', firebaseInfo!['appId']!),
                      _buildInfoRow('Messaging Sender ID', firebaseInfo!['messagingSenderId']!),
                      _buildInfoRow('API Key', firebaseInfo!['apiKey']!),
                    ] else
                      const CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Test Button
            Center(
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : _runFirebaseTests,
                icon: Icon(isLoading ? Icons.hourglass_empty : Icons.play_arrow),
                label: Text(isLoading ? 'Running Tests...' : 'Run Firebase Tests'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Test Results
            if (isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Testing Firebase services...'),
                  ],
                ),
              )
            else if (testResults != null)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🧪 Test Results',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView(
                            children: testResults!.entries.map((entry) {
                              final service = entry.key;
                              final success = entry.value;
                              return ListTile(
                                leading: Icon(
                                  success ? Icons.check_circle : Icons.error,
                                  color: success ? Colors.green : Colors.red,
                                ),
                                title: Text(
                                  service.toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(success ? 'Connected successfully' : 'Connection failed'),
                                trailing: Chip(
                                  label: Text(
                                    success ? 'PASS' : 'FAIL',
                                    style: TextStyle(
                                      color: success ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor: success 
                                      ? Colors.green.withOpacity(0.1) 
                                      : Colors.red.withOpacity(0.1),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Overall Status
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _getOverallStatus() ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getOverallStatus() ? Colors.green : Colors.red,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            _getOverallStatus() 
                                ? '✅ All Firebase services are working correctly!'
                                : '❌ Some Firebase services have issues',
                            style: TextStyle(
                              color: _getOverallStatus() ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  bool _getOverallStatus() {
    if (testResults == null) return false;
    return testResults!.values.every((result) => result);
  }
}