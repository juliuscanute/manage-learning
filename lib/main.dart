import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:manage_learning/data/firebase_service.dart';
import 'package:manage_learning/ui/add_cards_page.dart';
import 'package:manage_learning/ui/category_screen.dart';
import 'package:manage_learning/ui/decks_page.dart';
import 'package:manage_learning/ui/edit_cards_page.dart';
import 'package:manage_learning/ui/cards_page_view.dart';
import 'package:manage_learning/ui/login_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:manage_learning/ui/smart_cards_page.dart';
import 'package:provider/provider.dart';

void main() async {
  await initializeFirebase();
  runApp(const MyApp());
}

Future<Map<String, dynamic>> loadConfig() async {
  try {
    final response = await http.get(Uri.parse('config.json'));
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      // Handle the case when the file is not found or other server errors
      print('Failed to load config.json: ${response.statusCode}');
    }
  } catch (e) {
    // Handle any other types of errors (e.g., parsing errors)
    print('An error occurred while loading config.json: $e');
  }
  return {};
}

Future<bool> initializeFirebase() async {
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
  return true;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirebaseService>(
          create: (_) => FirebaseService(),
        )
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Welcome to John Louis academy',
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
            if (snapshot.connectionState == ConnectionState.active) {
              return snapshot.data != null
                  ? const DecksPage()
                  : const LoginScreen();
            }
            return const CircularProgressIndicator();
          },
        ),
        onGenerateRoute: (settings) {
          return PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) {
                if (settings.name == '/login') {
                  return const LoginScreen();
                } else if (settings.name == '/decks') {
                  return const DecksPage();
                } else if (settings.name == '/addcards') {
                  return const CardsPageView(
                    deckId: null,
                    operation: DeckOperation.create,
                  );
                } else if (settings.name == '/editcards') {
                  return CardsPageView(
                    deckId: settings.arguments as String,
                    operation: DeckOperation.edit,
                  );
                } else if (settings.name == '/category-screen') {
                  final args = settings.arguments as Map<String, dynamic>;
                  final decks = args['decks'] as List<Map<String, dynamic>>;
                  final categoryList = args['categoryList'] as List<String>;
                  return CategoryScreen(
                      categoryList: categoryList, decks: decks);
                } else if (settings.name == '/smart-deck') {
                  return SmartCardPage();
                }
                return Container();
              },
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero);
        },
      ),
    );
  }
}
