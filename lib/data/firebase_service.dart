import 'package:cloud_firestore/cloud_firestore.dart';

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

    // Fetch the cards
    var cardsSnapshot = await deckRef.collection('cards').get();
    var cards = cardsSnapshot.docs
        .map((doc) => {
              'front': doc.data()['front'] ?? '',
              'back': doc.data()['back'] ?? '',
            })
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

    // Add new cards
    for (var card in cards) {
      var newCardRef =
          cardCollection.doc(); // Generating a new document reference
      batch.set(newCardRef, {
        'front': card['front'],
        'back': card['back'],
      });
    }

    // Commit the batch
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
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                'front': doc.data()['front'],
                'back': doc.data()['back'],
              })
          .toList();
    });
  }

  Future<void> addCard(String deckId, String front, String back) async {
    await _firestore.collection('decks').doc(deckId).collection('cards').add({
      'front': front,
      'back': back,
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
