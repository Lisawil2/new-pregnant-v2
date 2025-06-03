import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pregnancy_chatbot/screens/home_screen.dart';
import 'package:pregnancy_chatbot/screens/onboarding_screen.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/tracker_screen.dart';
import 'screens/chat_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  bool firebaseInitialized = false;
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase initialized successfully.');
      firebaseInitialized = true;
    } catch (e, stackTrace) {
      debugPrint('Firebase initialization error: $e\n$stackTrace');
    }
  } else {
    debugPrint('Firebase already initialized.');
    firebaseInitialized = true;
  }

  // Initialize DotEnv
  bool dotEnvInitialized = false;
  try {
    await dotenv.load(fileName: ".env");
    if (dotenv.env['DEEPSEEK_API_KEY']?.isNotEmpty ?? false) {
      dotEnvInitialized = true;
      debugPrint('DotEnv initialized successfully.');
    } else {
      debugPrint('Warning: API_KEY is missing or empty in .env file.');
    }
  } catch (e, stackTrace) {
    debugPrint('Error loading DotEnv: $e\n$stackTrace');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider(dotEnvInitialized: dotEnvInitialized, firebaseInitialized: firebaseInitialized)),
      ],
      child: MyApp(
        dotEnvInitialized: dotEnvInitialized,
        firebaseInitialized: firebaseInitialized,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool dotEnvInitialized;
  final bool firebaseInitialized;

  const MyApp({
    super.key,
    required this.dotEnvInitialized,
    required this.firebaseInitialized,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BloomMama',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.pink,
          accentColor: Colors.pinkAccent,
          backgroundColor: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.pink,
          foregroundColor: Colors.white,
          elevation: 1,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/': (context) => const HomeScreen(),
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const HomeScreen(),
        '/tracker': (context) => TrackerScreen(
              initialWeek: (ModalRoute.of(context)?.settings.arguments
                      as Map<String, dynamic>?)?['initialWeek'] as int?,
            ),
        '/chat': (context) => const ChatScreen(),
      },
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text(
                'Route not found: ${settings.name}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        );
      },
    );
  }
}