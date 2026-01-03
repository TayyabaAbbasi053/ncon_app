import 'package:flutter/material.dart';
import '../services/firestore_service.dart'; // Changed import
import '../models/place.dart'; // Add this import

class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService(); // Changed to FirestoreService

  Future<void> _addPlace() async {
    if (_nameController.text.isEmpty || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    try {
      // Create a new place document in Firestore
      await _firestoreService.addPlace(
        _nameController.text,
        _descController.text,
        _imageUrlController.text,
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Place added successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding place: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Place'),
        backgroundColor: const Color(0xFF08548E),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Place Name'),
            ),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'ImgBB Image URL',
                hintText: 'Paste your ImgBB image URL here',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addPlace,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF08548E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}