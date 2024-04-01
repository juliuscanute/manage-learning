import 'package:flutter/material.dart';
import 'package:manage_learning/data/firebase_service.dart';
import 'package:provider/provider.dart';

class CategoryCard extends StatefulWidget {
  final List<String> categoryList;
  final String category;
  final List<Map<String, dynamic>> deck;

  CategoryCard({
    required this.categoryList,
    required this.category,
    required this.deck,
  });

  @override
  _CategoryCardState createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  late FirebaseService _firebaseService;

  @override
  void initState() {
    super.initState();
    _firebaseService = Provider.of<FirebaseService>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(widget.category, style: const TextStyle(fontSize: 18.0)),
        trailing: IconButton(
          icon: const Icon(Icons.copy),
          onPressed: () {
            _duplicateDeck();
          },
        ),
        onTap: () async {
          Navigator.pushNamed(context, '/category-screen', arguments: {
            'categoryList': List<String>.from(widget.categoryList)
              ..add(widget.category),
            'decks': widget.deck,
          });
        },
      ),
    );
  }

  void _duplicateDeck() {
    final newCategoryList = List<String>.from(widget.categoryList)
      ..add(widget.category);
    final lastIndex = newCategoryList.length - 1;
    for (var item in widget.deck) {
      List<String> tags = item['tags'].cast<String>();
      tags[lastIndex] = '${tags[lastIndex]} (Copy)';
      item['tags'] = tags;
      _firebaseService.duplicateDeck(item);
    }
  }
}
