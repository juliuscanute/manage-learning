import 'package:flutter/material.dart';
import 'package:manage_learning/data/firebase_service.dart';
import 'package:provider/provider.dart';

class DecksPage extends StatefulWidget {
  const DecksPage({super.key});

  @override
  _DecksPageWidgetState createState() => _DecksPageWidgetState();
}

class _DecksPageWidgetState extends State<DecksPage> {
  late FirebaseService _firebaseService;

  @override
  void initState() {
    super.initState();
    _firebaseService = Provider.of<FirebaseService>(context, listen: false);
  }

  Future<void> _showAddDeckDialog(BuildContext context) async {
    TextEditingController titleController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add New Deck'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(hintText: 'Deck Title'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                // if (titleController.text.isNotEmpty) {
                  String deckId =
                      await _firebaseService.createDeck(titleController.text);
                  print('New deck ID: $deckId');
                  // Navigate to AddCardsPage with the new deckId
                  var currentContext = context;
                  Future.delayed(Duration.zero, () {
                    Navigator.of(currentContext).pop();
                    Navigator.pushReplacementNamed(currentContext, '/addcards', arguments: deckId);
                  });
                // }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Decks")),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firebaseService.getDecksStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          var decks = snapshot.data ?? [];
          if (decks.isEmpty) {
            return const Center(
                child: Text(
                    "No decks available. Tap the '+' button to add a new deck."));
          }

          return ListView.builder(
            itemCount: decks.length,
            itemBuilder: (context, index) {
              var deck = decks[index];
              return ListTile(
                title: Text(deck['title']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        // Navigate to edit deck title page
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _firebaseService.deleteDeck(deck['id']),
                    ),
                  ],
                ),
                onTap: () {
                  // Navigate to cards page for this deck
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDeckDialog(context),
        tooltip: 'Add Deck',
        child: const Icon(Icons.add),
      ),
    );
  }
}
