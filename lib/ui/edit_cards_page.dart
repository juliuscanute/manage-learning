import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manage_learning/data/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart'; // For uploading images
// Conditional import for handling files
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

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
  final List<Map<String, dynamic>> _cardControllers = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _firebaseService = Provider.of<FirebaseService>(context, listen: false);
    _loadDeckData();
  }

  Future<void> _loadDeckData() async {
    var deckData = await _firebaseService.getDeckData(widget.deckId);
    _deckTitleController.text = deckData['title'];
    _videoUrlController.text = deckData['videoUrl'] ?? '';
    _tagsController.text = deckData['tags'].join(', '); // Assuming tags are stored as a list
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _deckTitleController.dispose();
    _videoUrlController.dispose();
    _tagsController.dispose(); // Dispose of the tags controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Deck and Cards'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              _buildDeckTitleInput(),
              _buildVideoUrlInput(),
              _buildTagsInput(), // Build tags input field
              // Other widget builders...
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveDeckAndCards,
        child: const Icon(Icons.save),
      ),
    );
  }

  // Widget builders and _saveDeckAndCards method

  Widget _buildTagsInput() {
    return TextField(
      controller: _tagsController,
      decoration: InputDecoration(
        labelText: 'Tags',
        hintText: 'Enter tags separated by commas',
      ),
    );
  }

  // Other widget builders...
}
