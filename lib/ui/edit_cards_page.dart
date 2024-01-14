import 'package:flutter/material.dart';
import 'package:manage_learning/data/firebase_service.dart';
import 'package:provider/provider.dart';

class EditCardsPage extends StatefulWidget {
  final String deckId;
  const EditCardsPage({required this.deckId, super.key});

  @override
  _EditCardsPageState createState() => _EditCardsPageState();
}

class _EditCardsPageState extends State<EditCardsPage> {
  late FirebaseService _firebaseService;
  final TextEditingController _deckTitleController = TextEditingController();
  late List<Map<String, TextEditingController>> _cardControllers = [];
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

  var fetchedCards = deckData['cards'] as List<Map<String, dynamic>>;
  _cardControllers = fetchedCards.map((cardData) {
    return {
      'front': TextEditingController(text: cardData['front'] as String),
      'back': TextEditingController(text: cardData['back'] as String),
    };
  }).toList();

  setState(() => _isLoading = false);
}



  void _addCardController() {
    setState(() {
      _cardControllers.add({
        'front': TextEditingController(),
        'back': TextEditingController(),
      });
    });
  }

  Future<void> _saveDeckAndCards() async {
    // Update the deck and its cards
    await _firebaseService.updateDeck(
      widget.deckId,
      _deckTitleController.text,
      _cardControllers.map((controllers) {
        return {
          'front': controllers['front']!.text,
          'back': controllers['back']!.text,
        };
      }).toList(),
    );
    var currentContext = context;
    Future.delayed(Duration.zero, () {
      Navigator.pop(currentContext);
    });
  }

  @override
  void dispose() {
    _deckTitleController.dispose();
    for (var controllers in _cardControllers) {
      controllers['front']!.dispose();
      controllers['back']!.dispose();
    }
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
                constraints: BoxConstraints(maxWidth: 600), // Max width of the content
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      Text('Cards', style: Theme.of(context).textTheme.headline6),
                      for (var i = 0; i < _cardControllers.length; i++)
                        Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _cardControllers[i]['front']!,
                                  decoration: InputDecoration(
                                    labelText: 'Front ${i + 1}',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextField(
                                  controller: _cardControllers[i]['back']!,
                                  decoration: InputDecoration(
                                    labelText: 'Back ${i + 1}',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ElevatedButton(
                        onPressed: _addCardController,
                        child: const Text('Add Another Card'),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _saveDeckAndCards,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, // Button color
                          foregroundColor: Colors.white, // Text color
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
