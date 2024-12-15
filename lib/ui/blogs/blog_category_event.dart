abstract class BlogCategoryEvent {}

class BlogFetchCategoriesEvent extends BlogCategoryEvent {}

class BlogFetchBlogsEvent extends BlogCategoryEvent {
  final String parentPath;
  final String folderId;

  BlogFetchBlogsEvent(this.parentPath, this.folderId);
}

class BlogDeletePostEvent extends BlogCategoryEvent {
  final String blogId;
  final String parentPath;
  final String folderId;

  BlogDeletePostEvent(this.blogId, this.parentPath, this.folderId);
}
