import 'package:flutter/material.dart';
import 'package:manage_learning/data/firebase_service.dart';
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

  Future<void> _saveDeckAndCards() async {
    await _firebaseService.updateDeck(
      widget.deckId,
      _deckTitleController.text,
      _videoUrlController
          .text, // Include this in your updateDeck method parameters
      _cardControllers.map((controllers) {
        return {
          'front': controllers['front'].text,
          'back': controllers['back'].text,
          'position': controllers['position'], // Save with updated position
        };
      }).toList(),
    );
    Navigator.pop(context);
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
