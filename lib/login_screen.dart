import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart'; 
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  void _submitEmailSignIn() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final user = await _authService.signInWithEmailAndPassword(
        email: _email,
        password: _password,
      );

      if (user != null) {
        print('Email sign-in successful for: ${user.email}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login Failed. Check your email and password.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NeighborShare Login')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: ListView( 
            shrinkWrap: true,
            children: <Widget>[
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) => val!.isEmpty || !val.contains('@') ? 'Enter a valid email' : null,
                      onSaved: (val) => _email = val!.trim(),
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (val) => val!.isEmpty ? 'Enter your password' : null,
                      onSaved: (val) => _password = val!,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitEmailSignIn,
                      child: const Text('Sign In with Email'),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              const Center(child: Text('— OR —')),
              const SizedBox(height: 30),

              ElevatedButton.icon(
                icon: const Icon(Icons.g_mobiledata),
                label: const Text('Sign in with Google'),
                onPressed: () async {
                  User? user = await _authService.signInWithGoogle();
                  if (user != null) {
                    print("Google sign-in successful for: ${user.email}");
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Google Sign-in failed or cancelled.')),
                    );
                  }
                },
              ),

              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                  );
                },
                child: const Text('New user? Sign Up Here'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}