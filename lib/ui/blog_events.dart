// Event definition
abstract class BlogEvent {}

class UpdateMarkdownEvent extends BlogEvent {
  final String markdown;
  UpdateMarkdownEvent(this.markdown);
}

class PickImageEvent extends BlogEvent {}

class RemoveImageEvent extends BlogEvent {}

class CreateBlogEvent extends BlogEvent {
  final String markdown;
  final String title;
  final String tags;
  CreateBlogEvent(this.markdown, this.title, this.tags);
}

class UpdateBlogEvent extends BlogEvent {
  final String blogId;
  final String initialMarkdown;
  final String markdown;
  final String title;
  final String tags;
  UpdateBlogEvent(
      this.blogId, this.initialMarkdown, this.markdown, this.title, this.tags);
}

// State definition
abstract class BlogState {}

class BlogInitial extends BlogState {}

class MarkdownUpdated extends BlogState {
  final String markdown;
  MarkdownUpdated(this.markdown);
}

class BlogLoading extends BlogState {}

class BlogCreated extends BlogState {}

class BlogUpdated extends BlogState {}

class BlogImageUpdated extends BlogState {
  final String? imageUrl;
  BlogImageUpdated(this.imageUrl);
}

class BlogFetched extends BlogState {
  final Map<String, dynamic> blog;
  BlogFetched(this.blog);
}

class BlogError extends BlogState {
  final String error;
  BlogError(this.error);
}

class FetchBlogByIdEvent extends BlogEvent {
  final String blogId;
  FetchBlogByIdEvent(this.blogId);
}
