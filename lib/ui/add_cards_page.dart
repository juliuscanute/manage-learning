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

class AddCardsPage extends StatefulWidget {
  @override
  _AddCardsPageState createState() => _AddCardsPageState();
}

class _AddCardsPageState extends State<AddCardsPage> {
  late FirebaseService _firebaseService;
  final TextEditingController _deckTitleController = TextEditingController();
  final TextEditingController _videoeUrlController = TextEditingController();
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
    var deckId = await _firebaseService.createDeck(_deckTitleController.text);

    // Save the Video URL to the deck
    if (_videoeUrlController.text.isNotEmpty) {
      await _firebaseService.updateDeckWithVideoUrl(
          deckId, _videoeUrlController.text);
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

      if (controllers['image'] != null) {
        String fileName =
            controllers['imageName']; // Assume this is set during image picking
        try {
          if (kIsWeb) {
            Uint8List imageBytes = controllers['image'];
            TaskSnapshot snapshot = await FirebaseStorage.instance
                .ref('card_images/$deckId/$fileName')
                .putData(imageBytes);
            imageUrl = await snapshot.ref.getDownloadURL();
          } else {
            File imageFile = File(controllers['image']);
            TaskSnapshot snapshot = await FirebaseStorage.instance
                .ref('card_images/$deckId/${basename(imageFile.path)}')
                .putFile(imageFile);
            imageUrl = await snapshot.ref.getDownloadURL();
          }
          // Continue with saving card details
        } catch (e) {
          print("Error uploading image: $e");
        }
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Deck and Cards')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDeckTitleInput(),
                _buildVideoUrlInput(),
                _buildCardsList(),
                _buildAddCardButton(),
                _buildSaveDeckButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoUrlInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Video URL', style: Theme.of(context).textTheme.headline6),
        SizedBox(height: 8),
        TextField(
          controller: _videoeUrlController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter Video URL',
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDeckTitleInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Deck Title', style: Theme.of(context).textTheme.headline6),
        SizedBox(height: 8),
        TextField(
          controller: _deckTitleController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter deck title',
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCardsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cards', style: Theme.of(context).textTheme.headline6),
        for (int i = 0; i < _cardControllers.length; i++) _buildCardItem(i),
      ],
    );
  }

  Widget _buildCardItem(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                controller: _cardControllers[index]['front']!,
                decoration: InputDecoration(
                  labelText: 'Front ${index + 1}',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _cardControllers[index]['back']!,
                decoration: InputDecoration(
                  labelText: 'Back ${index + 1}',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 8),
              _buildImagePicker(index),
              _buildMoveButtons(index),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(int index) {
    ImageProvider? imageProvider; // Mark as nullable

    // Check if there is an image for the current card
    if (_cardControllers[index]['image'] != null) {
      if (kIsWeb) {
        // For web, use MemoryImage with Uint8List
        Uint8List imageBytes = _cardControllers[index]['image'] as Uint8List;
        imageProvider = MemoryImage(imageBytes);
      } else {
        // For mobile, use FileImage with a File object
        String imagePath = _cardControllers[index]['image'] as String;
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
                image: imageProvider!,
              ),
            ),
          ),
          SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _pickImage(index),
            icon: Icon(Icons.image),
            label: Text('Pick Recall Image'),
          ),
        ],
      );
    }

    // Return a placeholder or button if no image is available
    return ElevatedButton.icon(
      onPressed: () => _pickImage(index),
      icon: Icon(Icons.image),
      label: Text('Pick Recall Image'),
    );
  }

  Future<void> _pickImage(int index) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Different handling for web
      if (kIsWeb) {
        // Read the file as bytes and store it
        Uint8List fileBytes = await pickedFile.readAsBytes();
        String fileName = pickedFile.name;
        setState(() {
          _cardControllers[index]['image'] = fileBytes;
          _cardControllers[index]['imageName'] =
              fileName; // Store the file name separately
        });
      } else {
        setState(() {
          _cardControllers[index]['image'] = pickedFile.path;
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
            icon: Icon(Icons.arrow_upward),
            onPressed: () => _moveCardUp(index),
          ),
        if (index != _cardControllers.length - 1)
          IconButton(
            icon: Icon(Icons.arrow_downward),
            onPressed: () => _moveCardDown(index),
          ),
      ],
    );
  }

  Widget _buildAddCardButton() {
    return ElevatedButton(
      onPressed: _addCardController,
      child: const Text('Add Another Card'),
    );
  }

  Widget _buildSaveDeckButton() {
    return ElevatedButton(
      onPressed: () => _saveDeckAndCards(),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      child: const Text('Save Deck and Cards'),
    );
  }
}
