import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final CollectionReference usersCollection = 
      FirebaseFirestore.instance.collection('users');

  Future<void> updateUserData(UserModel user) async {
  return await usersCollection.doc(user.uid).set(
    user.toFirestore(), 
    SetOptions(merge: true), 
  );
}

  Future<bool> isUserProfileComplete(String uid) async {
    try {
      DocumentSnapshot doc = await usersCollection.doc(uid).get();
      
      if (!doc.exists) {
        print('Profile Document not found for $uid.');
        return false;
      }
      final data = doc.data() as Map<String, dynamic>;
      final city = data['city'] as String?;
      final subcity = data['subcity'] as String?;

      final isLocationSet = city != null && 
                            city.isNotEmpty &&
                            subcity != null &&
                            subcity.isNotEmpty;
      if (!isLocationSet) {
          print('Profile incomplete: City or Subcity is missing.');
      } else {
          print('Profile complete. Navigating to Home.');
      }

      return isLocationSet;

    } catch (e) {
      print('Error checking profile completion: $e');
      return false; 
    }
  }

  Stream<UserModel> userDocumentStream(String uid) {
    return usersCollection.doc(uid).snapshots().map((doc) {
      return UserModel.fromFirestore(doc.data() as Map<String, dynamic>);
    });
  }
}