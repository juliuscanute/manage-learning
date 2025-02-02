import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AccountRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _apiBaseUrl;
  AccountRepository({required String apiBaseUrl}) : _apiBaseUrl = apiBaseUrl;

  Future<void> createTeacherAccount(String email, String password) async {
    // Get current user credentials
    final currentUser = await _auth.currentUser;
    final idToken = await currentUser?.getIdToken();

    if (idToken != null) {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/claims'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'claim': {'teacher': true}
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final uid = responseData['uid'];

        await _firestore.collection('users').doc(uid).set({
          'email': email,
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
          'isTeacher': true,
          'isActive': true,
        });
      } else {
        throw Exception(
            'Failed to create user and set claims: ${response.body}');
      }
    } else {
      throw Exception('Failed to get ID token for current user.');
    }
  }

  Future<List<Map<String, dynamic>>> loadUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) {
      return {
        'email': doc['email'],
        'uid': doc['uid'],
        'isTeacher': doc['isTeacher'],
        'isActive': doc['isActive'],
      };
    }).toList();
  }

  Future<void> deleteTeacherAccount(String uid) async {
    try {
      // Get the ID token of the current (admin) user
      final currentUser = _auth.currentUser;
      final idToken = await currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception("No valid ID token found.");
      }

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/deleteUser'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'uid': uid,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete user account: ${response.body}');
      }

      // Delete the corresponding Firestore document.
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete teacher account: $e');
    }
  }

  Future<void> resetUserPassword(String uid, String newPassword) async {
    try {
      // Get the ID token of the current (admin) user
      final currentUser = _auth.currentUser;
      final idToken = await currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception("No valid ID token found.");
      }

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/resetUser'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'uid': uid,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to reset user password: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to reset user password: $e');
    }
  }
}
