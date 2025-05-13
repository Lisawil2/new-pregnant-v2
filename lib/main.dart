import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/tracker_screen.dart';
import 'screens/reminder_screen.dart';

void main() {
  runApp(BloomMamaApp());
}

class BloomMamaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BloomMama',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        fontFamily: 'Roboto',
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreen(),
        '/onboarding': (context) => OnboardingScreen(),
        '/main': (context) => MainScreen(),
        '/home': (context) => HomeScreen(),
        '/chat': (context) => ChatScreen(),
        '/profile': (context) => ProfileScreen(),
        '/tracker': (context) => TrackerScreen(),
        '/reminder': (context) => ReminderScreen(),
      },
    );
  }
}
