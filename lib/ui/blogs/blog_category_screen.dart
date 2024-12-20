import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_learning/ui/blog_repository.dart';
import 'package:manage_learning/ui/blogs/blog_category_card_new.dart';
import 'package:manage_learning/ui/blogs/blog_list_item_new.dart';
import 'package:manage_learning/ui/blogs/blog_category_bloc.dart';
import 'package:manage_learning/ui/blogs/blog_category_event.dart';
import 'package:manage_learning/ui/blogs/blog_category_state.dart';
import 'package:provider/provider.dart';

class BlogCategoryScreen extends StatefulWidget {
  const BlogCategoryScreen();

  @override
  _BlogCategoryScreenState createState() => _BlogCategoryScreenState();
}

class _BlogCategoryScreenState extends State<BlogCategoryScreen> {
  late BlogCategoryBloc _categoryBloc;
  List<Map<String, dynamic>> folders = [];

  @override
  void initState() {
    super.initState();
    final BlogRepository blogRepository =
        Provider.of<BlogRepository>(context, listen: false);
    _categoryBloc = BlogCategoryBloc(blogRepository);
    _categoryBloc.add(BlogFetchCategoriesEvent());
    blogRepository.changeStream.listen((event) {
      _categoryBloc.add(BlogFetchCategoriesEvent());
    });
  }

  @override
  void dispose() {
    _categoryBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _categoryBloc,
      child: Scaffold(
        body: BlocBuilder<BlogCategoryBloc, BlogCategoryState>(
          builder: (context, state) {
            if (state is BlogCategoriesLoaded) {
              folders = state.categories;
            }

            return Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate the number of columns based on screen width
                    int crossAxisCount = constraints.maxWidth > 600
                        ? 2
                        : 1; // Example breakpoint at 600px

                    // Calculate the width of each child based on the number of columns
                    double width =
                        (constraints.maxWidth - (crossAxisCount - 1) * 10) /
                            crossAxisCount;

                    return SingleChildScrollView(
                      child: Wrap(
                        spacing: 10, // Horizontal space between items
                        runSpacing: 10, // Vertical space between items
                        children: List.generate(folders.length, (index) {
                          final folder = folders[index];
                          if (folder['type'] != 'card') {
                            return SizedBox(
                              width: width,
                              child: BlogCategoryCardNew(
                                category: folder['id'],
                                parentPath: 'blogFolders/${folder['id']}',
                                subFolders: folder['subFolders'] ?? [],
                                folderId: folder['id'],
                                isPublic: folder['isPublic'] ?? true,
                              ),
                            );
                          } else {
                            final leafNode = {
                              'title': folder['title'] ?? 'Untitled',
                              'blogId': folder['blogId'],
                              'type': 'card',
                              'parentPath': 'blogFolders/${folder['id']}',
                            };
                            return SizedBox(
                              width: width,
                              child: BlogListItemNew(
                                blog: leafNode,
                                categoryBloc: _categoryBloc,
                              ),
                            );
                          }
                        }),
                      ),
                    );
                  },
                ),
                if (state is BlogCategoriesLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            );
          },
        ),
      ),
    );
  }
}
