import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_learning/data/firebase_service.dart';
import 'package:manage_learning/ui/cards_page_view.dart';
import 'package:manage_learning/ui/mcq_controller.dart';
import 'package:path/path.dart';
import 'deck_event.dart';
import 'deck_state.dart';

class DeckBloc extends Bloc<DeckEvent, DeckState> {
  final FirebaseService _firebaseService;
  final String? deckId;
  final DeckOperation operation;

  DeckBloc(this._firebaseService, this.deckId, this.operation)
      : super(
          DeckState(
            isLoading: true,
            deckTitleController: TextEditingController(),
            videoUrlController: TextEditingController(),
            tagsController: TextEditingController(),
            jsonController: TextEditingController(),
            mindmapImageController: const {'image': null, 'imageUrl': ''},
            cardControllers: [
              {
                'front': TextEditingController(),
                'frontTex': TextEditingController(),
                'back': TextEditingController(),
                'backTex': TextEditingController(),
                'position': 0,
                'image': null,
                'imageName': '',
                'imageUrl': '',
                'mcq': MCQController.initialize(),
                'explanation': TextEditingController(),
                'explanationTex': TextEditingController(),
                'mnemonic': TextEditingController(),
              }
            ],
            isEvaluatorStrict: true,
            isPublic: true,
            finishSave: false,
          ),
        ) {
    on<LoadDeckData>(_onLoadDeckData);
    on<MoveCard>(_onMoveCard);
    on<AddCardController>(_onAddCardController);
    on<SaveDeckAndCards>(_onSaveDeckAndCards);
    on<UpdateEvaluatorStrictness>(_onUpdateEvaluatorStrictness);
    on<UpdatePublicStatus>(_onUpdatePublicStatus);
    on<DeleteImage>(_onDeleteImage);
    on<UpdateCardControllers>(_onUpdateCardControllers);
    on<UpdateImage>(_onUpdateImage);
    on<AddCardAbove>(_onAddCardAbove);
    on<AddCardBelow>(_onAddCardBelow);
    on<UpdateJsonDeck>(_onUpdateJsonDeck);
    on<UpdateMetaData>(_applyMetaData);
  }

