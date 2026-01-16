import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neighbor_share/core/main_navigation.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../screens/login_screen.dart';
import '../screens/profile_setup_screen.dart';
import '../screens/splash_screen.dart';


class AuthGuard extends StatelessWidget {
  const AuthGuard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final User? user = authSnapshot.data;

        if (user == null) {
          return const LoginScreen();
        }

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
            
            bool isComplete = userModel.city != null && 
                             userModel.city!.isNotEmpty &&
                             userModel.subcity != null &&
                             userModel.subcity!.isNotEmpty;

            if (isComplete) {
              return const MainNavigation();
            } else {
              return const ProfileSetupScreen();
            }
          },
        );
      },
    );
  }
}