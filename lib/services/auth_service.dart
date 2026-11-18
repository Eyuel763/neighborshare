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
    String? phoneNumber,
    String? subcity,
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

        // Account Activation: Send Email Verification
        await user.sendEmailVerification();

        final UserModel newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '', 
          name: displayName,
          phoneNumber: phoneNumber,
          subcity: subcity,
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
    final sanitizedEmail = email.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]+'), '_');
    final lockoutDocRef = FirebaseFirestore.instance.collection('account_lockouts').doc(sanitizedEmail);
    try {
      // 1. Check existing lockout status before attempting sign in
      final lockoutSnapshot = await lockoutDocRef.get();
      if (lockoutSnapshot.exists) {
        final data = lockoutSnapshot.data() as Map<String, dynamic>;
        final Timestamp? lockoutUntil = data['lockoutUntil'] as Timestamp?;
        if (lockoutUntil != null && lockoutUntil.toDate().isAfter(DateTime.now())) {
          final remainingMinutes = lockoutUntil.toDate().difference(DateTime.now()).inMinutes + 1;
          throw FirebaseAuthException(
            code: 'account-locked',
            message: 'Account temporarily locked due to 5 consecutive failed attempts. Please try again in $remainingMinutes minute(s).',
          );
        }
      }
      // 2. Attempt Authentication via Firebase Auth
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      final User? user = userCredential.user;
      // 3. Reset failed attempts counter on successful login
      if (user != null) {
        await lockoutDocRef.set({
          'failedAttempts': 0,
          'lockoutUntil': null,
          'lastSuccessfulLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-locked') {
        rethrow;
      }
      // 4. Increment failed attempts on failed login (wrong-password, user-not-found, etc.)
      final lockoutSnapshot = await lockoutDocRef.get();
      int currentAttempts = 0;
      if (lockoutSnapshot.exists) {
        currentAttempts = (lockoutSnapshot.data() as Map<String, dynamic>)['failedAttempts'] ?? 0;
      }
      currentAttempts += 1;
      final bool shouldLock = currentAttempts >= 5;
      final DateTime? lockUntil = shouldLock ? DateTime.now().add(const Duration(minutes: 15)) : null;
      await lockoutDocRef.set({
        'failedAttempts': currentAttempts,
        'lockoutUntil': lockUntil != null ? Timestamp.fromDate(lockUntil) : null,
        'lastFailedAttempt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (shouldLock) {
        throw FirebaseAuthException(
          code: 'account-locked',
          message: 'Account temporarily locked due to 5 consecutive failed attempts. Please try again in 15 minutes.',
        );
      }
      rethrow;
    }
  }

    /// Reads the role from the custom claims in the Firebase ID token
  Future<String?> getCurrentUserRoleClaim() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return null;
    
    // Force refresh token to ensure we have the latest custom claims
    final IdTokenResult tokenResult = await currentUser.getIdTokenResult(true);
    return tokenResult.claims?['role'] as String?;
  }

    /// Sends a password reset email with a short-lived reset token
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      print('Password Reset Error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('General Password Reset Error: $e');
      return false;
    }
  }
}