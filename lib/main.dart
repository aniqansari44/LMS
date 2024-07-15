import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'SplashScreen.dart';
import 'OnBoardingScreen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'common_dashboard.dart';
import 'ClassesScreen.dart';
import 'profile_screen.dart';
import 'history_screen.dart';
import 'resources_screen.dart';
import 'payments_screen.dart';
import 'students_screen.dart';
import 'search_screen.dart';
import 'my_courses_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LMS Mobile App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: AuthWrapper(),
      routes: {
        '/splash': (context) => SplashScreen(),
        '/onboarding': (context) => OnboardingScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/dashboard': (context) => CommonDashboard(),
        '/classes': (context) => ClassesScreen(),
        '/profile': (context) => ProfileScreen(),
        '/history': (context) => HistoryScreen(),
        '/resources': (context) => ResourcesScreen(),
        '/payments': (context) => PaymentsScreen(),
        '/students': (context) => StudentScreen(),
        '/search': (context) => SearchScreen(),
        '/mycourses': (context) => MyCoursesScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
        } else if (snapshot.hasData) {
          return CommonDashboard();
        } else {
          return OnboardingScreen();
        }
      },
    );
  }
}
