import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'database_service.dart';
import 'listing_model.dart';

class AddListingScreen extends StatefulWidget {
  const AddListingScreen({super.key});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _dbService = DatabaseService();
  final ImagePicker _picker = ImagePicker();
  
  // Form Fields
  String _title = '';
  String _description = '';
  String _type = 'Tool';
  late String _category; // Initialized in initState
  double _price = 0.0;
  File? _imageFile;
  bool _isLoading = false;

  // Category Lists
  final List<String> _toolCategories = ['Power Tools', 'Hand Tools', 'Gardening', 'Construction', 'Cleaning', 'Other'];
  final List<String> _skillCategories = ['Education', 'Plumbing', 'Electrical', 'Repair', 'Personal Care', 'Other'];

  @override
  void initState() {
    super.initState();
    // Ensures _category starts with a valid value from the default 'Tool' list
    _category = _toolCategories[0];
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Compression for mobile performance
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _submitListing() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        final User? user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        // 1. Generate a unique ID for the document first
        String listingId = _dbService.listingsCollection.doc().id;

        // 2. Upload image to Storage if one exists
        String? imageUrl;
        if (_imageFile != null) {
          imageUrl = await _dbService.uploadListingImage(_imageFile!, listingId);
        }

        // 3. Get User location from their profile
        final userDoc = await _dbService.usersCollection.doc(user.uid).get();
        final userData = userDoc.data() as Map<String, dynamic>;

        // 4. Create the model
        final newListing = ListingModel(
          id: listingId,
          ownerId: user.uid,
          title: _title,
          description: _description,
          type: _type,
          category: _category,
          price: _price,
          imageUrl: imageUrl,
          subcity: userData['subcity'] ?? 'Unknown',
          city: userData['city'] ?? 'Unknown',
          createdAt: DateTime.now(),
        );

        // 5. Save to Firestore using the generated ID
        await _dbService.listingsCollection.doc(listingId).set(newListing.toFirestore());

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Listing posted successfully!')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting listing: $e')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post New Item/Skill')),
      body: _isLoading 
        ? const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text("Uploading to NeighborShare..."),
            ],
          ))
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // --- IMAGE PICKER UI ---
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: _imageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                                SizedBox(height: 10),
                                Text('Tap to add a photo'),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- TYPE DROPDOWN ---
                  DropdownButtonFormField(
                    value: _type,
                    items: ['Tool', 'Skill'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) {
                      setState(() {
                        _type = val as String;
                        // Reset category so it doesn't crash the dropdown
                        _category = _type == 'Tool' ? _toolCategories[0] : _skillCategories[0];
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Type of Listing', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 15),

                  // --- CATEGORY DROPDOWN ---
                  DropdownButtonFormField(
                    value: _category,
                    items: (_type == 'Tool' ? _toolCategories : _skillCategories)
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) => setState(() => _category = val as String),
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 15),

                  // --- TITLE ---
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Title (e.g. Electric Drill)', border: OutlineInputBorder()),
                    validator: (val) => val!.isEmpty ? 'Enter a title' : null,
                    onSaved: (val) => _title = val!,
                  ),
                  const SizedBox(height: 15),

                  // --- DESCRIPTION ---
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    maxLines: 3,
                    validator: (val) => val!.isEmpty ? 'Enter details' : null,
                    onSaved: (val) => _description = val!,
                  ),
                  const SizedBox(height: 15),

                  // --- PRICE ---
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: _type == 'Tool' ? 'Price (ETB per day)' : 'Price (ETB per task/hour)',
                      border: const OutlineInputBorder(),
                      prefixText: 'ETB ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (val) => val!.isEmpty ? 'Enter price' : null,
                    onSaved: (val) => _price = double.parse(val!),
                  ),
                  const SizedBox(height: 30),

                  // --- SUBMIT BUTTON ---
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _submitListing,
                      child: const Text('Post Listing', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}