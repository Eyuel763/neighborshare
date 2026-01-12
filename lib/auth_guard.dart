import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';
import 'user_model.dart';
import 'login_screen.dart';
import 'profile_setup_screen.dart';
import 'home_screen.dart';

class AuthGuard extends StatelessWidget {
  const AuthGuard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // 1. Connection loading
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final User? user = authSnapshot.data;

        // 2. User is NOT logged in
        if (user == null) {
          return const LoginScreen();
        }

        // 3. User IS logged in - Now listen to their Firestore document reactively
        return StreamBuilder<UserModel>(
          stream: DatabaseService().userDocumentStream(user.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (!userSnapshot.hasData) {
              return const ProfileSetupScreen();
            }

            final userModel = userSnapshot.data!;
            
            // Check if profile is complete
            bool isComplete = userModel.city != null && 
                             userModel.city!.isNotEmpty &&
                             userModel.subcity != null &&
                             userModel.subcity!.isNotEmpty;

            if (isComplete) {
              return HomeScreen();
            } else {
              return const ProfileSetupScreen();
            }
          },
        );
      },
    );
  }
}