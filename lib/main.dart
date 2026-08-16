import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/ml/face_recognition_service.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for kiosk terminal stability
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Warm up and initialize MobileFaceNet TFLite interpreter ONCE on app launch
  await FaceRecognitionService().initialize();

  runApp(
    const ProviderScope(
      child: FacialAttendanceApp(),
    ),
  );
}

/// Root Application widget for the Facial Recognition Attendance Kiosk.
class FacialAttendanceApp extends StatelessWidget {
  const FacialAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BioAttend',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676),
          secondary: Color(0xFF00B0FF),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
