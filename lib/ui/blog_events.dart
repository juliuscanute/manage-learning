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
  CreateBlogEvent(this.markdown, this.title);
}

class UpdateBlogEvent extends BlogEvent {
  final String blogId;
  final String initialMarkdown;
  final String markdown;
  final String title;
  UpdateBlogEvent(this.blogId, this.initialMarkdown, this.markdown, this.title);
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

class BlogError extends BlogState {
  final String error;
  BlogError(this.error);
}
