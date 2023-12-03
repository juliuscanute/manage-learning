import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:manage_learning/login_screen.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

void main() async {
  initializeFirebase();
  runApp(MyApp());
}

Future<Map<String, dynamic>> loadConfig() async {
  try {
    final configString = await rootBundle.loadString('config.json');
    return json.decode(configString) as Map<String, dynamic>;
    // ignore: empty_catches
  } catch (e) {}
  return {};
}

void initializeFirebase() async {
  await dotenv.load(fileName: ".env", isOptional: true);
  final config = await loadConfig();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY'] ?? config['apiKey'],
      authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? config['authDomain'],
      projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? config['projectId'],
      storageBucket:
          dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? config['storageBucket'],
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ??
          config['messagingSenderId'],
      appId: dotenv.env['FIREBASE_APP_ID'] ?? config['appId'],
      measurementId:
          dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? config['measurementId'],
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Welcome to John Louis academy',
      home: LoginScreen(),
    );
  }
}
