import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _dbService = DatabaseService();
  String _subcity = ''; 
  String _city = '';  

  void _submitAddress() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final User? firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser != null) {
        try {
          await _dbService.usersCollection.doc(firebaseUser.uid).set({
            'subcity': _subcity, 
            'city': _city,
            'isAddressVerified': false, 
          }, SetOptions(merge: true));
          
        } catch (e) {
          print('!!! Firestore Update Failed: $e');
        }
      } 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile Location')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              const Text(
                'Enter your regional location (City and Sub-City/Woreda). This helps connect you with local neighbors and is required for Skill Providers.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                decoration: const InputDecoration(labelText: 'City/Town'),
                validator: (val) => val!.isEmpty ? 'Enter your city' : null,
                onSaved: (val) => _city = val!.trim(),
              ),
              
              TextFormField(
                decoration: const InputDecoration(labelText: 'Sub-City / Regional Division'),
                validator: (val) => val!.isEmpty ? 'Enter your Sub-City or Woreda' : null,
                onSaved: (val) => _subcity = val!.trim(),
              ),
              
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitAddress,
                child: const Text('Save Location & Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}