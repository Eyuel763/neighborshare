import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel {
  final String id;
  final String listingId;
  final String listingTitle;
  final String requesterId;
  final String ownerId;
  final String status; // 'pending', 'accepted', 'declined', 'completed'
  final DateTime createdAt;

  RequestModel({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.requesterId,
    required this.ownerId,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'listingId': listingId,
      'listingTitle': listingTitle,
      'requesterId': requesterId,
      'ownerId': ownerId,
      'status': status,
      'createdAt': createdAt,
    };
  }

  factory RequestModel.fromFirestore(String id, Map<String, dynamic> data) {
    return RequestModel(
      id: id,
      listingId: data['listingId'] ?? '',
      listingTitle: data['listingTitle'] ?? '',
      requesterId: data['requesterId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}