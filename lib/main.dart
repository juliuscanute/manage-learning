import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:manage_learning/data/firebase_service.dart';
import 'package:manage_learning/ui/accounts/account_repository.dart';
import 'package:manage_learning/ui/accounts/create_account.dart';
import 'package:manage_learning/ui/accounts/view_accounts.dart';
import 'package:manage_learning/ui/blog_repository.dart';
import 'package:manage_learning/ui/blogs/blog_subfolder_screen.dart';
import 'package:manage_learning/ui/blogs_create.dart';
import 'package:manage_learning/ui/category_screen_subfolder_new.dart';
import 'package:manage_learning/ui/decks_page.dart';
import 'package:manage_learning/ui/cards_page_view.dart';
import 'package:manage_learning/ui/login_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

Future<Map<String, dynamic>> loadConfig() async {
  try {
    final response = await http.get(Uri.parse('config.json'));
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      print('Failed to load config.json: ${response.statusCode}');
    }
  } catch (e) {
    print('An error occurred while loading config.json: $e');
  }
  return {};
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env and fallback config values
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

  runApp(MyApp(config: config));
}

class MyApp extends StatelessWidget {
  final Map<String, dynamic> config;
  const MyApp({Key? key, required this.config}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirebaseService>(
          create: (_) => FirebaseService(),
          lazy: false,
        ),
        Provider<BlogRepository>(
          create: (_) => BlogRepository(),
          lazy: false,
        ),
        Provider<AccountRepository>(
          create: (_) => AccountRepository(
            apiBaseUrl: dotenv.env['API_BASE_URL'] ?? config['apiBaseUrl'],
          ),
        ),
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
                } else if (settings.name == '/accounts') {
                  return ViewAccounts();
                } else if (settings.name == '/create-account') {
                  return CreateAccount();
                } else if (settings.name == '/addcards') {
                  return const CardsPageView(
                    deck: {},
                    operation: DeckOperation.create,
                  );
                } else if (settings.name == '/editcards') {
                  return CardsPageView(
                    deck: settings.arguments as Map<String, dynamic>,
                    operation: DeckOperation.edit,
                  );
                } else if (settings.name == '/category-screen-new') {
                  final args = settings.arguments as Map<String, dynamic>;
                  final parentPath = args['parentPath'] as String;
                  final subFolders =
                      args['subFolders'] as List<Map<String, dynamic>>;
                  final parentId = args['folderId'] as String;
                  return SubfolderScreen(
                    parentFolderName: parentId,
                    parentPath: parentPath,
                    subFolders: subFolders,
                  );
                } else if (settings.name == '/smart-deck') {
                  return const CardsPageView(
                      deck: {}, operation: DeckOperation.load);
                } else if (settings.name == '/blog-updates') {
                  final data = settings.arguments as BlogData;
                  return BlogCreateEdit(blogData: data);
                } else if (settings.name == '/blog-category-screen-new') {
                  final args = settings.arguments as Map<String, dynamic>;
                  final parentPath = args['parentPath'] as String;
                  final subFolders =
                      args['subFolders'] as List<Map<String, dynamic>>;
                  final parentId = args['folderId'] as String;
                  return BlogSubfolderScreen(
                    parentFolderName: parentId,
                    parentPath: parentPath,
                    subFolders: subFolders,
                  );
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
