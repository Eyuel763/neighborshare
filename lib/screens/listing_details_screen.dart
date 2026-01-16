import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/listing_model.dart';
import '../models/request_model.dart';
import '../services/database_service.dart';
import 'add_listing_screen.dart'; 

class ListingDetailsScreen extends StatelessWidget {
  final ListingModel listing;

  const ListingDetailsScreen({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final DatabaseService dbService = DatabaseService();
    final User? currentUser = FirebaseAuth.instance.currentUser;
    
    // Check if the current user owns this listing
    final bool isOwner = currentUser?.uid == listing.ownerId;

    return Scaffold(
      appBar: AppBar(
        title: Text(isOwner ? "Manage Your Listing" : listing.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF0052CC)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddListingScreen(existingListing: listing),
                  ),
                );
              },
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 350,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                image: listing.imageUrl != null && listing.imageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(listing.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: listing.imageUrl == null || listing.imageUrl!.isEmpty
                  ? Icon(Icons.image, size: 100, color: Colors.grey[400])
                  : null,
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildBadge(listing.type, listing.type == 'Tool' ? Colors.orange : Colors.blue),
                      const SizedBox(width: 8),
                      _buildBadge(listing.category, Colors.grey.shade600),
                    ],
                  ),
                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          listing.title,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${listing.price.toStringAsFixed(0)} ETB',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                          Text(
                            listing.type == 'Tool' ? 'per day' : 'per task',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 5),
                      Text(
                        '${listing.subcity}, ${listing.city}',
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ],
                  ),

                  const Divider(height: 40, thickness: 1),

                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    listing.description,
                    style: const TextStyle(fontSize: 16, color: Colors.black54, height: 1.5),
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: isOwner
                        ? OutlinedButton.icon(
                            onPressed: () {
                            },
                            icon: const Icon(Icons.analytics_outlined),
                            label: const Text("This is your listing"),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0052CC),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            onPressed: () async {
                              final newRequest = RequestModel(
                                id: '', 
                                listingId: listing.id,
                                listingTitle: listing.title,
                                requesterId: currentUser!.uid,
                                ownerId: listing.ownerId,
                                status: 'pending',
                                createdAt: DateTime.now(),
                              );

                              try {
                                await dbService.createRequest(newRequest);
                                if (context.mounted) {
                                  _showSuccessDialog(context);
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to send request: $e')),
                                );
                              }
                            },
                            child: Text(
                              listing.type == 'Tool' ? 'Request to Borrow' : 'Request Service',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text(
          'Request Sent! Your neighbor has been notified. You can track this in your Activity tab.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); 
              Navigator.pop(context); 
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}