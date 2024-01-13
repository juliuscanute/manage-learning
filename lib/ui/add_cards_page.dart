import 'package:flutter/material.dart';
import 'package:manage_learning/data/firebase_service.dart';
import 'package:provider/provider.dart';

class AddCardsPage extends StatefulWidget {
  final String deckId;

  const AddCardsPage({super.key, required this.deckId});

  @override
  _AddCardsPageState createState() => _AddCardsPageState();
}

class _AddCardsPageState extends State<AddCardsPage> {
  late FirebaseService _firebaseService;
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

  void _saveCards() async {
    for (var controllers in _cardControllers) {
      await _firebaseService.addCard(widget.deckId, controllers['front']!.text, controllers['back']!.text);
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    for (var controllers in _cardControllers) {
      controllers['front']!.dispose();
      controllers['back']!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Cards')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            for (var controllers in _cardControllers)
              Card(
                child: Column(
                  children: [
                    TextField(
                      controller: controllers['front']!,
                      decoration: const InputDecoration(labelText: 'Front'),
                    ),
                    TextField(
                      controller: controllers['back']!,
                      decoration: const InputDecoration(labelText: 'Back'),
                    ),
                  ],
                ),
              ),
            ElevatedButton(
              onPressed: _addCardController,
              child: const Text('Add Another Card'),
            ),
            ElevatedButton(
              onPressed: _saveCards,
              child: const Text('Save Cards'),
            ),
          ],
        ),
      ),
    );
  }
}
