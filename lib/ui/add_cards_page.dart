import 'package:flutter/material.dart';
import 'package:manage_learning/data/firebase_service.dart';
import 'package:provider/provider.dart';

class AddCardsPage extends StatefulWidget {
  @override
  _AddCardsPageState createState() => _AddCardsPageState();
}

class _AddCardsPageState extends State<AddCardsPage> {
  late FirebaseService _firebaseService;
  final TextEditingController _deckTitleController = TextEditingController();
  final List<Map<String, TextEditingController>> _cardControllers = [];

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
      });
    });
  }

  Future<void> _saveDeckAndCards() async {
    var deckId = await _firebaseService.createDeck(_deckTitleController.text);
    for (var controllers in _cardControllers) {
      await _firebaseService.addCard(
        deckId,
        controllers['front']!.text,
        controllers['back']!.text,
      );
    }
    var currentContext = context;
    Future.delayed(Duration.zero, () {
      Navigator.of(currentContext).pop();
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
      appBar: AppBar(title: const Text('Add New Deck and Cards')),
      body: Center(
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
