import 'package:equatable/equatable.dart';

abstract class AppEvent extends Equatable {
  const AppEvent();

  @override
  List<Object> get props => [];
}

class LoadCategories extends AppEvent {
  final String parentPath;

  const LoadCategories(this.parentPath);

  @override
  List<Object> get props => [parentPath];
}

class RefreshCategories extends AppEvent {
  final String parentPath;

  const RefreshCategories(this.parentPath);

  @override
  List<Object> get props => [parentPath];
}

class DuplicateCategory extends AppEvent {
  final String parentPath;
  final String folderId;

  const DuplicateCategory(this.parentPath, this.folderId);

  @override
  List<Object> get props => [parentPath, folderId];
}

class DuplicateDeck extends AppEvent {
  final Map<String, dynamic> deck;
  final String parentPath;

  const DuplicateDeck(this.deck, this.parentPath);

  @override
  List<Object> get props => [deck];
}

class DeleteDeck extends AppEvent {
  final String deckId;
  final String parentPath;
  final String folderId;

  const DeleteDeck(this.deckId, this.parentPath, this.folderId);

  @override
  List<Object> get props => [deckId, parentPath, folderId];
}
