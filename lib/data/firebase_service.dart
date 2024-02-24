import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class Deck {
  final String id;
  final String title;
  final List<Map<String, dynamic>> cards;

  Deck({required this.id, required this.title, required this.cards});
}

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<List<Map<String, dynamic>>> getDecksStream() {
    return _firestore.collection('decks').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                'title': doc.data()['title'],
                'videoUrl': doc.data()['videoUrl'] ?? ''
              })
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
    deckData['videoUrl'] = deckSnapshot.data()?['videoUrl'] ?? '';

    // Fetch the cards ordered by 'position'
    var cardsSnapshot =
        await deckRef.collection('cards').orderBy('position').get();
    var cards = cardsSnapshot.docs
        .asMap() // Convert to map to access index
        .map((index, doc) => MapEntry(index, {
              'id': doc.id,
              'front': doc.data()['front'] ?? '',
              'back': doc.data()['back'] ?? '',
              'imageUrl': doc.data()['imageUrl'] ?? '',
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

  Future<void> updateDeck(String deckId, String title, String videoUrl,
      List<Map<String, dynamic>> cards) async {
    var batch = _firestore.batch();

    // Update the deck title
    var deckRef = _firestore.collection('decks').doc(deckId);
    batch.update(deckRef, {'title': title, 'videoUrl': videoUrl});

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
        'front': (card['front'] as TextEditingController).text,
        'back': (card['back'] as TextEditingController).text,
        'imageUrl': card['imageUrl'], // Include the card's image URL
        'position': i, // Include the card's position
      });
    }

    await batch.commit();
  }

  Future<void> updateDeckWithVideoUrl(String deckId, String videoUrl) async {
    try {
      await _firestore.collection('decks').doc(deckId).update({
        'videoUrl': videoUrl,
      });
    } catch (e) {
      print("Error updating deck with Video URL: $e");
      // Handle any errors appropriately in your app context
    }
  }

  Future<void> deleteDeck(String deckId) async {
    var cardsSnapshot = await _firestore
        .collection('decks')
        .doc(deckId)
        .collection('cards')
        .get();
    for (var doc in cardsSnapshot.docs) {
      var imageUrl = doc.data()['imageUrl'];
      deleteImage(imageUrl);
    }
    await _firestore.collection('decks').doc(deckId).delete();
  }

  Future<void> addCard(String deckId, String front, String back,
      String imageUrl, int position) async {
    await _firestore.collection('decks').doc(deckId).collection('cards').add({
      'front': front,
      'back': back,
      'imageUrl': imageUrl, // Include the image URL in the saved data
      'position': position, // Include the position in the saved data
    });
  }

  Future<void> updateCard(String deckId, String cardId, String front,
      String back, String position, String imageUrl) async {
    await _firestore
        .collection('decks')
        .doc(deckId)
        .collection('cards')
        .doc(cardId)
        .update({
      'front': front,
      'back': back,
      'position': position,
      'imageUrl': imageUrl
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

  Future<void> deleteImage(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      return;
    }
    try {
      // Create a reference to the storage item using the URL
      Reference ref = _storage.refFromURL(imageUrl);
      // Delete the image
      await ref.delete();
      print("Old image deleted successfully");
    } catch (e) {
      print("Error deleting old image: $e");
    }
  }
}
