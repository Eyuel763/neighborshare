import 'package:flutter/material.dart';
import 'listing_model.dart';

class ListingDetailsScreen extends StatelessWidget {
  final ListingModel listing;

  const ListingDetailsScreen({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(listing.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Large Image Header
            Container(
              width: double.infinity,
              height: 300,
              color: Colors.grey[200],
              child: listing.imageUrl != null && listing.imageUrl!.isNotEmpty
                  ? Image.network(listing.imageUrl!, fit: BoxFit.cover)
                  : Icon(Icons.image, size: 100, color: Colors.grey[400]),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Title and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          listing.title,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '${listing.price.toStringAsFixed(0)} ETB',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                  Text(
                    listing.type == 'Tool' ? 'per day' : 'per task/hour',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const Divider(height: 40),

                  // 3. Location and Category
                  Row(
                    children: [
                      Chip(label: Text(listing.type), backgroundColor: Colors.orange[100]),
                      const SizedBox(width: 10),
                      Chip(label: Text(listing.category), backgroundColor: Colors.blue[100]),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.redAccent),
                      const SizedBox(width: 5),
                      Text('${listing.subcity}, ${listing.city}', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const Divider(height: 40),

                  // 4. Description
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(listing.description, style: const TextStyle(fontSize: 16, height: 1.5)),
                  
                  const SizedBox(height: 40),

                  // 5. Contact Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        // Phase 3: Messaging/Chat logic goes here
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Chat feature coming in the next phase!')),
                        );
                      },
                      child: const Text('Contact Neighbor', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}