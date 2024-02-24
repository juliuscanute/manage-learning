import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manage_learning/data/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' hide context;

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
    _videoUrlController.text =
        deckData['videoUrl'] ?? ''; // Default to empty if not found

    // Adjusted to handle positioning
    var fetchedCards = deckData['cards'] as List<Map<String, dynamic>>;
    _cardControllers = fetchedCards
        .map((cardData) => {
              'front': TextEditingController(text: cardData['front']),
              'back': TextEditingController(text: cardData['back']),
              'position': cardData['position'], // Store position
              'imageUrl': cardData['imageUrl'] ?? '',
            })
        .toList()
      ..sort((a, b) => (a['position'] as int)
          .compareTo(b['position'] as int)); // Sort by position

    setState(() => _isLoading = false);
  }

  void _moveCard(int oldIndex, int newIndex) {
    setState(() {
      final item = _cardControllers.removeAt(oldIndex);
      _cardControllers.insert(newIndex, item);
      // After moving, update positions to reflect current order
      for (int i = 0; i < _cardControllers.length; i++) {
        _cardControllers[i]['position'] = i;
      }
    });
  }

  Future<void> _pickImage(int index) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        Uint8List fileBytes = await pickedFile.readAsBytes();
        String fileName = pickedFile.name;
        setState(() {
          _cardControllers[index]['image'] = fileBytes;
          _cardControllers[index]['imageName'] = fileName;
        });
      } else {
        setState(() {
          _cardControllers[index]['image'] = pickedFile.path;
          _cardControllers[index]['imageName'] = basename(pickedFile.path);
        });
      }
    }
  }

  Widget _buildVideoUrlInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: _videoUrlController,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Video URL',
          hintText: 'Enter Video URL',
        ),
      ),
    );
  }

  Widget _buildImagePicker(int index) {
    return Column(
      children: [
        if (_cardControllers[index]['image'] != null ||
            _cardControllers[index]['imageUrl'].isNotEmpty)
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _cardControllers[index]['image'] != null
                ? Image.memory(
                    _cardControllers[index]['image'],
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    _cardControllers[index]['imageUrl'],
                    fit: BoxFit.cover,
                  ),
          ),
        ElevatedButton.icon(
          onPressed: () => _pickImage(index),
          icon: Icon(Icons.image),
          label: Text('Pick Image'),
        ),
      ],
    );
  }

  Future<void> _saveDeckAndCards() async {
    // Showing a progress indicator dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Uploading Images...'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return LinearProgressIndicator(
                value:
                    null, // null value shows an indeterminate progress bar initially
              );
            },
          ),
        );
      },
    );

    for (int i = 0; i < _cardControllers.length; i++) {
      var controller = _cardControllers[i];
      if (controller['image'] != null) {
        // New image has been selected; upload it
        try {
          String fileName = controller['imageName'];
          var image = controller['image'];

          if (kIsWeb) {
            Uint8List imageBytes = image as Uint8List;
            TaskSnapshot snapshot = await FirebaseStorage.instance
                .ref('card_images/${widget.deckId}/$fileName')
                .putData(imageBytes);
            String newImageUrl = await snapshot.ref.getDownloadURL();
            controller['imageUrl'] = newImageUrl; // Update with new image URL
          } else {
            File imageFile = File(image as String);
            TaskSnapshot snapshot = await FirebaseStorage.instance
                .ref('card_images/${widget.deckId}/${basename(imageFile.path)}')
                .putFile(imageFile);
            String newImageUrl = await snapshot.ref.getDownloadURL();
            controller['imageUrl'] = newImageUrl;
          }

          // Optionally update progress indicator here if you want to show detailed progress
        } catch (e) {
          print("Error uploading image: $e");
          // Handle error, perhaps close the dialog and show an error message
        }
      }

      await _firebaseService.updateDeck(
        widget.deckId,
        _deckTitleController.text,
        _videoUrlController.text,
        _cardControllers,
      );
    }

    // Close the progress dialog
    Navigator.pop(context); // Assuming this is how you close your dialog

    // Optional: show a success message or navigate away
    Navigator.of(context).pop(); // Navigate back to the previous screen
  }

  void _addCardController() {
    setState(() {
      _cardControllers.add({
        'front': TextEditingController(),
        'back': TextEditingController(),
        'position': _cardControllers.length, // Assign next position
      });
    });
  }

  @override
  void dispose() {
    _deckTitleController.dispose();
    _cardControllers.forEach((controllers) {
      controllers['front'].dispose();
      controllers['back'].dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Deck and Cards')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Deck Title',
                          style: Theme.of(context).textTheme.headline6),
                      SizedBox(height: 8),
                      TextField(
                        controller: _deckTitleController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter deck title',
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildVideoUrlInput(), // Add the Video URL input here
                      Text('Cards',
                          style: Theme.of(context).textTheme.headline6),
                      ..._cardControllers.asMap().entries.map((entry) {
                        int i = entry.key;
                        Map<String, dynamic> controller = entry.value;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                TextField(
                                  controller: controller['front'],
                                  decoration: InputDecoration(
                                    labelText: 'Front ${i + 1}',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextField(
                                  controller: controller['back'],
                                  decoration: InputDecoration(
                                    labelText: 'Back ${i + 1}',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.arrow_upward),
                                      onPressed: i > 0
                                          ? () => _moveCard(i, i - 1)
                                          : null,
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.arrow_downward),
                                      onPressed: i < _cardControllers.length - 1
                                          ? () => _moveCard(i, i + 1)
                                          : null,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                _buildImagePicker(i),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      ElevatedButton(
                        onPressed: _addCardController,
                        child: const Text('Add Another Card'),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _saveDeckAndCards,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Save Deck and Cards'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
