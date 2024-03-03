import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manage_learning/data/firebase_service.dart';
import 'package:path/path.dart' hide context;
import 'package:provider/provider.dart';

class EditCardsPage extends StatefulWidget {
  final String deckId;
  const EditCardsPage({required this.deckId, Key? key}) : super(key: key);

  @override
  _EditCardsPageState createState() => _EditCardsPageState();
}

class _EditCardsPageState extends State<EditCardsPage> {
  late FirebaseService _firebaseService;
  final TextEditingController _deckTitleController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController(); // New tags controller
  final ImagePicker _picker = ImagePicker();

  late List<Map<String, dynamic>> _cardControllers = []; // Include positioning
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _firebaseService = Provider.of<FirebaseService>(context, listen: false);
    _loadDeckData();
  }

  void _loadDeckData() async {
    setState(() => _isLoading = true);
    var deckData = await _firebaseService.getDeckData(widget.deckId);
    _deckTitleController.text = deckData['title'];
    _videoUrlController.text = deckData['videoUrl'] ?? ''; // Default to empty if not found
    _tagsController.text = deckData['tags'] ?? ''; // Load existing tags

    // Adjusted to handle positioning
    var fetchedCards = deckData['cards'] as List<Map<String, dynamic>>;
    _cardControllers = fetchedCards
        .map((cardData) => {
              'front': TextEditingController(text: cardData['front']),
              'back': TextEditingController(text: cardData['back']),
              'position': cardData['position'], // Store position
              'imageUrl': cardData['imageUrl'] ?? '',
              'tags': TextEditingController(text: cardData['tags'] ?? ''), // New tags field for cards
            })
        .toList()
      ..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int)); // Sort by position

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _deckTitleController.dispose();
    _videoUrlController.dispose();
    _tagsController.dispose(); // Dispose the new tags controller
    _cardControllers.forEach((controllers) {
      controllers['front'].dispose();
      controllers['back'].dispose();
      controllers['tags'].dispose(); // Dispose the tags field for cards
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Deck and Cards')),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDeckTitleInput(),
                        _buildVideoUrlInput(),
                        _buildTagsInput(), // New method to build tags input
                        ..._cardControllers
                            .asMap()
                            .entries
                            .map(
                              (entry) => _buildCard(entry.value, entry.key),
                            )
                            .toList(),
                      ],
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ElevatedButton(
                      onPressed: _addCardController,
                      child: Text('Add Another Card'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ElevatedButton(
                      onPressed: _saveDeckAndCards,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text('Save Deck and Cards'),
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
