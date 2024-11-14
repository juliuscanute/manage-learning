import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
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
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Map<String, dynamic> _originalCardsState = <String, dynamic>{};

  final StreamController<void> _changeController =
      StreamController<void>.broadcast();

  Stream<void> get changeStream => _changeController.stream;

  FirebaseService() {
    _firestore.settings = const Settings(persistenceEnabled: true);
  }

  void notifyListeners() {
    _changeController.add(null);
  }

  Future<void> logAnalyticsEvent(
      String eventName, Map<String, dynamic> parameters) async {
    await _analytics.logEvent(
      name: eventName,
      parameters: parameters,
    );
  }

  Stream<List<Map<String, dynamic>>> getFoldersStream() {
    return _firestore.collection('folder').snapshots().map((snapshot) {
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, 'name': data['name'] ?? ''};
      }).toList();
      items.sort((a, b) => a['name'].compareTo(b['name']));
      logAnalyticsEvent(
          "read_operation", {"collection": "folder", "size": items.length});
      return items;
    });
  }

// Method to read subfolders of a folder from Firestore
// /folder/{folderId}/subfolder/ - Returns subfolder in this collection
// /folder/{folderId}/subfolder/{subfolderId}/subfolder - Returns subfolder in this collection
// Input will contain the parent path with id
  Future<List<Map<String, dynamic>>> getSubFolders(String parentPath) async {
    try {
      var subFolders = <Map<String, dynamic>>[];
      var subFolderSnapshot = await _firestore.collection(parentPath).get();

      for (var subFolder in subFolderSnapshot.docs) {
        var folderData = subFolder.data();
        if (folderData['hasSubfolders'] == true) {
          subFolders.add({
            'id': subFolder.id,
            'name': folderData['name'] ?? '',
            'hasSubfolders': true,
          });
        } else {
          subFolders.add({
            'id': subFolder.id,
            'name': folderData['name'] ?? '',
            'deckId': folderData['deckId'] ?? '',
            'title': folderData['title'] ?? '',
            'isPublic': folderData['isPublic'] ?? false,
            'type': 'card',
            'hasSubfolders': false,
          });
        }
      }

      logAnalyticsEvent("read_operation", {
        "collection": "folder",
        "parentPath": parentPath,
        "size": subFolders.length
      });
      subFolders.sort((a, b) => a['name'].compareTo(b['name']));
      return subFolders;
    } catch (error) {
      print('Error reading subfolders from Firestore: $error');
      return [];
    }
  }

  Future<Map<String, dynamic>> getDeckData(String deckId) async {
    try {
      var deckRef = _firestore.collection('decks').doc(deckId);
      var deckSnapshot = await deckRef.get();
      if (!deckSnapshot.exists) {
        throw Exception("Deck not found");
      }
      var deckData = deckSnapshot.data()!;
      deckData['id'] = deckSnapshot.id;

      // Fetch the cards ordered by 'position'
      var cardsSnapshot =
          await deckRef.collection('cards').orderBy('position').get();
      var cards = cardsSnapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      deckData['cards'] = cards;
      _originalCardsState = deckData;
      logAnalyticsEvent("read_operation",
          {"collection": "decks", "deckId": deckId, "size": cards.length});
      return deckData;
    } catch (error) {
      throw Exception("Error fetching deck data: $error");
    }
  }

  Future<String> createDeck(
      String title, List<String> tags, bool exactMatch, bool isPublic) async {
    try {
      // Create the deck in the final collection

      var newDeckRef = await _firestore.collection('decks').add({
        'title': title,
        'tags': tags,
        'exactMatch': exactMatch,
        'isPublic': isPublic, // Add isPublic here
      });
      final deckId = newDeckRef.id;
      await _createTagPath(tags, deckId, title, exactMatch, isPublic);
      notifyListeners();
      logAnalyticsEvent("write_operation", {
        "collection": "decks",
        "deckId": deckId,
        "title": title,
        "tags": tags,
        "exactMatch": exactMatch,
        "isPublic": isPublic,
      });
      return deckId;
    } catch (e) {
      print("Error creating deck: $e");
      return '';
    }
  }

  Future<void> _createTagPath(List<String> tags, String deckId, String title,
      bool exactMatch, bool isPublic) async {
    // Start with the root collection
    CollectionReference currentRef = _firestore.collection('folder');

    // If tags are empty, place in "OTHERS" folder
    if (tags.isEmpty) {
      final othersDoc = currentRef.doc('OTHERS');
      final othersSnapshot = await othersDoc.get();
      if (!othersSnapshot.exists) {
        await othersDoc.set({
          'name': 'OTHERS',
          'hasSubfolders': false,
        });
      }
      currentRef = othersDoc.collection('subfolders');
    } else {
      // Navigate through the tags to construct the path
      for (int i = 0; i < tags.length; i++) {
        final tag = tags[i];
        final folderDoc = currentRef.doc(tag);
        final folderSnapshot = await folderDoc.get();
        if (!folderSnapshot.exists) {
          await folderDoc.set({
            'name': tag,
            'hasSubfolders': true,
          });
        } else {
          await folderDoc.update({'hasSubfolders': true});
        }
        // Move to the next subfolder collection
        currentRef = folderDoc.collection('subfolders');
      }
    }

    final finalDocRef = currentRef.doc();
    await finalDocRef.set({
      'title': title,
      'deckId': deckId,
      'tags': tags,
      'exactMatch': exactMatch,
      'isPublic': isPublic,
      'type': 'card',
      'hasSubfolders': false,
    });

    logAnalyticsEvent("write_operation", {
      "collection": "folder",
      "deckId": deckId,
      "title": title,
      "tags": tags,
      "exactMatch": exactMatch,
      "isPublic": isPublic,
    });
  }

  Future<void> duplicateCategory(String parentPath, String folderId) async {
    try {
      // Reference to the folder document
      final folderDocRef = _firestore.collection(parentPath).doc(folderId);

      // Check if the folder has any subcollections
      final subcollections = await folderDocRef.collection('subfolders').get();
      for (var subfolder in subcollections.docs) {
        await duplicateCategory(
            '$parentPath/$folderId/subfolders', subfolder.id);
      }
      //Get data for parentPath & folderId
      final folderSnapshot = await folderDocRef.get();
      final folderData = folderSnapshot.data();
      //Extract all neccessary data to deck
      final deckData = {
        'deckId': folderData?['deckId'] ?? '',
        'title': folderData?['title'] ?? '',
        'tags': List.from(folderData?['tags'] ?? []),
        'exactMatch': folderData?['exactMatch'] ?? true,
        'isPublic': folderData?['isPublic'] ?? false,
        'parentPath': parentPath,
      };
      //Duplicate deck
      await duplicateDeck(deckData);
      logAnalyticsEvent("write_operation", {
        "collection": "folder",
        "parentPath": parentPath,
        "folderId": folderId,
      });
      notifyListeners();
    } catch (e) {
      print("Error duplicating category: $e");
    }
  }

  Future<String> duplicateDeck(Map<String, dynamic> deck) async {
    try {
      Map<String, dynamic> newDeck = Map.from(deck);
      List<String> tags = recreateTagsFromPath(deck['parentPath']);

      newDeck['title'] = newDeck['title'] + ' (Copy)';
      newDeck['tags'] = tags;
      var newDeckRef = _firestore.collection('decks').doc();

      newDeck = await duplicateImageInData(
          newDeck, 'mapUrl', newDeckRef, 'mindmap_images');

      await newDeckRef.set(newDeck);

      var cardsSnapshot = await _firestore
          .collection('decks')
          .doc(deck['deckId'])
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
      _createTagPath(tags, newDeckRef.id, newDeck['title'] ?? '',
          newDeck['exactMatch'] ?? false, newDeck['isPublic'] ?? false);
      logAnalyticsEvent("write_operation", {
        "collection": "decks",
        "deckId": newDeckRef.id,
        "title": newDeck['title'],
        "tags": tags,
        "exactMatch": newDeck['exactMatch'],
        "isPublic": newDeck['isPublic'],
      });
      notifyListeners();
      return newDeckRef.id;
    } catch (e) {
      print("Error duplicating deck: $e");
      return '';
    }
  }

  List<String> recreateTagsFromPath(String path) {
    // Split the path by the '/' delimiter
    List<String> segments = path.split('/');

    // Filter out the "folder" and "subfolders" segments
    List<String> tags = [];
    for (int i = 0; i < segments.length; i++) {
      if (segments[i] != 'folder' && segments[i] != 'subfolders') {
        tags.add(segments[i]);
      }
    }

    return tags;
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

  Map<String, dynamic> constructDeckUpdates(
      Map<String, dynamic> deck,
      String deckId,
      String title,
      String videoUrl,
      String mapUrl,
      bool exactMatch,
      List<String> tags,
      bool isPublic) {
    Map<String, dynamic> updates = {};
    if (_originalCardsState['title'] != title) {
      updates['title'] = title;
      updateFolderTitle(deck['parentPath'], deck['folderId'], title);
      // Update deck title
    }
    if (_originalCardsState['videoUrl'] != videoUrl) {
      updates['videoUrl'] = videoUrl;
      updateFolderVideoUrl(deck['parentPath'], deck['folderId'], videoUrl);
    }
    if (_originalCardsState['mapUrl'] != mapUrl) {
      updates['mapUrl'] = mapUrl;
      updateFolderMapUrl(deck['parentPath'], deck['folderId'], mapUrl);
    }
    if (_originalCardsState['tags'] != tags) {
      updates['tags'] = tags;
      _createTagPath(tags, deckId, title, exactMatch, isPublic);
      deleteFolderIfEmpty(deck['parentPath'], deck['folderId']);
      updateFolderTags(deck['parentPath'], deck['folderId'], tags);
    }
    if (_originalCardsState['exactMatch'] != exactMatch) {
      updates['exactMatch'] = exactMatch;
      updateFolderExactMatch(deck['parentPath'], deck['folderId'], exactMatch);
    }
    if (_originalCardsState['isPublic'] != isPublic) {
      updates['isPublic'] = isPublic;
      updateFolderIsPublic(deck['parentPath'], deck['folderId'], isPublic);
    }
    return updates;
  }

  Future<void> updateDeck(
      Map<String, dynamic> deck,
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
        deck, deckId, title, videoUrl, mapUrl, exactMatch, tags, isPublic);

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

    logAnalyticsEvent("write_operation", {
      "collection": "decks",
      "deckId": deckId,
      "title": title,
      "tags": tags,
      "exactMatch": exactMatch,
      "isPublic": isPublic,
      "size": cards.length,
    });
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
    logAnalyticsEvent("delete_operation", {
      "collection": "decks",
      "deckId": deckId,
      "cardId": cardId,
    });
  }

  Future<void> deleteDeck(
      String deckId, String parentPath, String folderId) async {
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
    await deleteFolderIfEmpty(parentPath, folderId);
    logAnalyticsEvent("delete_operation", {
      "collection": "decks",
      "deckId": deckId,
    });
    notifyListeners();
  }

  Future<void> updateFolderTitle(
      String parentPath, String folderId, String title) async {
    try {
      await _firestore.collection(parentPath).doc(folderId).update({
        'title': title,
      });
    } catch (e) {
      print("Error updating folder title: $e");
    }
  }

  Future<void> updateFolderVideoUrl(
      String parentPath, String folderId, String videoUrl) async {
    try {
      await _firestore.collection(parentPath).doc(folderId).update({
        'videoUrl': videoUrl,
      });
    } catch (e) {
      print("Error updating folder video URL: $e");
    }
  }

  Future<void> updateFolderMapUrl(
      String parentPath, String folderId, String mapUrl) async {
    try {
      await _firestore.collection(parentPath).doc(folderId).update({
        'mapUrl': mapUrl,
      });
    } catch (e) {
      print("Error updating folder map URL: $e");
    }
  }

  Future<void> updateFolderTags(
      String parentPath, String folderId, List<String> tags) async {
    try {
      await _firestore.collection(parentPath).doc(folderId).update({
        'tags': tags,
      });
    } catch (e) {
      print("Error updating folder tags: $e");
    }
  }

  Future<void> updateFolderExactMatch(
      String parentPath, String folderId, bool exactMatch) async {
    try {
      await _firestore.collection(parentPath).doc(folderId).update({
        'exactMatch': exactMatch,
      });
    } catch (e) {
      print("Error updating folder exact match: $e");
    }
  }

  Future<void> updateFolderIsPublic(
      String parentPath, String folderId, bool isPublic) async {
    try {
      await _firestore.collection(parentPath).doc(folderId).update({
        'isPublic': isPublic,
      });
    } catch (e) {
      print("Error updating folder is public: $e");
    }
  }

  Future<void> deleteFolderIfEmpty(String parentPath, String folderId) async {
    try {
      // Reference to the folder document
      final folderDocRef = _firestore.collection(parentPath).doc(folderId);

      // Check if the folder has any subcollections
      final subcollections = await folderDocRef.collection('subfolders').get();
      if (subcollections.docs.isNotEmpty) {
        // Folder has subcollections, do not delete
        return;
      }

      // Check if the folder has any documents
      final folderSnapshot = await folderDocRef.get();
      if (!folderSnapshot.exists) {
        // Folder does not exist, nothing to delete
        return;
      }

      // Delete the folder document
      await folderDocRef.delete();

      // Recursively check and delete parent folders if they become empty
      final parentSegments = parentPath.split('/');
      if (parentSegments.length > 2) {
        // Remove the last two segments to move one level up
        parentSegments.removeLast(); // Remove the "subfolders" keyword
        final parentFolderId =
            parentSegments.removeLast(); // Remove the folder ID
        final newParentPath = parentSegments.join('/');
        await deleteFolderIfEmpty(newParentPath, parentFolderId);
      }
    } catch (e) {
      print("Error deleting folder: $e");
    }
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
