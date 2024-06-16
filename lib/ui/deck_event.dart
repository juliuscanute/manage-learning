import 'package:equatable/equatable.dart';

abstract class DeckEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadDeckData extends DeckEvent {
  final String? deckId;

  LoadDeckData(this.deckId);

  @override
  List<Object?> get props => [deckId];
}

class MoveCard extends DeckEvent {
  final int oldIndex;
  final int newIndex;

  MoveCard(this.oldIndex, this.newIndex);

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

class AddCardController extends DeckEvent {}

class SaveDeckAndCards extends DeckEvent {}

class UpdateEvaluatorStrictness extends DeckEvent {
  final bool isStrict;

  UpdateEvaluatorStrictness(this.isStrict);

  @override
  List<Object?> get props => [isStrict];
}

class UpdatePublicStatus extends DeckEvent {
  final bool isPublic;

  UpdatePublicStatus(this.isPublic);

  @override
  List<Object?> get props => [isPublic];
}

class DeleteImage extends DeckEvent {
  final Map<String, dynamic> controller;

  DeleteImage(this.controller);

  @override
  List<Object?> get props => [controller];
}

class UpdateCardControllers extends DeckEvent {
  final List<Map<String, dynamic>> cardControllers;

  UpdateCardControllers(this.cardControllers);

  @override
  List<Object?> get props => [cardControllers];
}

class UpdateImage extends DeckEvent {
  final Map<String, dynamic> controller;
  final dynamic image;
  final String imageName;
  final bool isMindmap;

  UpdateImage(this.controller, this.image, this.imageName, this.isMindmap);

  @override
  List<Object?> get props => [controller, image, imageName, isMindmap];
}

class AddCardAbove extends DeckEvent {
  final int index;

  AddCardAbove(this.index);

  @override
  List<Object?> get props => [index];
}

class AddCardBelow extends DeckEvent {
  final int index;

  AddCardBelow(this.index);

  @override
  List<Object?> get props => [index];
}

class UpdateJsonDeck extends DeckEvent {
  final String jsonDeck;

  UpdateJsonDeck(this.jsonDeck);

  @override
  List<Object?> get props => [jsonDeck];
}
