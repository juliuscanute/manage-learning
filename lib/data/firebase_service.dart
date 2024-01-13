import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getDecksStream() {
    return _firestore.collection('decks').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        'title': doc.data()['title']
      }).toList();
    });
  }

Future<String> createDeck(String title) async {
    var newDeckRef = await _firestore.collection('decks').add({
      'title': title,
    });
    return newDeckRef.id; // Return the newly created deck ID
  }

  Future<void> deleteDeck(String deckId) async {
    await _firestore.collection('decks').doc(deckId).delete();
  }

  Future<void> updateDeckTitle(String deckId, String title) async {
    await _firestore.collection('decks').doc(deckId).update({'title': title});
  }

  Stream<List<Map<String, dynamic>>> getCardsStream(String deckId) {
    return _firestore.collection('decks').doc(deckId).collection('cards').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        'front': doc.data()['front'],
        'back': doc.data()['back'],
      }).toList();
    });
  }

  Future<void> addCard(String deckId, String front, String back) async {
    await _firestore.collection('decks').doc(deckId).collection('cards').add({
      'front': front,
      'back': back,
    });
  }

  Future<void> updateCard(String deckId, String cardId, String front, String back) async {
    await _firestore.collection('decks').doc(deckId).collection('cards').doc(cardId).update({
      'front': front,
      'back': back,
    });
  }

  Future<void> deleteCard(String deckId, String cardId) async {
    await _firestore.collection('decks').doc(deckId).collection('cards').doc(cardId).delete();
  }
}
