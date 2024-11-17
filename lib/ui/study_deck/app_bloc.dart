import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_learning/data/firebase_service.dart';
import 'app_event.dart';
import 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  final FirebaseService firebaseService;

  AppBloc(this.firebaseService) : super(AppInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<RefreshCategories>(_onRefreshCategories);
    on<DuplicateCategory>(_onDuplicateCategory);
    on<DuplicateDeck>(_onDuplicateDeck);
    on<DeleteDeck>(_onDeleteDeck);
  }

  Future<void> _onLoadCategories(
      LoadCategories event, Emitter<AppState> emit) async {
    emit(AppLoading());
    try {
      final categories = await firebaseService.getSubFolders(event.parentPath);
      emit(CategoriesLoaded(categories));
    } catch (e) {
      emit(AppError('Error loading categories'));
    }
  }

  Future<void> _onRefreshCategories(
      RefreshCategories event, Emitter<AppState> emit) async {
    emit(AppLoading());
    try {
      final categories = await firebaseService.getSubFolders(event.parentPath);
      emit(CategoriesLoaded(categories));
    } catch (e) {
      emit(AppError('Error refreshing categories'));
    }
  }

  Future<void> _onDuplicateCategory(
      DuplicateCategory event, Emitter<AppState> emit) async {
    emit(AppLoading());
    try {
      await firebaseService.duplicateCategory(event.parentPath, event.folderId);
      final categories = await firebaseService.getSubFolders(event.parentPath);
      emit(CategoriesLoaded(categories));
    } catch (e) {
      emit(AppError('Error duplicating category'));
    }
  }

  Future<void> _onDuplicateDeck(
      DuplicateDeck event, Emitter<AppState> emit) async {
    emit(AppLoading());
    try {
      await firebaseService.duplicateDeck(event.deck);
      emit(DeckDuplicated());
      add(RefreshCategories(event.parentPath));
    } catch (e) {
      emit(AppError('Error duplicating deck'));
    }
  }

  Future<void> _onDeleteDeck(DeleteDeck event, Emitter<AppState> emit) async {
    emit(AppLoading());
    try {
      await firebaseService.deleteDeck(
          event.deckId, event.parentPath, event.folderId);
      emit(DeckDeleted());
      add(RefreshCategories(event.parentPath));
    } catch (e) {
      emit(AppError('Error deleting deck'));
    }
  }
}
