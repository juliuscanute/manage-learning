import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:manage_learning/ui/blog_events.dart';
import 'package:manage_learning/ui/blog_repository.dart';
import 'package:manage_learning/ui/blogs_bloc.dart';
import 'package:provider/provider.dart';

class BlogCreateEdit extends StatefulWidget {
  final BlogData? blogData;

  BlogCreateEdit({this.blogData});

  @override
  _BlogCreateEditState createState() => _BlogCreateEditState();
}

class BlogData {
  final String? blogId;
  final String? parentPath;
  final String? folderId;

  BlogData({this.blogId, this.parentPath, this.folderId});
}

class _BlogCreateEditState extends State<BlogCreateEdit> {
  final TextEditingController _markdownController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  late BlogBloc _blogBloc;
  String? initialMarkdown;

  @override
  void initState() {
    super.initState();
    final blogRepository = Provider.of<BlogRepository>(context, listen: false);
    _blogBloc =
        BlogBloc(repository: blogRepository, imageService: ImageService());
    final blogData = widget.blogData;
    if (widget.blogData != null) {
      if (blogData?.blogId != null) {
        _blogBloc.add(FetchBlogByIdEvent(blogData!.blogId!));
      }
    }
  }

  @override
  void dispose() {
    _blogBloc.close();
    _markdownController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _blogBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Blog Editor'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BlocListener<BlogBloc, BlogState>(
            listener: (context, state) {
              if (state is BlogImageUpdated) {
                _markdownController.text +=
                    ' ![Illustration](${state.imageUrl})';
                _blogBloc.add(UpdateMarkdownEvent(_markdownController.text));
              } else if (state is BlogError) {
                _showErrorSnackbar(context, state.error);
              }
              if (state is BlogCreated || state is BlogUpdated) {
                Navigator.of(context).pop();
              }
              if (state is BlogFetched) {
                final blog = state.blog;
                _titleController.text = blog['title'];
                _tagsController.text = blog['tags'];
                _markdownController.text = blog['markdown'];
                initialMarkdown = blog['markdown'];
              }
            },
            child: BlocBuilder<BlogBloc, BlogState>(
              builder: (context, state) {
                return Stack(
                  children: [
                    Column(
                      children: [
                        _buildTitleField(),
                        const SizedBox(height: 16),
                        _buildTagsField(),
                        const SizedBox(height: 16),
                        _buildAddImageButton(),
                        const SizedBox(height: 16),
                        _buildMarkdownEditor(),
                        const SizedBox(height: 16),
                        _buildSaveButton(),
                      ],
                    ),
                    if (state is BlogLoading)
                      const Center(child: CircularProgressIndicator()),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Separate method to build the title input field
  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      decoration: const InputDecoration(
        hintText: 'Enter title',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildTagsField() {
    return TextField(
      controller: _tagsController,
      decoration: const InputDecoration(
        labelText: 'New Tag',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
        onPressed: () {
          if (widget.blogData?.blogId == null) {
            _blogBloc.add(CreateBlogEvent(_markdownController.text,
                _titleController.text, _tagsController.text));
          } else {
            _blogBloc.add(UpdateBlogEvent(
                widget.blogData!.blogId!,
                initialMarkdown ?? '',
                _markdownController.text,
                _titleController.text,
                _tagsController.text,
                widget.blogData!.parentPath!,
                widget.blogData!.folderId!));
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(
            widget.blogData?.blogId == null ? 'Create Blog' : 'Update Blog'));
  }

  // Separate method to build the add image button
  Widget _buildAddImageButton() {
    return ElevatedButton(
      onPressed: () => _blogBloc.add(PickImageEvent()),
      child: const Text('Add Image'),
    );
  }

  // Separate method to build the markdown editor and preview
  Widget _buildMarkdownEditor() {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Determine if the screen is large or small
          bool isLargeScreen =
              constraints.maxWidth > 600; // Adjust the breakpoint as needed

          // Define the common widgets
          final textField = Expanded(
            child: TextField(
              controller: _markdownController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: 'Write your blog here...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _blogBloc.add(UpdateMarkdownEvent(value)),
            ),
          );

          final markdownPreview = Expanded(
            child: Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.grey[200],
              child: BlocBuilder<BlogBloc, BlogState>(
                builder: (context, state) {
                  final markdownContent = state is MarkdownUpdated
                      ? state.markdown
                      : _markdownController.text;
                  return Markdown(
                    data: markdownContent,
                    selectable: true,
                    imageBuilder: (uri, title, alt) {
                      String modifiedUri = uri
                          .toString()
                          .replaceFirst('blog_images/', 'blog_images%2F');
                      return Image.network(
                        modifiedUri,
                        loadingBuilder: (BuildContext context, Widget child,
                            ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          } else {
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        (loadingProgress.expectedTotalBytes ??
                                            1)
                                    : null,
                              ),
                            );
                          }
                        },
                        errorBuilder: (BuildContext context, Object error,
                            StackTrace? stackTrace) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, color: Colors.red),
                                SizedBox(height: 8),
                                Text('Failed to load image',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          );

          return isLargeScreen
              ? Row(
                  children: [
                    textField,
                    const SizedBox(width: 16),
                    markdownPreview,
                  ],
                )
              : Column(
                  children: [
                    textField,
                    const SizedBox(height: 16),
                    markdownPreview,
                  ],
                );
        },
      ),
    );
  }

  // Separate method to show error snackbar
  void _showErrorSnackbar(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  }
}
