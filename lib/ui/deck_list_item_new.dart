import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_learning/ui/study_deck/app_bloc.dart';
import 'package:manage_learning/ui/study_deck/app_event.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class DeckListItemNew extends StatefulWidget {
  final Map<String, dynamic> deck;

  DeckListItemNew({required this.deck});

  @override
  _DeckListItemNewState createState() => _DeckListItemNewState();
}

class _DeckListItemNewState extends State<DeckListItemNew> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: ListTile(
        title: Text(widget.deck['title'],
            style: Theme.of(context).textTheme.titleLarge),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: _buildTrailingActions(context),
        ),
      ),
    );
  }

  List<Widget> _buildTrailingActions(BuildContext context) {
    List<Widget> trailingActions = [
      IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () {
          Navigator.of(context)
              .pushNamed('/editcards', arguments: widget.deck)
              .then((_) {
            context
                .read<AppBloc>()
                .add(RefreshCategories(widget.deck['parentPath']));
          });
        },
      ),
      IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () async {
          context.read<AppBloc>().add(DeleteDeck(widget.deck['deckId'],
              widget.deck['parentPath'], widget.deck['folderId']));
        },
      ),
      IconButton(
        icon: const Icon(Icons.copy),
        onPressed: () async {
          context
              .read<AppBloc>()
              .add(DuplicateDeck(widget.deck, widget.deck['parentPath']));
        },
      ),
    ];

    var videoUrl = Uri.parse(widget.deck['videoUrl'] ?? "");
    if (videoUrl.isAbsolute) {
      trailingActions.add(
        IconButton(
          icon: const Icon(Icons.play_circle_fill),
          onPressed: () async {
            if (await canLaunchUrl(videoUrl)) {
              await launchUrl(videoUrl);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cannot open video URL')),
              );
            }
          },
        ),
      );
    }

    return trailingActions;
  }
}
