import 'package:flutter/material.dart';
import 'package:manage_learning/ui/blogs/blog_category_bloc.dart';
import 'package:manage_learning/ui/blogs/blog_category_event.dart';
import 'package:manage_learning/ui/blogs_create.dart';

class BlogListItemNew extends StatelessWidget {
  final Map<String, dynamic> blog;
  final BlogCategoryBloc categoryBloc;

  BlogListItemNew({required this.blog, required this.categoryBloc});

  @override
  Widget build(BuildContext context) {
    final String markdown = blog['markdown'] ?? '';

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(blog['title'] ?? 'Untitled',
            style: const TextStyle(fontSize: 18.0)),
        subtitle: Text(
          markdown,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // Logic to edit the blog post
                Navigator.of(context).pushNamed(
                  '/blog-updates',
                  arguments: BlogData(
                    blogId: blog['blogId'],
                    parentPath: blog['parentPath'],
                    folderId: blog['folderId'],
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                categoryBloc.add(BlogDeletePostEvent(
                    blog['blogId'], blog['parentPath'], blog['folderId']));
              },
            ),
          ],
        ),
      ),
    );
  }
}
