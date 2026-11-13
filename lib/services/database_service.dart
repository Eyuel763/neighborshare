import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/listing_model.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/request_model.dart';
import '../models/message_model.dart';
import '../models/review_model.dart';

import '../models/role_request_model.dart';
import '../models/user_role.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection('users');
  final CollectionReference listingsCollection = FirebaseFirestore.instance
      .collection('listings');
  final CollectionReference requestsCollection = FirebaseFirestore.instance
      .collection('requests');

  Future<void> updateUserData(UserModel user) async {
    return await usersCollection
        .doc(user.uid)
        .set(user.toFirestore(), SetOptions(merge: true));
  }

  Stream<UserModel> userDocumentStream(String uid) {
    return usersCollection.doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserModel.fromFirestore(snapshot.data() as Map<String, dynamic>);
      } else {
        throw Exception("User document not found");
      }
    });
  }

  Future<void> addListing(ListingModel listing) async {
    try {
      await listingsCollection.add(listing.toFirestore());
    } catch (e) {
      print("Error adding listing: $e");
      rethrow;
    }
  }

  Future<String?> uploadListingImage(File imageFile, String listingId) async {
    try {
      // Create a reference to the location in Firebase Storage
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('listing_images')
          .child('$listingId.jpg');

      // Upload the file
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
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

      final isLocationSet =
          city != null &&
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

  Stream<List<ListingModel>> getNearbyListings(String city, String subcity) {
    return listingsCollection
        .where('city', isEqualTo: city)
        .where('subcity', isEqualTo: subcity)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ListingModel.fromFirestore(
              doc.id,
              doc.data() as Map<String, dynamic>,
            );
          }).toList();
        });
  }

  Future<void> createRequest(RequestModel request) async {
    await requestsCollection.add(request.toFirestore());
  }

  // Stream of requests SENT by the current user
  Stream<List<RequestModel>> getSentRequests(String uid) {
    return requestsCollection
        .where('requesterId', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => RequestModel.fromFirestore(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }

  // Stream of requests RECEIVED by the current user (as an owner)
  Stream<List<RequestModel>> getReceivedRequests(String uid) {
    return requestsCollection
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => RequestModel.fromFirestore(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }

  Future<void> updateRequestStatus(String requestId, String newStatus) async {
    try {
      await requestsCollection.doc(requestId).update({'status': newStatus});
    } catch (e) {
      print("Error updating request: $e");
      rethrow;
    }
  }

  Future<void> sendMessage(String chatRoomId, MessageModel message) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add(message.toFirestore());
  }

  Stream<List<MessageModel>> getMessages(String chatRoomId) {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true) // Newest at bottom
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc.data()))
              .toList(),
        );
  }

  Stream<List<ListingModel>> getUserListings(String uid) {
    return listingsCollection
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ListingModel.fromFirestore(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }

  Future<void> updateListing(String listingId, Map<String, dynamic> updatedData) async {
    try {
      await listingsCollection.doc(listingId).update(updatedData);
    } catch (e) {
      print("Error updating listing: $e");
      rethrow;
    }
  }

  Future<void> deleteListing(String listingId) async {
    await listingsCollection.doc(listingId).delete();
  }

  Future<void> submitReview(ReviewModel review) async {
    await FirebaseFirestore.instance.collection('reviews').add(review.toMap());

    await _recalculateUserAverage(review.targetUserId);
  }

  Future<void> _recalculateUserAverage(String userId) async {
    final query = await FirebaseFirestore.instance
        .collection('reviews')
        .where('targetUserId', isEqualTo: userId)
        .get();

    if (query.docs.isEmpty) return;

    double totalStars = 0;
    for (var doc in query.docs) {
      totalStars += (doc.data()['rating'] as num).toDouble();
    }

    double average = totalStars / query.docs.length;

    await usersCollection.doc(userId).update({
      'rating': average,
      'reviewCount': query.docs.length,
    });
  }

    Future<void> submitRoleRequest({
    required String requesterUid,
    required String requesterEmail,
    required UserRole requestedRole,
    String? reason,
  }) async {
    final request = RoleRequestModel(
      id: '',
      requesterUid: requesterUid,
      requesterEmail: requesterEmail,
      requestedRole: requestedRole,
      reason: reason,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('role_requests').add(request.toFirestore());
  }

    Stream<List<RoleRequestModel>> getPendingRoleRequests() {
    return _firestore
        .collection('role_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RoleRequestModel.fromFirestore(doc))
            .toList());
  }

    Future<void> reviewRoleRequest({
    required String requestId,
    required String requesterUid,
    required String adminUid,
    required bool approve,
  }) async {
    // Client-side guard (also strictly enforced by Firestore Security Rules)
    if (requesterUid == adminUid) {
      throw Exception('Separation of Duties violation: Admins cannot approve their own role requests.');
    }

    await _firestore.collection('role_requests').doc(requestId).update({
      'status': approve ? 'approved' : 'rejected',
      'reviewedBy': adminUid,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }
}
