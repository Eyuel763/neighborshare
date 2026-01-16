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
  
  final double rating; 
  final int reviewCount;

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
    this.rating = 0.0,    
    this.reviewCount = 0, 
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
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'uid': uid,
      'email': email,
      'createdAt': createdAt,
      'isAddressVerified': isAddressVerified,
      'trustScore': trustScore,
      'rating': rating,     
      'reviewCount': reviewCount, 
    };

    if (name != null) data['name'] = name;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (subcity != null) data['subcity'] = subcity;
    if (city != null) data['city'] = city;

    return data;
  }
}