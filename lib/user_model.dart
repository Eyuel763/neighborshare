import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid; 
  final String email;
  final String? name;
  final String? photoUrl;
  final double trustScore; 
  final DateTime createdAt;
  final String? subcity;
  final String? city;
  final bool isAddressVerified;

  UserModel({
    required this.uid,
    required this.email,
    this.name,
    this.photoUrl,
    this.trustScore = 5.0, 
    required this.createdAt,
    this.subcity, 
    this.city,
    this.isAddressVerified = false,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] as String,
      email: data['email'] as String,
      name: data['name'] as String?,
      photoUrl: data['photoUrl'] as String?,
      trustScore: (data['trustScore'] as num?)?.toDouble() ?? 5.0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      subcity: data['subcity'] as String?,
      city: data['city'] as String?,
      isAddressVerified: data['isAddressVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'uid': uid,
      'email': email,
      'createdAt': createdAt,
    };

    if (name != null) data['name'] = name;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (subcity != null) data['subcity'] = subcity;
    if (city != null) data['city'] = city;
    data['isAddressVerified'] = isAddressVerified;
    data['trustScore'] = trustScore;

    return data;
  }
}