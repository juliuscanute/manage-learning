import 'package:flutter/material.dart';
import 'package:manage_learning/data/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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

  void _showAddCards() {
    Navigator.of(context).pushNamed('/addcards');
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
                  "No decks available. Tap the '+' button to add a new deck."),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: 600), // Max width of the cards
              child: ListView.builder(
                itemCount: decks.length,
                itemBuilder: (context, index) {
                  var deck = decks[index];
                  // Initialize an empty list for the actions
                  List<Widget> trailingActions = [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.of(context)
                            .pushNamed('/editcards', arguments: deck['id']);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _firebaseService.deleteDeck(deck['id']),
                    ),
                  ];

                  // Conditionally add the play icon if videoUrl is not empty
                  var videoUrl = Uri.parse(deck['videoUrl'] ?? "");
                  if (videoUrl.isAbsolute) {
                    trailingActions.add(
                      IconButton(
                        icon: const Icon(Icons.play_circle_fill),
                        onPressed: () async {
                          if (await canLaunchUrl(videoUrl)) {
                            await launchUrl(videoUrl);
                          } else {
                            // Handle the case where the YouTube URL cannot be launched or is missing
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Cannot open video URL')),
                            );
                          }
                        },
                      ),
                    );
                  }

                  return Card(
                    elevation: 4,
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: ListTile(
                      title: Text(deck['title'],
                          style: Theme.of(context).textTheme.titleLarge),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: trailingActions,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCards,
        tooltip: 'Add Deck',
        child: const Icon(Icons.add),
      ),
    );
  }
}
