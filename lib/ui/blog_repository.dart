import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class BlogRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final StreamController<void> _changeController =
      StreamController<void>.broadcast();

  Stream<void> get changeStream => _changeController.stream;

  BlogRepository() {
    _firestore.settings = const Settings(persistenceEnabled: true);
  }

  void notifyListeners() {
    _changeController.add(null);
  }

  Future<void> addIsPublicFlag(String collectionPath, bool isPublic) async {
    try {
      await _firestore.doc(collectionPath).update({
        'isPublic': isPublic,
      });
    } catch (e) {
      print("Error adding isPublic flag: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getFolders() async {
    try {
      final snapshot = await _firestore.collection('blogFolders').get();
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'isPublic': data['isPublic'] ?? true
        };
      }).toList();
      items.sort((a, b) => a['name'].compareTo(b['name']));
      return items;
    } catch (e) {
      print('Error getting folders: $e');
      return [];
    }
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
            'isPublic': folderData['isPublic'] ?? true,
          });
        } else {
          subFolders.add({
            'id': subFolder.id,
            'blogId': folderData['blogId'] ?? '',
            'title': folderData['title'] ?? '',
            'type': 'card',
            'hasSubfolders': false,
          });
        }
      }

      // Ensure all names and titles are strings and handle null values
      subFolders.sort((a, b) {
        bool hasABlogId = a.containsKey('blogId') && a['blogId'] != null;
        bool hasBBlockId = b.containsKey('blogId') && b['blogId'] != null;

        if (hasABlogId && hasBBlockId) {
          String titleA = (a['title'] ?? '').toString().toLowerCase();
          String titleB = (b['title'] ?? '').toString().toLowerCase();
          return titleA.compareTo(titleB);
        } else if (hasABlogId && !hasBBlockId) {
          return 1;
        } else if (!hasABlogId && hasBBlockId) {
          return -1;
        } else {
          String idA = (a['id'] ?? '').toString().toLowerCase();
          String idB = (b['id'] ?? '').toString().toLowerCase();
          return idA.compareTo(idB);
        }
      });

      return subFolders;
    } catch (error) {
      print('Error reading subfolders from Firestore: $error');
      return [];
    }
  }

  Future<String> uploadImage(XFile imageFile) async {
    final String fileName =
        '${DateTime.now().millisecondsSinceEpoch}${imageFile.path.split('/').last}';
    final Reference storageRef = _storage.ref().child('blog_images/$fileName');
    final UploadTask uploadTask =
        storageRef.putData(await imageFile.readAsBytes());
    final TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  Future<void> deleteImage(String imageUrl) async {
    await _storage.refFromURL(imageUrl).delete();
  }

  Future<void> deleteBlogPost(
      String id, String parentPath, String folderId) async {
    try {
      final DocumentSnapshot docSnapshot =
          await _firestore.collection('blogs').doc(id).get();
      if (docSnapshot.exists) {
        final String markdown = docSnapshot['markdown'];
        final RegExp imageUrlRegExp = RegExp(r'!\[.*?\]\((.*?)\)');
        final Iterable<RegExpMatch> initialMatches =
            imageUrlRegExp.allMatches(markdown);
        final matches = initialMatches.map((match) => match.group(1)!).toList();
        for (final match in matches) {
          final String imageUrl = Uri.decodeFull(match);
          await deleteImage(imageUrl);
        }
        await _firestore.collection('blogs').doc(id).delete();
        await deleteFolderIfEmpty(parentPath, folderId);
        notifyListeners();
      }
    } catch (e) {
      print('Error deleting blog post: $e');
    }
  }

  Future<String> saveBlogPost(
      String title, String markdown, String tags) async {
    final docRef = await _firestore.collection('blogs').add({
      'title': title,
      'markdown': markdown,
      'tags': tags,
      'created_at': FieldValue.serverTimestamp(),
    });
    notifyListeners();
    return docRef.id;
  }

  Future<Map<String, dynamic>?> getBlogPostById(String id) async {
    try {
      final DocumentSnapshot docSnapshot =
          await _firestore.collection('blogs').doc(id).get();
      if (docSnapshot.exists) {
        return docSnapshot.data() as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting blog post by ID: $e');
      return null;
    }
  }

  Future<void> updateBlogPost(String id, String title, String markdown,
      String tags, String parentPath, String folderId) async {
    final currentBlogEntry = await getBlogPostById(id);
    if (currentBlogEntry != null) {
      bool shouldUpdate = false;
      final Map<String, dynamic> updates = {};

      if (currentBlogEntry['title'] != title) {
        updates['title'] = title;
        updateFolderTitle(parentPath, folderId, title);
        shouldUpdate = true;
      }
      if (currentBlogEntry['markdown'] != markdown) {
        updates['markdown'] = markdown;
        shouldUpdate = true;
      }
      if (currentBlogEntry['tags'] != tags) {
        updates['tags'] = tags;
        final tagsList =
            tags.split('/').where((tag) => tag.isNotEmpty).toList();
        await createTagPath(tagsList, id, title);
        await updateFolderTags(parentPath, folderId, tagsList);
        await deleteFolderIfEmpty(parentPath, folderId);
        shouldUpdate = true;
      }

      if (shouldUpdate) {
        updates['updated_at'] = FieldValue.serverTimestamp();
        await _firestore.collection('blogs').doc(id).update(updates);
      }

      notifyListeners();
    }
  }

  Stream<List<Map<String, dynamic>>> getBlogStream() {
    return _firestore
        .collection('blogs')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return {
                'id': doc.id,
                ...doc.data(),
              };
            }).toList());
  }

  Future<void> createTagPath(
      List<String> tags, String blogId, String title) async {
    CollectionReference currentRef = _firestore.collection('blogFolders');

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
        currentRef = folderDoc.collection('subfolders');
      }
    }

    final finalDocRef = currentRef.doc();
    await finalDocRef.set({
      'title': title,
      'blogId': blogId,
      'tags': tags,
      'type': 'card',
      'hasSubfolders': false,
    });
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

  Future<void> deleteFolderIfEmpty(String parentPath, String folderId) async {
    try {
      final folderDocRef = _firestore.collection(parentPath).doc(folderId);

      final subcollections = await folderDocRef.collection('subfolders').get();
      if (subcollections.docs.isNotEmpty) {
        return;
      }

      final folderSnapshot = await folderDocRef.get();
      if (!folderSnapshot.exists) {
        return;
      }

      await folderDocRef.delete();

      final parentSegments = parentPath.split('/');
      if (parentSegments.length > 2) {
        parentSegments.removeLast();
        final parentFolderId = parentSegments.removeLast();
        final newParentPath = parentSegments.join('/');
        await deleteFolderIfEmpty(newParentPath, parentFolderId);
      }
    } catch (e) {
      print("Error deleting folder: $e");
    }
  }
}
