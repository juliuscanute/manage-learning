import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class BlogRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Future<void> deleteBlogPost(String id) async {
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
    }
  }

  Future<void> saveBlogPost(String title, String markdown) async {
    await _firestore.collection('blogs').add({
      'title': title,
      'markdown': markdown,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateBlogPost(String id, String title, String markdown) async {
    await _firestore.collection('blogs').doc(id).update({
      'title': title,
      'markdown': markdown,
      'updated_at': FieldValue.serverTimestamp(),
    });
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
}
