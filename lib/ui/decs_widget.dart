// decks_widget.dart

import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:manage_learning/data/firebase_service.dart';
import 'package:manage_learning/ui/category_card.dart';
import 'package:manage_learning/ui/deck_list_item.dart';
import 'package:provider/provider.dart';

class DecksWidget extends StatelessWidget {
  const DecksWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: firebaseService.getDecksStream(),
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
          scrollDirection: Axis.vertical,
          child: LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 800 ? 4 : 1;
              double width =
                  (constraints.maxWidth - (crossAxisCount - 1) * 10) /
                      crossAxisCount;

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(children.length, (index) {
                  return SizedBox(
                    width: width,
                    child: children[index],
                  );
                }),
              );
            },
          ),
        );
      },
    );
  }
}
