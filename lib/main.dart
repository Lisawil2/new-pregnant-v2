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
import 'firebase_options.dart'; // This file should define DefaultFirebaseOptions

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase safely - check if already initialized
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialized successfully.');
    } catch (e) {
      print('Firebase initialization error: $e');
      // Continue without Firebase for now
    }
  } else {
    print('Firebase already initialized.');
  }

  bool dotEnvInitialized = false;

  try {
    await dotenv.load(fileName: ".env");
    if (dotenv.env['API_KEY']?.isNotEmpty ?? false) {
      dotEnvInitialized = true;
      print('DotEnv initialized successfully.');
    } else {
      print('Warning: API_KEY is missing or empty in .env file.');
    }
  } catch (e, stackTrace) {
    print('Error loading DotEnv: $e\n$stackTrace');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MyApp(dotEnvInitialized: dotEnvInitialized),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool dotEnvInitialized;

  const MyApp({super.key, required this.dotEnvInitialized});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pregnancy Chatbot',
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
        '/': (context) => const HomeScreen(), // Fallback for root route
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