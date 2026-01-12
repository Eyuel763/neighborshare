import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'auth_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const NeighborShareApp());
}

class NeighborShareApp extends StatelessWidget {
  const NeighborShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeighborShare',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthGuard(),
    );
  }
}