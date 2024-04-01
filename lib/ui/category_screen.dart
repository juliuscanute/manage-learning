import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:manage_learning/data/firebase_service.dart';
import 'package:manage_learning/ui/category_card.dart';
import 'package:manage_learning/ui/deck_list_item.dart';
import 'package:provider/provider.dart';

class CategoryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> decks;
  final List<String> categoryList;

  CategoryScreen({required this.decks, required this.categoryList});

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late FirebaseService _firebaseService;

  @override
  void initState() {
    super.initState();
    _firebaseService = Provider.of<FirebaseService>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.categoryList.last),
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _firebaseService.getDecksStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return Center(child: Text('No decks found'));
            }

            final decks = snapshot.data ?? widget.decks;

            // Filter decks that belong to the current category/subcategories
            final relevantDecks = decks.where((deck) {
              final tags = List<String>.from(deck['tags']);
              // Check if the deck's categories match up to the current category list
              return tags.take(widget.categoryList.length).toList().join(',') ==
                  widget.categoryList.join(',');
            }).toList();

            // Group remaining decks by their next subcategory
            final subcategoryGroups =
                SplayTreeMap<String, List<Map<String, dynamic>>>();
            for (var deck in relevantDecks) {
              final tags = List<String>.from(deck['tags']);
              // Remove the current category path to find potential subcategories
              final remainingTags =
                  tags.skip(widget.categoryList.length).toList();
              if (remainingTags.isNotEmpty) {
                final subcategory = remainingTags.first;
                subcategoryGroups.putIfAbsent(subcategory, () => []).add(deck);
              }
            }

            List<Widget> children = [];

            // Create a CategoryCard for each subcategory group
            subcategoryGroups.forEach((subcategory, decks) {
              final updatedCategoryList =
                  List<String>.from(widget.categoryList);
              children.add(CategoryCard(
                categoryList: updatedCategoryList,
                category: subcategory,
                deck: decks,
              ));
            });

            // Add DeckCards for decks without further subcategories
            final noSubcategoryDecks = relevantDecks.where((deck) {
              final remainingTags = List<String>.from(deck['tags'])
                  .skip(widget.categoryList.length)
                  .toList();
              return remainingTags.isEmpty;
            }).toList();
            noSubcategoryDecks.forEach((deck) {
              children.add(DeckListItem(deck: deck));
            });

            return ListView(children: children);
          },
        ));
  }
}
