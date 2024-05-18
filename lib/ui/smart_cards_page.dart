// import 'dart:io';

import 'dart:io';

import 'package:path/path.dart' hide context;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manage_learning/data/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart'; // For uploading images
// Conditional import for handling files
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';

class SmartCardPage extends StatefulWidget {
  @override
  _SmartCardPageState createState() => _SmartCardPageState();
}

class _SmartCardPageState extends State<SmartCardPage> {
  late FirebaseService _firebaseService;
  final TextEditingController _deckTitleController = TextEditingController();
  final TextEditingController _videoeUrlController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _jsonController = TextEditingController();
  final Map<String, dynamic> _mapImageController = {
    'image': null, // Initialize image path as null
  };
  bool _isEvaluatorStrict = true;
  bool _isPublic = false;

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

  void _moveCardUp(int index) {
    if (index > 0) {
      setState(() {
        final item = _cardControllers.removeAt(index);
        _cardControllers.insert(index - 1, item);
      });
    }
  }

  void _moveCardDown(int index) {
    if (index < _cardControllers.length - 1) {
      setState(() {
        final item = _cardControllers.removeAt(index);
        _cardControllers.insert(index + 1, item);
      });
    }
  }

  Future<void> _saveDeckAndCards() async {
    List<String> tags =
        _tagsController.text.split('/').where((tag) => tag.isNotEmpty).toList();
    var deckId = await _firebaseService.createDeck(
        _deckTitleController.text, tags, _isEvaluatorStrict, _isPublic);

    // Save the Video URL to the deck
    if (_videoeUrlController.text.isNotEmpty) {
      await _firebaseService.updateDeckWithVideoUrl(
          deckId, _videoeUrlController.text);
    }

    final mapUrl =
        await uploadImage(_mapImageController, deckId, 'mindmap_images');
    if (mapUrl.isNotEmpty) {
      await _firebaseService.updateDeckWithMapUrl(deckId, mapUrl);
    }

    // For showing a linear progress indicator
    double totalUploadSteps = _cardControllers.length.toDouble();
    double currentStep = 0;

    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dialog from closing
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Uploading Cards...'),
            content: StatefulBuilder(
              builder: (context, setState) => LinearProgressIndicator(
                value: currentStep / totalUploadSteps,
              ),
            ),
          );
        },
      );
    });

    for (var i = 0; i < _cardControllers.length; i++) {
      var controllers = _cardControllers[i];
      String imageUrl = '';
      imageUrl = await uploadImage(_cardControllers[i], deckId, 'card_images');
      await _firebaseService.addCard(
        deckId,
        controllers['front']!.text,
        controllers['back']!.text,
        imageUrl,
        i, // Pass the index as the card's position
      );

      // Update progress
      setState(() {
        currentStep++;
      });
    }
    var currentContext = context;
    Future.delayed(Duration.zero, () {
      Navigator.pop(currentContext);
      Navigator.of(currentContext).pop();
    });
  }

  Future<String> uploadImage(Map<String, dynamic> controllers, String deckId,
      String pathPrefix) async {
    String imageUrl = "";

    if (controllers['image'] != null) {
      String fileName =
          controllers['imageName']; // Assume this is set during image picking
      try {
        if (kIsWeb) {
          Uint8List imageBytes = controllers['image'];
          TaskSnapshot snapshot = await FirebaseStorage.instance
              .ref('$pathPrefix/$deckId/$fileName')
              .putData(imageBytes);
          imageUrl = await snapshot.ref.getDownloadURL();
        } else {
          File imageFile = File(controllers['image']);
          TaskSnapshot snapshot = await FirebaseStorage.instance
              .ref('$pathPrefix/$deckId/${basename(imageFile.path)}')
              .putFile(imageFile);
          imageUrl = await snapshot.ref.getDownloadURL();
        }
      } catch (e) {
        print("Error uploading image: $e");
      }
    }

    return imageUrl;
  }

  @override
  void dispose() {
    _deckTitleController.dispose();
    _videoeUrlController.dispose(); // Dispose of the Video URL controller
    for (var controller in _cardControllers) {
      controller['front']!.dispose();
      controller['back']!.dispose();
    }
    super.dispose();
  }

  Widget _buildMultilineTextField() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _jsonController,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'JSON Deck',
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            // Parse the JSON string
            final Map<String, dynamic> jsonData =
                jsonDecode(_jsonController.text);

            // Set the values of the controllers
            setState(() {
              _deckTitleController.text = jsonData['title'];
              _cardControllers.clear();
              for (var flashcard in jsonData['flashcards']) {
                _cardControllers.add({
                  'front': TextEditingController(text: flashcard['front']),
                  'back': TextEditingController(text: flashcard['back']),
                });
              }
            });
          },
          child: const Text('Generate Deck'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Deck and Cards'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                // crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMultilineTextField(),
                  _buildDeckTitleInput(),
                  _buildVideoUrlInput(),
                  _buildEvaluatorStrictnessSwitch(),
                  _buildPublicSwitch(),
                  _buildImagePicker(_mapImageController, 'Pick Mind Map Image'),
                  _buildTagsInput(),
                  _buildCardsList(),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment
                  .spaceEvenly, // This centers the buttons horizontally and spaces them evenly.
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
                    padding: const EdgeInsets.only(
                        left: 8.0), // Add some space between the buttons
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

  Widget _buildPublicSwitch() {
    return Row(
      children: [
        Text('Is it public? ${_isPublic ? 'Yes' : 'No'}'),
        Switch(
          value: _isPublic,
          onChanged: (bool value) {
            setState(() {
              _isPublic = value;
            });
          },
        ),
      ],
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

  Widget _buildTagsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tags', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        TextField(
          controller: _tagsController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter tags (e.g., a/b/c)',
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildVideoUrlInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Video URL', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        TextField(
          controller: _videoeUrlController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter Video URL',
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDeckTitleInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Deck Title', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        TextField(
          controller: _deckTitleController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter deck title',
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCardsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cards', style: Theme.of(context).textTheme.headlineSmall),
        for (int i = 0; i < _cardControllers.length; i++) _buildCardItem(i),
      ],
    );
  }

  Widget _buildCardItem(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Card ${index + 1}',
                      style: Theme.of(context).textTheme.headlineSmall),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() {
                      _cardControllers.removeAt(index);
                    }),
                    tooltip: 'Delete Card',
                  ),
                ],
              ),
              TextField(
                controller:
                    _cardControllers[index]['front'] as TextEditingController,
                decoration: const InputDecoration(
                  labelText: 'Front',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller:
                    _cardControllers[index]['back'] as TextEditingController,
                decoration: const InputDecoration(
                  labelText: 'Back',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildImagePicker(
                    _cardControllers[index], "Pick Recall Image"),
              ), // Assuming this method builds your image picker UI
              _buildMoveButtons(index), // If you have move up/down buttons
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(
      Map<String, dynamic> imageController, String buttonText) {
    ImageProvider? imageProvider; // Mark as nullable

    // Check if there is an image for the current card
    if (imageController['image'] != null) {
      if (kIsWeb) {
        // For web, use MemoryImage with Uint8List
        Uint8List imageBytes = imageController['image'] as Uint8List;
        imageProvider = MemoryImage(imageBytes);
      } else {
        // For mobile, use FileImage with a File object
        String imagePath = imageController['image'] as String;
        imageProvider = FileImage(
            File(imagePath)); // Use the File class from the 'dart:io' package
      }

      // Return the image container if there's an image present
      return Column(
        children: [
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.cover,
                image: imageProvider,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _pickImage(imageController),
            icon: const Icon(Icons.image),
            label: Text(buttonText),
          ),
        ],
      );
    }

    // Return a placeholder or button if no image is available
    return ElevatedButton.icon(
      onPressed: () => _pickImage(imageController),
      icon: const Icon(Icons.image),
      label: Text(buttonText),
    );
  }

  Future<void> _pickImage(Map<String, dynamic> imageController) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Different handling for web
      if (kIsWeb) {
        // Read the file as bytes and store it
        Uint8List fileBytes = await pickedFile.readAsBytes();
        String fileName = pickedFile.name;
        setState(() {
          imageController['image'] = fileBytes;
          imageController['imageName'] =
              fileName; // Store the file name separately
        });
      } else {
        setState(() {
          imageController['image'] = pickedFile.path;
        });
      }
    }
  }

  Widget _buildMoveButtons(int index) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (index != 0)
          IconButton(
            icon: const Icon(Icons.arrow_upward),
            onPressed: () => _moveCardUp(index),
          ),
        IconButton(
          icon: const Icon(Icons.vertical_align_top), // Icon for adding above
          onPressed: () => _addCardAbove(index),
          tooltip: 'Add Card Above',
        ),
        IconButton(
          icon:
              const Icon(Icons.vertical_align_bottom), // Icon for adding below
          onPressed: () => _addCardBelow(index),
          tooltip: 'Add Card Below',
        ),
        if (index != _cardControllers.length - 1)
          IconButton(
            icon: const Icon(Icons.arrow_downward),
            onPressed: () => _moveCardDown(index),
          ),
      ],
    );
  }

  void _addCardAbove(int index) {
    setState(() {
      _cardControllers.insert(index, {
        'front': TextEditingController(),
        'back': TextEditingController(),
        'image': null,
      });
    });
  }

  void _addCardBelow(int index) {
    setState(() {
      // Insert below, so add 1 to the index
      _cardControllers.insert(index + 1, {
        'front': TextEditingController(),
        'back': TextEditingController(),
        'image': null,
      });
    });
  }
}
