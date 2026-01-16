import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String reviewerId;   
  final String targetUserId; 
  final double rating;      
  final String comment;    
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.reviewerId,
    required this.targetUserId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'reviewerId': reviewerId,
      'targetUserId': targetUserId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
    };
  }
}