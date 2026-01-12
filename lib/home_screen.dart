// lib/home_screen.dart
import 'package:flutter/material.dart';
import 'auth_service.dart'; // Import the AuthService

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  // Initialize the AuthService
  // final AuthService _authService = AuthService(); // Use const if possible

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NeighborShare Dashboard'),
        // Add the Sign Out button to the AppBar's actions
        actions: <Widget>[
          TextButton.icon(
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Sign Out', style: TextStyle(color: Colors.white)),
            onPressed: () async {
              // Call the sign out function from AuthService
              await AuthService().signOut();
              // The AuthGuard will detect the change in the auth state (user is now null)
              // and automatically redirect the user to the LoginScreen.
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome! You are logged in and your profile is set up.',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'This is the main application area.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}