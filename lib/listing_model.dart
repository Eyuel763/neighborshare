import 'package:cloud_firestore/cloud_firestore.dart';

class ListingModel {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final String type; // 'Tool' or 'Skill'
  final String category;
  final double price;
  final String? imageUrl;
  final String subcity; 
  final String city;    
  final DateTime createdAt;

  ListingModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.price,
    this.imageUrl,
    required this.subcity,
    required this.city,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'type': type,
      'category': category,
      'price': price,
      'imageUrl': imageUrl,
      'subcity': subcity,
      'city': city,
      'createdAt': createdAt,
    };
  }

  factory ListingModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ListingModel(
      id: id,
      ownerId: data['ownerId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'Tool',
      category: data['category'] ?? 'Other',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['imageUrl'],
      subcity: data['subcity'] ?? '',
      city: data['city'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}