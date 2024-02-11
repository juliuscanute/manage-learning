import 'package:flutter/material.dart';
import 'package:manage_learning/data/firebase_service.dart';
import 'package:provider/provider.dart';

class AddCardsPage extends StatefulWidget {
  @override
  _AddCardsPageState createState() => _AddCardsPageState();
}

class _AddCardsPageState extends State<AddCardsPage> {
  late FirebaseService _firebaseService;
  final TextEditingController _deckTitleController = TextEditingController();
  final TextEditingController _videoeUrlController = TextEditingController();
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

  void _moveCardUp(int index) {
    if (index > 0) {
      setState(() {
        final item = _cardControllers.removeAt(index);
        _cardControllers.insert(index - 1, item);
      });
    }
  }

  void _moveCardDown(int index) {
    if (index < _cardControllers.length - 1) {
      setState(() {
        final item = _cardControllers.removeAt(index);
        _cardControllers.insert(index + 1, item);
      });
    }
  }

  Future<void> _saveDeckAndCards() async {
    var deckId = await _firebaseService.createDeck(_deckTitleController.text);

    // Save the Video URL to the deck
    if (_videoeUrlController.text.isNotEmpty) {
      await _firebaseService.updateDeckWithVideoUrl(
          deckId, _videoeUrlController.text);
    }

    for (var i = 0; i < _cardControllers.length; i++) {
      var controllers = _cardControllers[i];
      await _firebaseService.addCard(
        deckId,
        controllers['front']!.text,
        controllers['back']!.text,
        i, // Pass the index as the card's position
      );
    }
    var currentContext = context;
    Future.delayed(Duration.zero, () {
      Navigator.of(currentContext).pop();
    });
  }

  @override
  void dispose() {
    _deckTitleController.dispose();
    _videoeUrlController.dispose(); // Dispose of the Video URL controller
    for (var controller in _cardControllers) {
      controller['front']!.dispose();
      controller['back']!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Deck and Cards')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDeckTitleInput(),
                _buildVideoUrlInput(),
                _buildCardsList(),
                _buildAddCardButton(),
                _buildSaveDeckButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoUrlInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Video URL', style: Theme.of(context).textTheme.headline6),
        SizedBox(height: 8),
        TextField(
          controller: _videoeUrlController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter Video URL',
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDeckTitleInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Deck Title', style: Theme.of(context).textTheme.headline6),
        SizedBox(height: 8),
        TextField(
          controller: _deckTitleController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter deck title',
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCardsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cards', style: Theme.of(context).textTheme.headline6),
        for (int i = 0; i < _cardControllers.length; i++) _buildCardItem(i),
      ],
    );
  }

  Widget _buildCardItem(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                controller: _cardControllers[index]['front']!,
                decoration: InputDecoration(
                  labelText: 'Front ${index + 1}',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _cardControllers[index]['back']!,
                decoration: InputDecoration(
                  labelText: 'Back ${index + 1}',
                  border: OutlineInputBorder(),
                ),
              ),
              _buildMoveButtons(index),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoveButtons(int index) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (index != 0)
          IconButton(
            icon: Icon(Icons.arrow_upward),
            onPressed: () => _moveCardUp(index),
          ),
        if (index != _cardControllers.length - 1)
          IconButton(
            icon: Icon(Icons.arrow_downward),
            onPressed: () => _moveCardDown(index),
          ),
      ],
    );
  }

  Widget _buildAddCardButton() {
    return ElevatedButton(
      onPressed: _addCardController,
      child: const Text('Add Another Card'),
    );
  }

  Widget _buildSaveDeckButton() {
    return ElevatedButton(
      onPressed: _saveDeckAndCards,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      child: const Text('Save Deck and Cards'),
    );
  }
}
