import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_service.dart';
import '../models/listing_model.dart';

class AddListingScreen extends StatefulWidget {
  final ListingModel? existingListing; 

  const AddListingScreen({super.key, this.existingListing});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _dbService = DatabaseService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;

  late String _type;
  late String _category;
  File? _imageFile;
  bool _isLoading = false;

  final List<String> _toolCategories = ['Power Tools', 'Hand Tools', 'Gardening', 'Construction', 'Cleaning', 'Other'];
  final List<String> _skillCategories = ['Education', 'Plumbing', 'Electrical', 'Repair', 'Personal Care', 'Other'];

  @override
  void initState() {
    super.initState();
    _type = widget.existingListing?.type ?? 'Tool';
    _category = widget.existingListing?.category ?? (_type == 'Tool' ? _toolCategories[0] : _skillCategories[0]);
    
    _titleController = TextEditingController(text: widget.existingListing?.title ?? '');
    _descriptionController = TextEditingController(text: widget.existingListing?.description ?? '');
    _priceController = TextEditingController(text: widget.existingListing?.price.toString() ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _submitListing() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final User? user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        bool isEditing = widget.existingListing != null;
        String listingId = isEditing ? widget.existingListing!.id : _dbService.listingsCollection.doc().id;

        String? imageUrl = widget.existingListing?.imageUrl;
        if (_imageFile != null) {
          imageUrl = await _dbService.uploadListingImage(_imageFile!, listingId);
        }

        final userDoc = await _dbService.usersCollection.doc(user.uid).get();
        final userData = userDoc.data() as Map<String, dynamic>;

        final listingData = {
          'id': listingId,
          'ownerId': user.uid,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'type': _type,
          'category': _category,
          'price': double.parse(_priceController.text),
          'imageUrl': imageUrl,
          'subcity': userData['subcity'] ?? 'Unknown',
          'city': userData['city'] ?? 'Unknown',
          'createdAt': isEditing ? widget.existingListing!.createdAt : DateTime.now(),
        };

        if (isEditing) {
          await _dbService.updateListing(listingId, listingData);
        } else {
          await _dbService.listingsCollection.doc(listingId).set(listingData);
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isEditing ? 'Listing updated!' : 'Listing posted!')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.existingListing != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Listing' : 'Post New Item/Skill')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
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
                                child: Image.file(_imageFile!, fit: BoxFit.cover),
                              )
                            : (isEditing && widget.existingListing?.imageUrl != null)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(widget.existingListing!.imageUrl!, fit: BoxFit.cover),
                                  )
                                : const Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 20),

                    DropdownButtonFormField(
                      value: _type,
                      items: ['Tool', 'Skill'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) {
                        setState(() {
                          _type = val as String;
                          _category = _type == 'Tool' ? _toolCategories[0] : _skillCategories[0];
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField(
                      value: _category,
                      items: (_type == 'Tool' ? _toolCategories : _skillCategories)
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) => setState(() => _category = val as String),
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                      validator: (val) => val!.isEmpty ? 'Enter a title' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                      maxLines: 3,
                      validator: (val) => val!.isEmpty ? 'Enter details' : null,
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Price (ETB)', border: OutlineInputBorder(), prefixText: 'ETB '),
                      keyboardType: TextInputType.number,
                      validator: (val) => val!.isEmpty ? 'Enter price' : null,
                    ),
                    const SizedBox(height: 30),

                    SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0052CC), foregroundColor: Colors.white),
                        onPressed: _submitListing,
                        child: Text(isEditing ? 'Update Listing' : 'Post Listing', style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}