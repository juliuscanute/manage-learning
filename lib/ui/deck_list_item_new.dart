import 'package:flutter/material.dart';
import 'package:manage_learning/data/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class DeckListItemNew extends StatefulWidget {
  final Map<String, dynamic> deck;

  DeckListItemNew({required this.deck});

  @override
  _DeckListItemNewState createState() => _DeckListItemNewState();
}

class _DeckListItemNewState extends State<DeckListItemNew> {
  late FirebaseService _firebaseService;

  @override
  void initState() {
    super.initState();
    _firebaseService = Provider.of<FirebaseService>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> trailingActions = [
      IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () {
          Navigator.of(context)
              .pushNamed('/editcards', arguments: widget.deck['deckId']);
        },
      ),
      IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () async {
          await _firebaseService.deleteDeck(widget.deck['deckId'],
              widget.deck['parentPath'], widget.deck['folderId']);
        },
      ),
      IconButton(
        icon: const Icon(Icons.copy),
        onPressed: () async {
          await _duplicateDeck();
        },
      ),
    ];

    // Conditionally add the play icon if videoUrl is not empty
    var videoUrl = Uri.parse(widget.deck['videoUrl'] ?? "");
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
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: ListTile(
        title: Text(widget.deck['title'],
            style: Theme.of(context).textTheme.titleLarge),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: trailingActions,
        ),
      ),
    );
  }

  Future<void> _duplicateDeck() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return FutureBuilder<String>(
          future: _firebaseService.duplicateDeck(widget.deck),
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                content: Row(
                  children: [
                    CircularProgressIndicator(),
                    Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Text('Duplicating deck...'),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.of(context).pop();
              return Container();
            }
          },
        );
      },
    );
  }
}