  Future<void> _onLoadDeckData(
      LoadDeckData event, Emitter<DeckState> emit) async {
    final deckId = event.deckId;
    if (deckId == null) {
      emit(state.copyWith(isLoading: false));
      return;
    }
    try {
      emit(state.copyWith(isLoading: true));
      var deckData = await _firebaseService.getDeckData(deckId);

      // Create a modifiable copy of `mindmapImageController` if it's unmodifiable.
      var mindmapImageController =
          Map<String, dynamic>.from(state.mindmapImageController);
      mindmapImageController['imageUrl'] = deckData['mapUrl'] ?? '';

      state.deckTitleController.text = deckData['title'];
      state.videoUrlController.text = deckData['videoUrl'] ?? '';
      List<String> tags = List.from(deckData['tags'] ?? []);
      state.tagsController.text = tags.join('/');

      var fetchedCards = deckData['cards'] as List<Map<String, dynamic>>;
      emit(state.copyWith(
        mindmapImageController:
            mindmapImageController, // Update with the modifiable copy.
        cardControllers: fetchedCards
            .map((cardData) => {
                  'id': cardData['id'],
                  'front': TextEditingController(text: cardData['front']),
                  'frontTex':
                      TextEditingController(text: cardData['front_tex']),
                  'back': TextEditingController(text: cardData['back']),
                  'backTex': TextEditingController(text: cardData['back_tex']),
                  'position': cardData['position'],
                  'imageUrl': cardData['imageUrl'] ?? '',
                  'mcq': MCQController.fromMap(cardData['mcq'] ?? {}),
                  'explanation': TextEditingController(
                      text: cardData['explanation'] ?? ''),
                  'explanationTex': TextEditingController(
                      text: cardData['explanation_tex'] ?? ''),
                  'mnemonic':
                      TextEditingController(text: cardData['mnemonic'] ?? ''),
                })
            .toList()
          ..sort(
              (a, b) => (a['position'] as int).compareTo(b['position'] as int)),
        isEvaluatorStrict: deckData['exactMatch'] ?? true,
        isPublic: deckData['isPublic'] ?? false,
        isLoading: false,
      ));
    } catch (e) {
      print("Error loading deck data: $e");
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  void _onMoveCard(MoveCard event, Emitter<DeckState> emit) {
    final List<Map<String, dynamic>> updatedControllers =
        List.from(state.cardControllers);
    final item = updatedControllers.removeAt(event.oldIndex);
    updatedControllers.insert(event.newIndex, item);

    for (int i = 0; i < updatedControllers.length; i++) {
      updatedControllers[i]['position'] = i;
    }

    emit(state.copyWith(cardControllers: updatedControllers));
  }

  void _onAddCardController(AddCardController event, Emitter<DeckState> emit) {
    final updatedControllers =
        List<Map<String, dynamic>>.from(state.cardControllers)
          ..add({
            'front': TextEditingController(),
            'frontTex': TextEditingController(),
            'back': TextEditingController(),
            'backTex': TextEditingController(),
            'position': state.cardControllers.length,
            'image': null,
            'imageName': '',
            'imageUrl': '',
            'mcq': MCQController.initialize(),
            'explanation': TextEditingController(),
            'explanationTex': TextEditingController(),
            'mnemonic': TextEditingController(),
          });

    emit(state.copyWith(cardControllers: updatedControllers));
  }

  Future<void> _onSaveDeckAndCards(
      SaveDeckAndCards event, Emitter<DeckState> emit) async {
    if (operation == DeckOperation.edit) {
      await _updateDeck(event, emit);
    } else {
      await _createDeck(event, emit);
    }
  }

  Future<void> _createDeck(
      SaveDeckAndCards event, Emitter<DeckState> emit) async {
    try {
      emit(state.copyWith(isLoading: true));
      List<String> tags = state.tagsController.text
          .split('/')
          .where((tag) => tag.isNotEmpty)
          .toList();
      var deckId = await _firebaseService.createDeck(
          state.deckTitleController.text,
          tags,
          state.isEvaluatorStrict,
          state.isPublic);

      if (state.videoUrlController.text.isNotEmpty) {
        await _firebaseService.updateDeckWithVideoUrl(
            deckId, state.videoUrlController.text);
      }

      print("Processing mindmap");
      await _uploadImage(state.mindmapImageController, 'mindmap_images');
      final mapUrl = state.mindmapImageController['imageUrl'];
      if (mapUrl.isNotEmpty) {
        await _firebaseService.updateDeckWithMapUrl(deckId, mapUrl);
      }

      print('Processing card');

      for (var i = 0; i < state.cardControllers.length; i++) {
        var controllers = state.cardControllers[i];

        await _uploadImage(controllers, 'card_images');
        await _firebaseService.addCard(
          deckId,
          controllers['front']!.text,
          controllers['frontTex']!.text,
          controllers['back']!.text,
          controllers['backTex']!.text,
          controllers['imageUrl'],
          (controllers['mcq'] as MCQController).toMap(),
          controllers['explanation']!.text,
          controllers['explanationTex']!.text,
          controllers['mnemonic']!.text,
          i,
        );
        print('Card $i added');
      }
    } catch (e) {
      print("Error saving deck: $e");
    } finally {
      emit(state.copyWith(isLoading: false, finishSave: true));
    }
  }

  Future<void> _updateDeck(
      SaveDeckAndCards event, Emitter<DeckState> emit) async {
    try {
      emit(state.copyWith(isLoading: true));

      List<String> tags = state.tagsController.text
          .split('/')
          .where((tag) => tag.isNotEmpty)
          .toList();

      await _uploadImage(state.mindmapImageController, 'mindmap_images');
      for (var controller in state.cardControllers) {
        await _uploadImage(controller, 'card_images');
      }

      await _firebaseService.updateDeck(
        deckId!,
        state.deckTitleController.text,
        state.videoUrlController.text,
        state.mindmapImageController['imageUrl'],
        state.isEvaluatorStrict,
        state.cardControllers
            .map((e) => {
                  'id': e['id'],
                  'front': e['front'].text,
                  'front_tex': e['frontTex'].text,
                  'back': e['back'].text,
                  'back_tex': e['backTex'].text,
                  'imageUrl': e['imageUrl'],
                  'position': e['position'],
                  'mcq': (e['mcq'] as MCQController).toMap(),
                  'explanation': e['explanation'].text,
                  'explanation_tex': e['explanationTex'].text,
                  'mnemonic': e['mnemonic'].text,
                })
            .toList(),
        tags,
        state.isPublic,
      );
    } finally {
      emit(state.copyWith(isLoading: false, finishSave: true));
    }
  }

  Future<void> _uploadImage(
      Map<String, dynamic> controller, String pathPrefix) async {
    if (controller['image'] == null) return;
    try {
      String fileName = controller['imageName'];
      var image = controller['image'];

      await _firebaseService.deleteImage(controller['imageUrl']);

      if (kIsWeb) {
        Uint8List imageBytes = image as Uint8List;
        TaskSnapshot snapshot = await FirebaseStorage.instance
            .ref('$pathPrefix/$deckId/$fileName')
            .putData(imageBytes);
        String newImageUrl = await snapshot.ref.getDownloadURL();
        controller['imageUrl'] = newImageUrl;
      } else {
        File imageFile = File(image as String);
        TaskSnapshot snapshot = await FirebaseStorage.instance
            .ref('$pathPrefix/$deckId/${basename(imageFile.path)}')
            .putFile(imageFile);
        String newImageUrl = await snapshot.ref.getDownloadURL();
        controller['imageUrl'] = newImageUrl;
      }
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  void _onUpdateEvaluatorStrictness(
      UpdateEvaluatorStrictness event, Emitter<DeckState> emit) {
    emit(state.copyWith(isEvaluatorStrict: event.isStrict));
  }

  void _onUpdatePublicStatus(
      UpdatePublicStatus event, Emitter<DeckState> emit) {
    emit(state.copyWith(isPublic: event.isPublic));
  }

  Future<void> _onDeleteImage(
      DeleteImage event, Emitter<DeckState> emit) async {
    try {
      emit(state.copyWith(isLoading: true));
      if (event.controller['imageUrl'] != null &&
          event.controller['imageUrl'].isNotEmpty) {
        await _firebaseService.deleteImage(event.controller['imageUrl']);
        event.controller['imageUrl'] = '';
        emit(state.copyWith(cardControllers: List.from(state.cardControllers)));
      }
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  void _onUpdateImage(UpdateImage event, Emitter<DeckState> emit) {
    if (!event.isMindmap) {
      final updatedControllers = state.cardControllers.map((controller) {
        if (controller == event.controller) {
          return {
            ...controller,
            'image': event.image,
            'imageName': event.imageName,
          };
        }
        return controller;
      }).toList();

      emit(state.copyWith(cardControllers: updatedControllers));
    } else {
      emit(state.copyWith(
        mindmapImageController: {
          'image': event.image,
          'imageName': event.imageName,
        },
      ));
    }
  }

  void _onUpdateCardControllers(
      UpdateCardControllers event, Emitter<DeckState> emit) {
    emit(state.copyWith(cardControllers: event.cardControllers));
  }

  void _onAddCardAbove(AddCardAbove event, Emitter<DeckState> emit) {
    final List<Map<String, dynamic>> updatedControllers =
        List.from(state.cardControllers)
          ..insert(event.index, {
            'front': TextEditingController(),
            'frontTex': TextEditingController(),
            'back': TextEditingController(),
            'backTex': TextEditingController(),
            'position': event.index,
            'image': null,
            'imageName': '',
            'imageUrl': '',
            'mcq': MCQController.initialize(),
            'explanation': TextEditingController(),
            'explanationTex': TextEditingController(),
            'mnemonic': TextEditingController(),
          });

    for (int i = 0; i < updatedControllers.length; i++) {
      updatedControllers[i]['position'] = i;
    }

    emit(state.copyWith(cardControllers: updatedControllers));
  }

  void _onAddCardBelow(AddCardBelow event, Emitter<DeckState> emit) {
    final List<Map<String, dynamic>> updatedControllers =
        List.from(state.cardControllers)
          ..insert(event.index + 1, {
            'front': TextEditingController(),
            'frontTex': TextEditingController(),
            'back': TextEditingController(),
            'backTex': TextEditingController(),
            'position': event.index + 1,
            'image': null,
            'imageName': '',
            'imageUrl': '',
            'mcq': MCQController.initialize(),
            'explanation': TextEditingController(),
            'explanationTex': TextEditingController(),
            'mnemonic': TextEditingController(),
          });

    for (int i = 0; i < updatedControllers.length; i++) {
      updatedControllers[i]['position'] = i;
    }

    emit(state.copyWith(cardControllers: updatedControllers));
  }

  void _onUpdateJsonDeck(UpdateJsonDeck event, Emitter<DeckState> emit) {
    try {
      emit(state.copyWith(isLoading: true));
      final Map<String, dynamic> jsonData = jsonDecode(event.jsonDeck);
      final flashcards =
          jsonData['flashcards'] ?? []; // Provide a default empty list if null
      final updatedControllers = flashcards.map((flashcard) {
        return {
          'front': TextEditingController(text: flashcard['front']),
          'frontTex': TextEditingController(text: flashcard['front_tex']),
          'back': TextEditingController(text: flashcard['back']),
          'backTex': TextEditingController(text: flashcard['back_tex']),
          'image': null,
          'mcq': MCQController.fromMap(flashcard.containsKey('mcq')
              ? {
                  'options':
                      List<String>.from(flashcard['mcq']['options'] ?? []),
                  'options_tex':
                      List<String>.from(flashcard['mcq']['options_tex'] ?? []),
                  'answer_index': flashcard['mcq']['answer_index'],
                }
              : {}),
          'explanation': TextEditingController(text: flashcard['explanation']),
          'explanationTex':
              TextEditingController(text: flashcard['explanation_tex']),
          'mnemonic': TextEditingController(text: flashcard['mnemonic']),
        };
      }).toList();

      emit(state.copyWith(
        deckTitleController: TextEditingController(text: jsonData['title']),
        cardControllers: List<Map<String, dynamic>>.from(updatedControllers),
      ));
    } catch (e) {
      print("Error parsing JSON: $e");
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  void _applyMetaData(UpdateMetaData event, Emitter<DeckState> emit) {
    try {
      emit(state.copyWith(isLoading: true));
      final Map<String, dynamic> jsonData = jsonDecode(event.jsonMetaData);
      final metaData =
          jsonData['metaData'] ?? []; // Provide a default empty list if null

      final updatedControllers =
          state.cardControllers.asMap().entries.map((entry) {
        final index = entry.key;
        final controller = entry.value;
        final meta = metaData.length > index ? metaData[index] : null;
        if (meta != null) {
          controller['mnemonic'] =
              TextEditingController(text: meta['mnemonic']);
        }
        return controller;
      }).toList();

      emit(state.copyWith(
        cardControllers: List<Map<String, dynamic>>.from(updatedControllers),
      ));
    } catch (e) {
      print("Error parsing JSON: $e");
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }
}
