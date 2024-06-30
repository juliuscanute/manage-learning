import 'dart:collection';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:manage_learning/data/firebase_service.dart';
import 'package:manage_learning/ui/category_card.dart';
import 'package:manage_learning/ui/deck_list_item.dart';
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
      appBar: AppBar(
        title: const Text('Decks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: () {
              Navigator.of(context).pushNamed('/smart-deck');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
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
          decks.sort((a, b) => a['title'].compareTo(b['title']));

          var categories = SplayTreeMap<String, List<Map<String, dynamic>>>();
          for (var deck in decks) {
            if (deck['tags'].isNotEmpty) {
              String category = deck['tags'][0];
              categories.putIfAbsent(category, () => []).add(deck);
            }
          }

          List<Widget> children = [];

          // For categories with decks, create a CategoryCard
          categories.forEach((category, decksInCategory) {
            children.add(CategoryCard(
                categoryList: [], // Assuming you have logic to populate this
                category: category,
                deck: decksInCategory));
          });

          // Add DeckCards for decks without a category directly to the list
          decks.where((deck) => deck['tags'].isEmpty).forEach((deck) {
            children.add(DeckListItem(deck: deck));
          });

          return SingleChildScrollView(
            // Enable scrolling in both directions if needed
            scrollDirection:
                Axis.vertical, // Commonly, vertical scrolling is desired
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate the number of columns based on screen width
                int crossAxisCount = constraints.maxWidth > 800 ? 4 : 1;

                // Calculate the width of each child based on the number of columns
                double width =
                    (constraints.maxWidth - (crossAxisCount - 1) * 10) /
                        crossAxisCount;

                return Wrap(
                  spacing: 10, // Horizontal space between items
                  runSpacing: 10, // Vertical space between items
                  children: List.generate(children.length, (index) {
                    return SizedBox(
                      width: width,
                      // Height is not specified to allow content to determine the height
                      child: children[index],
                    );
                  }),
                );
              },
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
