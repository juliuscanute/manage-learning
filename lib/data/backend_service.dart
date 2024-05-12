import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class BackendService {
  final _firebaseAuth = FirebaseAuth.instance;

  Future<FlashcardResponse> analyzeFile(PlatformFile file) async {
    // Send the POST request using http.post
    try {
      // Get the Firebase user
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('User is not logged in');
      }

      // Get the user's ID token
      final idToken = await user.getIdToken();

      // Read the PDF file as bytes, then convert to Base64 string
      final pdfBytes = file.bytes!;
      final pdfBase64 = base64Encode(pdfBytes);

      // Define your API endpoint
      final apiEndpoint = Uri.parse(
          'https://gob6ag7fp2.execute-api.ap-southeast-2.amazonaws.com/prod/deck');

      // Define headers for the request
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      };

      // Create a JSON payload with the Base64-encoded PDF data
      final body = jsonEncode({
        'body': pdfBase64,
      });
      final response =
          await http.post(apiEndpoint, headers: headers, body: body);

      // Return the response from the API
      final responseJson = jsonDecode(response.body);

      return FlashcardResponse.fromJson(responseJson);
    } catch (e) {
      throw Exception('Error occurred: $e');
    }
  }
}

class Flashcard {
  final String front;
  final String back;

  Flashcard({required this.front, required this.back});

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      front: json['front'] as String,
      back: json['back'] as String,
    );
  }
}

class FlashcardResponse {
  final String title;
  final List<Flashcard> flashcards;

  FlashcardResponse({required this.title, required this.flashcards});

  factory FlashcardResponse.fromJson(Map<String, dynamic> json) {
    var flashcardsJson = json['flashcards'] as List;
    List<Flashcard> flashcardsList =
        flashcardsJson.map((i) => Flashcard.fromJson(i)).toList();

    return FlashcardResponse(
      title: json['title'] as String,
      flashcards: flashcardsList,
    );
  }
}
