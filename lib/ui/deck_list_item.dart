import 'package:flutter/material.dart';
import 'package:manage_learning/data/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class DeckListItem extends StatefulWidget {
  final Map<String, dynamic> deck;

  DeckListItem({required this.deck});

  @override
  _DeckListItemState createState() => _DeckListItemState();
}

class _DeckListItemState extends State<DeckListItem> {
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
              .pushNamed('/editcards', arguments: widget.deck['id']);
        },
      ),
      IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () => _firebaseService.deleteDeck(widget.deck['id']),
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
}
