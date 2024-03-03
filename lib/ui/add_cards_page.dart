import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manage_learning/data/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart'; // For uploading images
// Conditional import for handling files
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class AddCardsPage extends StatefulWidget {
  @override
  _AddCardsPageState createState() => _AddCardsPageState();
}

class _AddCardsPageState extends State<AddCardsPage> {
  late FirebaseService _firebaseService;
  final TextEditingController _deckTitleController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController(); // New tags controller
  final List<Map<String, dynamic>> _cardControllers = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _firebaseService = Provider.of<FirebaseService>(context, listen: false);
    _addCardController();
  }

  void _addCardController() {
    setState(() {
      _cardControllers.add({
        'front': TextEditingController(),
        'back': TextEditingController(),
        'image': null, // Initialize image path as null
        'tags': TextEditingController(), // New tags field for cards
      });
    });
  }

  // Existing methods remain unchanged

  @override
  void dispose() {
    _deckTitleController.dispose();
    _videoUrlController.dispose();
    _tagsController.dispose(); // Dispose the new tags controller
    for (var controller in _cardControllers) {
      controller['front']!.dispose();
      controller['back']!.dispose();
      controller['tags']!.dispose(); // Dispose the tags field for cards
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Deck and Cards')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDeckTitleInput(),
                  _buildVideoUrlInput(),
                  _buildTagsInput(), // New method to build tags input
                  _buildCardsList(),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // This centers the buttons horizontally and spaces them evenly.
              children: [
                Expanded(
                  // Wrap with Expanded for flexible button widths
                  child: Padding(
                    padding: const EdgeInsets.only(
                        right: 8.0), // Add some space between the buttons
                    child: ElevatedButton(
                      onPressed: _addCardController,
                      child: const Text('Add Another Card'),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              20), // Optional: Adds rounded corners
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  // Wrap with Expanded for flexible button widths
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0), // Add some space between the buttons
                    child: ElevatedButton(
                      onPressed: () => _saveDeckAndCards(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              20), // Optional: Adds rounded corners
                        ),
                      ),
                      child: const Text('Save Deck and Cards'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Method to build tags input
  Widget _buildTagsInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: _tagsController,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Tags',
          hintText: 'Enter tags separated by commas',
        ),
      ),
    );
  }
}
