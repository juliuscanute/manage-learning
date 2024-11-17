import 'package:equatable/equatable.dart';

abstract class AppState extends Equatable {
  const AppState();

  @override
  List<Object> get props => [];
}

class AppInitial extends AppState {}

class AppLoading extends AppState {}

class CategoriesLoaded extends AppState {
  final List<Map<String, dynamic>> categories;

  const CategoriesLoaded(this.categories);

  @override
  List<Object> get props => [categories];
}

class DeckDuplicated extends AppState {}

class DeckDeleted extends AppState {}

class AppError extends AppState {
  final String message;

  const AppError(this.message);

  @override
  List<Object> get props => [message];
}
