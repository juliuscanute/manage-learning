import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_learning/data/firebase_service.dart';
import 'package:path/path.dart';
import 'deck_event.dart';
import 'deck_state.dart';

class DeckBloc extends Bloc<DeckEvent, DeckState> {
  final FirebaseService _firebaseService;
  final String deckId;

  DeckBloc(this._firebaseService, this.deckId)
      : super(
          DeckState(
            isLoading: true,
            deckTitleController: TextEditingController(),
            videoUrlController: TextEditingController(),
            tagsController: TextEditingController(),
            mindmapImageController: const {'image': null, 'imageUrl': ''},
            cardControllers: [],
            isEvaluatorStrict: true,
            isPublic: false,
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
  }

  Future<void> _onLoadDeckData(
      LoadDeckData event, Emitter<DeckState> emit) async {
    try {
      emit(state.copyWith(isLoading: true));
      var deckData = await _firebaseService.getDeckData(event.deckId);

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
                  'back': TextEditingController(text: cardData['back']),
                  'position': cardData['position'],
                  'imageUrl': cardData['imageUrl'] ?? '',
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
    state.cardControllers.add({
      'front': TextEditingController(),
      'back': TextEditingController(),
      'position': state.cardControllers.length,
    });
    emit(state.copyWith(cardControllers: List.from(state.cardControllers)));
  }

  Future<void> _onSaveDeckAndCards(
      SaveDeckAndCards event, Emitter<DeckState> emit) async {
    try {
      emit(state.copyWith(isLoading: true));
      await _uploadImage(state.mindmapImageController, 'mindmap_images');
      for (var controller in state.cardControllers) {
        await _uploadImage(controller, 'card_images');
      }

      List<String> tags = state.tagsController.text
          .split('/')
          .where((tag) => tag.isNotEmpty)
          .toList();

      await _firebaseService.updateDeck(
        deckId,
        state.deckTitleController.text,
        state.videoUrlController.text,
        state.mindmapImageController['imageUrl'],
        state.isEvaluatorStrict,
        state.cardControllers
            .map((e) => {
                  'id': e['id'],
                  'front': e['front'].text,
                  'back': e['back'].text,
                  'imageUrl': e['imageUrl'],
                  'position': e['position'],
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
            'back': TextEditingController(),
            'position': event.index,
            'image': null,
            'imageName': '',
            'imageUrl': '',
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
            'back': TextEditingController(),
            'position': event.index + 1,
            'image': null,
            'imageName': '',
            'imageUrl': '',
          });

    for (int i = 0; i < updatedControllers.length; i++) {
      updatedControllers[i]['position'] = i;
    }

    emit(state.copyWith(cardControllers: updatedControllers));
  }
}
