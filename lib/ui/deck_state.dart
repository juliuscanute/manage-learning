import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class DeckState extends Equatable {
  final bool isLoading;
  final TextEditingController deckTitleController;
  final TextEditingController videoUrlController;
  final TextEditingController tagsController;
  final Map<String, dynamic> mindmapImageController;
  final List<Map<String, dynamic>> cardControllers;
  final bool isEvaluatorStrict;
  final bool isPublic;
  final bool finishSave;

  DeckState({
    required this.isLoading,
    required this.deckTitleController,
    required this.videoUrlController,
    required this.tagsController,
    required this.mindmapImageController,
    required this.cardControllers,
    required this.isEvaluatorStrict,
    required this.isPublic,
    required this.finishSave,
  });

  DeckState copyWith({
    bool? isLoading,
    TextEditingController? deckTitleController,
    TextEditingController? videoUrlController,
    TextEditingController? tagsController,
    Map<String, dynamic>? mindmapImageController,
    List<Map<String, dynamic>>? cardControllers,
    bool? isEvaluatorStrict,
    bool? isPublic,
    bool? finishSave,
  }) {
    return DeckState(
      isLoading: isLoading ?? this.isLoading,
      deckTitleController: deckTitleController ?? this.deckTitleController,
      videoUrlController: videoUrlController ?? this.videoUrlController,
      tagsController: tagsController ?? this.tagsController,
      mindmapImageController:
          mindmapImageController ?? this.mindmapImageController,
      cardControllers: cardControllers ?? this.cardControllers,
      isEvaluatorStrict: isEvaluatorStrict ?? this.isEvaluatorStrict,
      isPublic: isPublic ?? this.isPublic,
      finishSave: finishSave ?? this.finishSave,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        deckTitleController,
        videoUrlController,
        tagsController,
        mindmapImageController,
        cardControllers,
        isEvaluatorStrict,
        isPublic,
      ];
}
