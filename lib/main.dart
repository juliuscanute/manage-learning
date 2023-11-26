import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:manage_learning/login_screen.dart';

void main() async {
  initializeFirebase();
  runApp(MyApp());
}

void initializeFirebase() async {
  await dotenv.load(fileName: ".env", isOptional: true);
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY'] ??
          const String.fromEnvironment('FIREBASE_API_KEY'),
      authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ??
          const String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
      projectId: dotenv.env['FIREBASE_PROJECT_ID'] ??
          const String.fromEnvironment('FIREBASE_PROJECT_ID'),
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ??
          const String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ??
          const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
      appId: dotenv.env['FIREBASE_APP_ID'] ??
          const String.fromEnvironment('FIREBASE_APP_ID'),
      measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'] ??
          const String.fromEnvironment('FIREBASE_MEASUREMENT_ID'),
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
