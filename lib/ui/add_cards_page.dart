import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manage_learning/data/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart'; // For uploading images
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
      });
    });
  }

  // Existing code for building the UI

  // Additional function to handle saving tags to Firebase

  @override
  void dispose() {
    _deckTitleController.dispose();
    _videoUrlController.dispose();
    _tagsController.dispose(); // Dispose of the tags controller
    for (var controller in _cardControllers) {
      controller['front'].dispose();
      controller['back'].dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Deck and Cards'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildDeckTitleInput(),
                  _buildVideoUrlInput(),
                  _buildTagsInput(), // Build tags input field
                  _buildCardsList(),
                ],
              ),
            ),
          ),
          _buildSaveButton(),
        ],
      ),
    );
  }

  // Method to build tags input field
  Widget _buildTagsInput() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: TextField(
        controller: _tagsController,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Tags',
          hintText: 'Enter tags separated by commas',
        ),
      ),
    );
  }

  // Existing methods for _buildDeckTitleInput, _buildVideoUrlInput, _buildCardsList, and _buildSaveButton

}
