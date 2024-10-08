import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class Deck {
  final String id;
  final String title;
  final List<Map<String, dynamic>> cards;
  final List<String> tags; // Add tags field

  Deck({
    required this.id,
    required this.title,
    required this.cards,
    required this.tags, // Add tags to the constructor
  });
}

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  Map<String, dynamic> _originalCardsState = <String, dynamic>{};

  Stream<List<Map<String, dynamic>>> getDecksStream() {
    return _firestore.collection('decks').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                'title': doc.data()['title'] ?? '',
                'videoUrl': doc.data()['videoUrl'] ?? '',
                'exactMatch': doc.data()['exactMatch'] ?? true,
                'tags':
                    List.from(doc.data()['tags'] ?? []), // Include tags here
                'mapUrl': doc.data()['mapUrl'] ?? '',
              })
          .toList();
    });
  }

  Future<Map<String, dynamic>> getDeckData(String deckId) async {
    var deckData = <String, dynamic>{};

    var deckRef = _firestore.collection('decks').doc(deckId);
    var deckSnapshot = await deckRef.get();
    if (!deckSnapshot.exists) {
      throw Exception("Deck not found");
    }
    deckData['title'] = deckSnapshot.data()?['title'] ?? '';
    deckData['videoUrl'] = deckSnapshot.data()?['videoUrl'] ?? '';
    deckData['tags'] =
        List.from(deckSnapshot.data()?['tags'] ?? []); // Add tags here
    deckData['mapUrl'] = deckSnapshot.data()?['mapUrl'] ?? '';
    deckData['exactMatch'] = deckSnapshot.data()?['exactMatch'] ?? true;
    deckData['isPublic'] =
        deckSnapshot.data()?['isPublic'] ?? false; // Add isPublic here

    // Fetch the cards ordered by 'position'
    var cardsSnapshot =
        await deckRef.collection('cards').orderBy('position').get();
    var cards = cardsSnapshot.docs
        .asMap() // Convert to map to access index
        .map((index, doc) => MapEntry(index, {
              'id': doc.id,
              'front': doc.data()['front'] ?? '',
              'front_tex': doc.data()['front_tex'] ?? '',
              'back': doc.data()['back'] ?? '',
              'back_tex': doc.data()['back_tex'] ?? '',
              'imageUrl': doc.data()['imageUrl'] ?? '',
              'position':
                  doc.data()['position'] ?? index, // Use map index as fallback
              'mcq': doc.data()['mcq'] ?? {},
              'explanation': doc.data()['explanation'] ?? '',
              'explanation_tex': doc.data()['explanation_tex'] ?? '',
              'mnemonic': doc.data()['mnemonic'] ?? '',
            }))
        .values // Convert back to iterable
        .toList();
    deckData['cards'] = cards;
    _originalCardsState = deckData;
    return deckData;
  }

  Future<String> createDeck(
      String title, List<String> tags, bool exactMatch, bool isPublic) async {
    try {
      var newDeckRef = await _firestore.collection('decks').add({
        'title': title,
        'tags': tags,
        'exactMatch': exactMatch,
        'isPublic': isPublic, // Add isPublic here
      });
      return newDeckRef.id;
    } catch (e) {
      print("Error creating deck: $e");
      return '';
    }
  }

  Future<String> duplicateDeck(Map<String, dynamic> deck) async {
    try {
      Map<String, dynamic> newDeck = Map.from(deck);
      newDeck['title'] = newDeck['title'] + ' (Copy)';
      var newDeckRef = _firestore.collection('decks').doc();

      newDeck = await duplicateImageInData(
          newDeck, 'mapUrl', newDeckRef, 'mindmap_images');

      await newDeckRef.set(newDeck);

      var cardsSnapshot = await _firestore
          .collection('decks')
          .doc(deck['id'])
          .collection('cards')
          .get();

      for (var cardDoc in cardsSnapshot.docs) {
        var card = cardDoc.data();

        card = await duplicateImageInData(
            card, 'imageUrl', newDeckRef, 'card_images');
        await _firestore
            .collection('decks')
            .doc(newDeckRef.id)
            .collection('cards')
            .add(card);
      }

      return newDeckRef.id;
    } catch (e) {
      print("Error duplicating deck: $e");
      return '';
    }
  }

  Future<Map<String, dynamic>> duplicateImageInData(Map<String, dynamic> data,
      String imageUrlKey, DocumentReference newDocRef, String imagePath) async {
    // Check if imageUrl is not null or empty
    if (data[imageUrlKey] != null && data[imageUrlKey].isNotEmpty) {
      // Get the URL of the new image
      var newImageUrl =
          await duplicateImage(data[imageUrlKey], newDocRef, imagePath);

      // Update the imageUrl in the data
      data[imageUrlKey] = newImageUrl;
    }
    return data;
  }

  Future<String> duplicateImage(
      String imageUrl, DocumentReference newDeckRef, String pathPrefix) async {
    // Download the image
    var response = await http.get(Uri.parse(imageUrl));
    var imageData = response.bodyBytes;

    // Upload the image to a new location
    var newImageRef = FirebaseStorage.instance
        .ref()
        .child('$pathPrefix/${newDeckRef.id}/${path.basename(imageUrl)}');
    await newImageRef.putData(imageData);

    // Get the URL of the new image
    var newImageUrl = await newImageRef.getDownloadURL();

    return newImageUrl;
  }

  Map<String, dynamic> constructDeckUpdates(String title, String videoUrl,
      String mapUrl, bool exactMatch, List<String> tags, bool isPublic) {
    Map<String, dynamic> updates = {};
    if (_originalCardsState['title'] != title) {
      updates['title'] = title;
    }
    if (_originalCardsState['videoUrl'] != videoUrl) {
      updates['videoUrl'] = videoUrl;
    }
    if (_originalCardsState['mapUrl'] != mapUrl) {
      updates['mapUrl'] = mapUrl;
    }
    if (_originalCardsState['tags'] != tags) {
      updates['tags'] = tags;
    }
    if (_originalCardsState['exactMatch'] != exactMatch) {
      updates['exactMatch'] = exactMatch;
    }
    if (_originalCardsState['isPublic'] != isPublic) {
      updates['isPublic'] = isPublic;
    }
    return updates;
  }

  Future<void> updateDeck(
      String deckId,
      String title,
      String videoUrl,
      String mapUrl,
      bool exactMatch,
      List<Map<String, dynamic>> cards,
      List<String> tags,
      bool isPublic) async {
    WriteBatch batch = _firestore.batch();
    DocumentReference deckRef = _firestore.collection('decks').doc(deckId);

    // Construct the updates map
    Map<String, dynamic> deckUpdates = constructDeckUpdates(
        title, videoUrl, mapUrl, exactMatch, tags, isPublic);
    ;
    if (deckUpdates.isNotEmpty) {
      batch.update(deckRef, deckUpdates);
    }

    // Handle cards
    var cardCollection = deckRef.collection('cards');

    // Assuming you have a way to identify new vs existing cards, e.g., by checking if they have an 'id'
    for (var card in cards) {
      DocumentReference cardRef;

      // Find the original state of the card, if it exists
      final originalCard = _originalCardsState['cards'].firstWhere(
          (c) => c['id'] == card['id'],
          orElse: () => <String, dynamic>{});

      // Check if the card has been modified
      bool isModified = (originalCard['front'] != card['front'] ||
              originalCard['front_tex'] != card['front_tex'] ||
              originalCard['back'] != card['back'] ||
              originalCard['back_tex'] != card['back_tex'] ||
              originalCard['imageUrl'] != card['imageUrl'] ||
              originalCard['position'] != card['position']) ||
          originalCard['mcq'] != card['mcq'] ||
          originalCard['explanation'] != card['explanation'] ||
          originalCard['explanation_tex'] != card['explanation_tex'] ||
          originalCard['mnemonic'] != card['mnemonic'];

      if (card.containsKey('id') && card['id'] != null && isModified) {
        // Existing card, update
        cardRef = cardCollection.doc(card['id']);
        batch.update(cardRef, {
          'front': card['front'],
          'front_tex': card['front_tex'],
          'back': card['back'],
          'back_tex': card['back_tex'],
          'imageUrl': card['imageUrl'],
          'position': card['position'],
          'mcq': card['mcq'],
          'explanation': card['explanation'],
          'explanation_tex': card['explanation_tex'],
          'mnemonic': card['mnemonic'],
        });
      } else if (!card.containsKey('id') || card['id'] == null) {
        // New card, add
        cardRef = cardCollection.doc(); // Let Firestore generate a new ID
        batch.set(cardRef, {
          'front': card['front'],
          'front_tex': card['front_tex'],
          'back': card['back'],
          'back_tex': card['back_tex'],
          'imageUrl': card['imageUrl'],
          'position': card['position'],
          'mcq': card['mcq'],
          'explanation': card['explanation'],
          'explanation_tex': card['explanation_tex'],
          'mnemonic': card['mnemonic'],
        });
      }
    }

    // Identify and delete removed cards
    Set<String> currentCardIds =
        Set.from(cards.map((card) => card['id'].toString()));
    Set<String> originalCardIds = Set.from(
        _originalCardsState['cards'].map((card) => card['id'].toString()));
    Set<String> idsToDelete = originalCardIds.difference(currentCardIds);

    for (String idToDelete in idsToDelete) {
      DocumentReference cardRef = deckRef.collection('cards').doc(idToDelete);
      batch.delete(cardRef);
    }

    // Commit the batch operation
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

  Future<void> updateDeckWithMapUrl(String deckId, String mapUrl) async {
    try {
      await _firestore.collection('decks').doc(deckId).update({
        'mapUrl': mapUrl,
      });
    } catch (e) {
      print("Error updating deck with Map URL: $e");
      // Handle any errors appropriately in your app context
    }
  }

  Future<void> deleteCard(String deckId, String cardId) async {
    await _firestore
        .collection('decks')
        .doc(deckId)
        .collection('cards')
        .doc(cardId)
        .delete();
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

  Future<void> addCard(
      String deckId,
      String front,
      String? frontTex,
      String back,
      String? backTex,
      String? imageUrl,
      Map<String, dynamic> mcq,
      String? explanation,
      String? explanationTex,
      String? mnemonic,
      int position) async {
    await _firestore.collection('decks').doc(deckId).collection('cards').add({
      'front': front,
      'front_tex': frontTex,
      'back': back,
      'back_tex': backTex,
      'imageUrl': imageUrl, // Include the image URL in the saved data
      'position': position, // Include the position in the saved data
      'mcq': mcq,
      'explanation': explanation,
      'explanation_tex': explanationTex,
      'mnemonic': mnemonic,
    });
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
