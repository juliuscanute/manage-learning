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
  final TextEditingController _tagsController = TextEditingController();
  final Map<String, dynamic> _mindmapImageController = {
    'image': null, // Initialize image path as null
    'imageUrl': '', // Initialize image URL as empty
  };

  final ImagePicker _picker = ImagePicker();

  late List<Map<String, dynamic>> _cardControllers = []; // Include positioning
  bool _isLoading = true;
  bool _isEvaluatorStrict = true;

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
    _mindmapImageController['imageUrl'] = deckData['mapUrl'] ?? '';
    setState(() {
      _isEvaluatorStrict = deckData['exactMatch'] ?? true;
    });
    List<String> tags = List.from(deckData['tags'] ?? []);
    _tagsController.text = tags.join('/');

    // Adjusted to handle positioning
    var fetchedCards = deckData['cards'] as List<Map<String, dynamic>>;
    _cardControllers = fetchedCards
        .map((cardData) => {
              'id': cardData['id'], // Store ID
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

  Widget _buildTagsInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: _tagsController,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Tags',
          hintText: 'Enter tags (e.g., a/b/c)',
        ),
      ),
    );
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

  Widget _buildImagePicker(
      Map<String, dynamic> cardController, String buttonText) {
    return Column(
      children: [
        if (cardController['image'] != null ||
            cardController['imageUrl']?.isNotEmpty == true)
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: cardController['image'] != null
                ? Image.memory(
                    cardController['image'],
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    cardController['imageUrl'],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.error,
                          size: 24,
                          color: Colors.red,
                        ),
                      );
                    },
                  ),
          ),
        ElevatedButton.icon(
          onPressed: () => _pickImage(cardController),
          icon: Icon(Icons.image),
          label: Text(buttonText),
        ),
      ],
    );
  }

  Future<void> _pickImage(Map<String, dynamic> cardController) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        Uint8List fileBytes = await pickedFile.readAsBytes();
        String fileName = pickedFile.name;
        setState(() {
          cardController['image'] = fileBytes;
          cardController['imageName'] = fileName;
        });
      } else {
        setState(() {
          cardController['image'] = pickedFile.path;
          cardController['imageName'] = basename(pickedFile.path);
        });
      }
    }
  }

  Future<void> uploadImage(
      Map<String, dynamic> controller, String pathPrefix) async {
    // New image has been selected; upload it
    if (controller['image'] == null) return;
    try {
      String fileName = controller['imageName'];
      var image = controller['image'];

      if (kIsWeb) {
        Uint8List imageBytes = image as Uint8List;
        TaskSnapshot snapshot = await FirebaseStorage.instance
            .ref('$pathPrefix/${widget.deckId}/$fileName')
            .putData(imageBytes);
        await _firebaseService.deleteImage(controller['imageUrl']);
        String newImageUrl = await snapshot.ref.getDownloadURL();
        controller['imageUrl'] = newImageUrl; // Update with new image URL
      } else {
        File imageFile = File(image as String);
        TaskSnapshot snapshot = await FirebaseStorage.instance
            .ref('$pathPrefix/${widget.deckId}/${basename(imageFile.path)}')
            .putFile(imageFile);
        await _firebaseService.deleteImage(controller['imageUrl']);
        String newImageUrl = await snapshot.ref.getDownloadURL();
        controller['imageUrl'] = newImageUrl;
      }

      // Optionally update progress indicator here if you want to show detailed progress
    } catch (e) {
      print("Error uploading image: $e");
      // Handle error, perhaps close the dialog and show an error message
    }
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

    await uploadImage(_mindmapImageController, 'mindmap_images');
    for (int i = 0; i < _cardControllers.length; i++) {
      var controller = _cardControllers[i];
      await uploadImage(controller, 'card_images');
    }

    List<String> tags =
        _tagsController.text.split('/').where((tag) => tag.isNotEmpty).toList();

    await _firebaseService.updateDeck(
      widget.deckId,
      _deckTitleController.text,
      _videoUrlController.text,
      _mindmapImageController['imageUrl'],
      _isEvaluatorStrict,
      _cardControllers
          .map((e) => {
                'id': e['id'],
                'front': e['front'].text,
                'back': e['back'].text,
                'imageUrl': e['imageUrl'],
                'position': e['position'],
              })
          .toList(),
      tags,
    );

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
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildDeckTitle(),
                          SizedBox(height: 8),
                          _buildDeckTitleInput(),
                          SizedBox(height: 16),
                          _buildVideoUrlInput(),
                          _buildEvaluatorStrictnessSwitch(),
                          _buildMindmapImagePicker(),
                          _buildTagsInput(),
                          _buildCardsTitle(),
                          _buildCardsList(),
                        ],
                      ),
                    ),
                  ),
          ),
          _buildButtonRow(),
        ],
      ),
    );
  }

  Widget _buildEvaluatorStrictnessSwitch() {
    return Row(
      children: [
        Text(
            'Do you want the evaluator to be strict? ${_isEvaluatorStrict ? 'YES' : 'NO'}'),
        Switch(
          value: _isEvaluatorStrict,
          onChanged: (bool value) {
            setState(() {
              _isEvaluatorStrict = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildButtonRow() {
    return Container(
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
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
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
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: Text('Save Deck and Cards'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeckTitle() {
    return Text('Deck Title', style: Theme.of(context).textTheme.headline6);
  }

  Widget _buildDeckTitleInput() {
    return TextField(
      controller: _deckTitleController,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Enter deck title',
      ),
    );
  }

  Widget _buildMindmapImagePicker() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _buildImagePicker(_mindmapImageController, 'Pick Mindmap Image'),
    );
  }

  Widget _buildCardsTitle() {
    return Text('Cards', style: Theme.of(context).textTheme.headline6);
  }

  Widget _buildCardsList() {
    return Column(
      children: _cardControllers
          .asMap()
          .entries
          .map((entry) => _buildCard(entry.value, entry.key))
          .toList(),
    );
  }

  Widget _buildCard(Map<String, dynamic> controller, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Stack(
        children: [
          Padding(
            padding:
                const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
            child: Column(
              children: [
                SizedBox(height: 24),
                TextField(
                  controller: controller['front'] as TextEditingController,
                  decoration: const InputDecoration(
                    labelText: 'Front',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller['back'] as TextEditingController,
                  decoration: const InputDecoration(
                    labelText: 'Back',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                _buildImagePicker(controller, 'Pick Recall Image'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.vertical_align_top),
                      onPressed: () => _addCardAbove(index),
                      tooltip: 'Add Card Above',
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_upward),
                      onPressed:
                          index == 0 ? null : () => _moveCard(index, index - 1),
                      tooltip: 'Move Up',
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_downward),
                      onPressed: index == _cardControllers.length - 1
                          ? null
                          : () => _moveCard(index, index + 1),
                      tooltip: 'Move Down',
                    ),
                    IconButton(
                      icon: Icon(Icons.vertical_align_bottom),
                      onPressed: () => _addCardBelow(index),
                      tooltip: 'Add Card Below',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 8,
            top: 0,
            child: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                if (controller['imageUrl'] != null &&
                    controller['imageUrl'].isNotEmpty) {
                  await _firebaseService.deleteImage(controller['imageUrl']);
                }
                setState(() {
                  _cardControllers.removeAt(index);
                });
              },
              tooltip: 'Delete Card',
            ),
          ),
        ],
      ),
    );
  }

  void _addCardAbove(int index) {
    setState(() {
      _cardControllers.insert(index, {
        'front': TextEditingController(),
        'back': TextEditingController(),
        'image': null,
        'imageUrl': '',
        'position':
            index, // You might need to adjust positions if you use them for ordering
      });
      // After adding, update positions for all cards
      for (int i = 0; i < _cardControllers.length; i++) {
        _cardControllers[i]['position'] = i;
      }
    });
  }

  void _addCardBelow(int index) {
    setState(() {
      _cardControllers.insert(index + 1, {
        'front': TextEditingController(),
        'back': TextEditingController(),
        'image': null,
        'imageUrl': '',
        'position': index + 1,
      });
      // After adding, update positions for all cards
      for (int i = 0; i < _cardControllers.length; i++) {
        _cardControllers[i]['position'] = i;
      }
    });
  }
}
