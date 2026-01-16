import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'core/auth_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const NeighborShareApp());
}

class NeighborShareApp extends StatelessWidget {
  const NeighborShareApp({super.key});

  static const Color trustBlue = Color(0xFF0052CC);

  @override
 Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NeighborShare',
      theme: ThemeData(
        useMaterial3: true,
        // Global color scheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: trustBlue,
          primary: trustBlue,
          secondary: const Color(0xFF0065FF),
        ),
        // Global AppBar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: trustBlue,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: trustBlue,
          ),
        ),
        // Global Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: trustBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        // Global Chip Theme 
        chipTheme: ChipThemeData(
          selectedColor: trustBlue,
          secondaryLabelStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      home: const AuthGuard(), 
    );
  }
}