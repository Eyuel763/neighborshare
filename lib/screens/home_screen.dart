import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/listing_model.dart';
import '../models/user_model.dart';
import '../widgets/listing_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String _selectedType = 'All';

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final DatabaseService dbService = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('NeighborShare'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async => await AuthService().signOut(),
          ),
        ],
      ),
      body: StreamBuilder<UserModel>(
        stream: dbService.userDocumentStream(currentUser!.uid),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = userSnapshot.data!;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search for tools or skills...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['All', 'Tool', 'Skill'].map((type) {
                    return ChoiceChip(
                      label: Text(type),
                      selected: _selectedType == type,
                      onSelected: (selected) => setState(() => _selectedType = type),
                    );
                  }).toList(),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Available in ${user.subcity}, ${user.city}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blueGrey),
                  ),
                ),
              ),

              Expanded(
                child: StreamBuilder<List<ListingModel>>(
                  stream: dbService.getNearbyListings(user.city!, user.subcity!),
                  builder: (context, listingSnapshot) {
                    if (listingSnapshot.hasError) {
                      return const Center(child: Text('Error loading listings.'));
                    }

                    if (listingSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allListings = listingSnapshot.data ?? [];
                    final filteredListings = allListings.where((l) {
                      final matchesSearch = l.title.toLowerCase().contains(_searchQuery) || 
                                            l.description.toLowerCase().contains(_searchQuery);
                      final matchesType = _selectedType == 'All' || l.type == _selectedType;
                      return matchesSearch && matchesType;
                    }).toList();

                    if (filteredListings.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off, size: 60, color: Colors.grey),
                            Text(_searchQuery.isEmpty 
                              ? 'No listings nearby.' 
                              : 'No matches found.'),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredListings.length,
                      itemBuilder: (context, index) {
                        return ListingCard(listing: filteredListings[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}