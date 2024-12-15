import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_learning/ui/blog_repository.dart';
import 'package:manage_learning/ui/blogs/blog_category_event.dart';
import 'package:manage_learning/ui/blogs/blog_category_state.dart';

class BlogCategoryBloc extends Bloc<BlogCategoryEvent, BlogCategoryState> {
  final BlogRepository _blogRepository;

  BlogCategoryBloc(this._blogRepository) : super(BlogCategoriesLoading()) {
    on<BlogFetchCategoriesEvent>(_onFetchCategories);
    on<BlogFetchBlogsEvent>(_onFetchSubFolders);
    on<BlogDeletePostEvent>(_onDeleteBlogPost);
  }

  Future<void> _onFetchCategories(
      BlogFetchCategoriesEvent event, Emitter<BlogCategoryState> emit) async {
    emit(BlogCategoriesLoading());
    try {
      final categories = await _blogRepository.getFolders();
      emit(BlogCategoriesLoaded(categories));
    } catch (e) {
      emit(BlogCategoriesError(e.toString()));
    }
  }

  Future<void> _onFetchSubFolders(
      BlogFetchBlogsEvent event, Emitter<BlogCategoryState> emit) async {
    emit(BlogCategoriesLoading());
    try {
      final subFolders = await _blogRepository.getSubFolders(event.parentPath);
      emit(BlogCategoriesLoaded(subFolders));
    } catch (e) {
      emit(BlogCategoriesError(e.toString()));
    }
  }

  Future<void> _onDeleteBlogPost(
      BlogDeletePostEvent event, Emitter<BlogCategoryState> emit) async {
    emit(BlogCategoriesLoading());
    try {
      await _blogRepository.deleteBlogPost(
          event.blogId, event.parentPath, event.folderId);
      final categories = await _blogRepository.getSubFolders(event.parentPath);
      emit(BlogCategoriesLoaded(categories));
    } catch (e) {
      emit(BlogCategoriesError(e.toString()));
    }
  }
}
