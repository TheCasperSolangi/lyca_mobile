import 'package:flutter/material.dart';
import 'package:lyca_mobile/AssignmentScreen.dart';
import 'package:lyca_mobile/AttendanceScreen.dart';
import 'package:lyca_mobile/CalendarScreen.dart';
import 'package:lyca_mobile/EQManagement.dart';
import 'package:lyca_mobile/FeeManagement.dart';
import 'package:lyca_mobile/IQManagement.dart';
import 'package:lyca_mobile/LeaveManagement.dart';
import 'package:lyca_mobile/LibraryManagementScreen.dart';
import 'package:lyca_mobile/LoginScreen.dart';
import 'package:lyca_mobile/NotificationScreen.dart';
import 'package:lyca_mobile/ParentDashboard.dart';
import 'package:lyca_mobile/SelfExam.dart';
import 'package:lyca_mobile/SettingsPage.dart';
import 'package:lyca_mobile/StudentDashboard.dart';
import 'package:lyca_mobile/TeacherDashboard.dart';
import 'package:lyca_mobile/examinationScreen.dart';
import 'package:lyca_mobile/mental_health.dart';
import 'package:lyca_mobile/studentProfileScreen.dart';
import 'package:lyca_mobile/transportManagement.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/splash', // Changed to splash screen
      routes: {
        '/splash': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/student-dashboard': (context) => StudentDashboard(),
        '/teacher-dashboard': (context) => TeacherDashboard(),
        '/parent-dashboard': (context) => ParentDashboard(),
        '/assignment': (context) => AssignmentScreen(),
        '/exams': (context) => ExamListScreen(),
        '/attendance': (context) => AttendanceScreen(),
        '/library': (context) => LibraryScreen(),
        '/self_exams': (context) => SelfExamScreen(),
        '/mental_health': (context) => MentalHealthScreen(),
        '/fees': (context) => FeeManagementScreen(),
        '/leave': (context) => StudentLeaveScreen(),
        '/transport': (context) => TransportTrackerScreen(),
        '/notifications': (context) => NotificationScreen(),
        '/calendar': (context) => CalendarScreen(),
        '/profile': (context) => StudentProfileScreen(),
        '/settings':(context) => SettingsScreen()
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');
    final rememberMe = prefs.getBool('rememberMe') ?? false;

    await Future.delayed(Duration(seconds: 5)); // Optional splash delay

    if (rememberMe && token != null && token.isNotEmpty) {
      // Token exists and remember me is checked - navigate to appropriate dashboard
      switch (role) {
        case 'student':
          Navigator.pushReplacementNamed(context, '/teacher-dashboard');
          break;
        case 'teacher':
          Navigator.pushReplacementNamed(context, '/teacher-dashboard');
          break;
        case 'parent':
          Navigator.pushReplacementNamed(context, '/parent-dashboard');
          break;
        default:
          Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      // No valid token or remember me not checked - go to login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FlutterLogo(size: 150), // Replace with your splash screen widget
      ),
    );
  }
}