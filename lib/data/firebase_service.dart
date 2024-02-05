import 'package:cloud_firestore/cloud_firestore.dart';

class Deck {
  final String id;
  final String title;
  final List<Map<String, dynamic>> cards;

  Deck({required this.id, required this.title, required this.cards});
}

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getDecksStream() {
    return _firestore.collection('decks').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => {'id': doc.id, 'title': doc.data()['title']})
          .toList();
    });
  }

  Future<Map<String, dynamic>> getDeckData(String deckId) async {
    var deckData = <String, dynamic>{};

    // Fetch the deck document
    var deckRef = _firestore.collection('decks').doc(deckId);
    var deckSnapshot = await deckRef.get();
    if (!deckSnapshot.exists) {
      throw Exception("Deck not found");
    }
    deckData['title'] = deckSnapshot.data()?['title'] ?? '';

    // Fetch the cards ordered by 'position'
    var cardsSnapshot =
        await deckRef.collection('cards').orderBy('position').get();
    var cards = cardsSnapshot.docs
        .asMap() // Convert to map to access index
        .map((index, doc) => MapEntry(index, {
              'front': doc.data()['front'] ?? '',
              'back': doc.data()['back'] ?? '',
              'position':
                  doc.data()['position'] ?? index, // Use map index as fallback
            }))
        .values // Convert back to iterable
        .toList();
    deckData['cards'] = cards;

    return deckData;
  }

  Future<String> createDeck(String title) async {
    try {
      var newDeckRef = await _firestore.collection('decks').add({
        'title': title,
      });
      return newDeckRef.id; // Return the newly created deck ID
    } catch (e) {
      print("Error creating deck: $e");
      return ''; // Return an empty string or handle the error as needed
    }
  }

  Future<void> updateDeck(
      String deckId, String title, List<Map<String, dynamic>> cards) async {
    var batch = _firestore.batch();

    // Update the deck title
    var deckRef = _firestore.collection('decks').doc(deckId);
    batch.update(deckRef, {'title': title});

    // Delete existing cards
    var cardCollection = deckRef.collection('cards');
    var existingCards = await cardCollection.get();
    for (var doc in existingCards.docs) {
      batch.delete(doc.reference);
    }

    // Add new cards with positions
    for (var i = 0; i < cards.length; i++) {
      var card = cards[i];
      var newCardRef =
          cardCollection.doc(); // Generating a new document reference
      batch.set(newCardRef, {
        'front': card['front'],
        'back': card['back'],
        'position': i, // Include the card's position
      });
    }

    await batch.commit();
  }

  Future<void> deleteDeck(String deckId) async {
    await _firestore.collection('decks').doc(deckId).delete();
  }

  Stream<List<Map<String, dynamic>>> getCardsStream(String deckId) {
    return _firestore
        .collection('decks')
        .doc(deckId)
        .collection('cards')
        .orderBy('position', descending: false) // Attempt to order by position
        .snapshots()
        .map((snapshot) {
      var docs = snapshot.docs;
      // Check if documents have the 'position' field; if not, rely on their index
      var arePositionsAvailable =
          docs.any((doc) => doc.data().containsKey('position'));

      List<Map<String, dynamic>> cards;
      if (arePositionsAvailable) {
        // If positions are available, sort by position
        cards = docs
            .map((doc) => {
                  'id': doc.id,
                  'front': doc.data()['front'],
                  'back': doc.data()['back'],
                  // Including position for debugging or UI purposes
                  'position': doc.data()['position'] ?? docs.indexOf(doc),
                })
            .toList();
      } else {
        // Fallback to using the index if position is not available
        cards = docs.asMap().entries.map((entry) {
          int idx = entry.key;
          var doc = entry.value;
          return {
            'id': doc.id,
            'front': doc.data()['front'],
            'back': doc.data()['back'],
            // Use index as fallback position
            'position': idx,
          };
        }).toList();
      }

      // Note: This sorting is a fallback and might not be needed if 'orderBy' is effective
      // Sort based on position to ensure order, especially if relying on index as fallback
      cards.sort(
          (a, b) => (a['position'] as int).compareTo(b['position'] as int));

      return cards;
    });
  }

  Future<void> addCard(
      String deckId, String front, String back, int position) async {
    await _firestore.collection('decks').doc(deckId).collection('cards').add({
      'front': front,
      'back': back,
      'position': position, // Include the position in the saved data
    });
  }

  Future<void> updateCard(
      String deckId, String cardId, String front, String back) async {
    await _firestore
        .collection('decks')
        .doc(deckId)
        .collection('cards')
        .doc(cardId)
        .update({
      'front': front,
      'back': back,
    });
  }

  Future<void> deleteCard(String deckId, String cardId) async {
    await _firestore
        .collection('decks')
        .doc(deckId)
        .collection('cards')
        .doc(cardId)
        .delete();
  }
}
