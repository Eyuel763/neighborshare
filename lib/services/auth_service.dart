import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'database_service.dart'; 
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _dbService = DatabaseService();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '968434106434-u93ia5ktcl7cpfhp108vh9p8dk61q49l.apps.googleusercontent.com', 
  ); 

  Stream<User?> get user => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('Google Sign-In canceled by user.');
        return null;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final UserModel newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          name: user.displayName,
          photoUrl: user.photoURL,
          createdAt: DateTime.now(),
        );
        await _dbService.updateUserData(newUser);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.message}');
      return null;
    } catch (e) {
      print('General Error during Google Sign-In: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<User?> signUpWithEmailAndPassword({
    required String email, 
    required String password,
    String? displayName,
  }) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final User? user = userCredential.user;

      if (user != null) {
        if (displayName != null) {
            await user.updateDisplayName(displayName);
        }

        final UserModel newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '', 
          name: displayName,
          createdAt: DateTime.now(),
        );

        await _dbService.updateUserData(newUser); 
      }
      return user;

    } on FirebaseAuthException catch (e) {
      print('Firebase Sign-Up Error: ${e.code}');
      return null;
    } catch (e) {
      print('General Sign-Up Error: $e');
      return null;
    }
  }

  Future<User?> signInWithEmailAndPassword({
    required String email, 
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final User? user = userCredential.user;
      return user;

    } on FirebaseAuthException catch (e) {
      print('Firebase Sign-In Error: ${e.code}');
      String message;
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided for that user.';
      } else {
        message = 'Login failed. Please check your credentials.';
      }
      print(message);
      return null;
    } catch (e) {
      print('General Sign-In Error: $e');
      return null;
    }
  }
}