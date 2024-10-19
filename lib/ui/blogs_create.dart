import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:manage_learning/ui/blog_events.dart';
import 'package:manage_learning/ui/blog_repository.dart';
import 'package:manage_learning/ui/blogs_bloc.dart';

class BlogCreateEdit extends StatefulWidget {
  final BlogData? blogData;

  BlogCreateEdit({this.blogData});

  @override
  _BlogCreateEditState createState() => _BlogCreateEditState();
}

class BlogData {
  final String? blogId;
  final String? initialTitle;
  final String? initialContent;

  BlogData({this.blogId, this.initialTitle, this.initialContent});
}

class _BlogCreateEditState extends State<BlogCreateEdit> {
  final TextEditingController _markdownController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  late BlogBloc _blogBloc;

  @override
  void initState() {
    super.initState();
    _blogBloc =
        BlogBloc(repository: BlogRepository(), imageService: ImageService());
    if (widget.blogData?.initialTitle != null) {
      _titleController.text = widget.blogData!.initialTitle!;
    }
    if (widget.blogData?.initialContent != null) {
      _markdownController.text = widget.blogData!.initialContent!;
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
          child: Column(
            children: [
              _buildTitleField(),
              const SizedBox(height: 16),
              _buildAddImageButton(),
              const SizedBox(height: 16),
              BlocListener<BlogBloc, BlogState>(
                listener: (context, state) {
                  if (state is BlogImageUpdated) {
                    _markdownController.text +=
                        ' ![Illustration](${state.imageUrl})';
                    _blogBloc
                        .add(UpdateMarkdownEvent(_markdownController.text));
                  } else if (state is BlogError) {
                    _showErrorSnackbar(context, state.error);
                  }
                  if (state is BlogCreated || state is BlogUpdated) {
                    Navigator.of(context).pop();
                  }
                },
                child: _buildMarkdownEditor(),
              ),
              const SizedBox(height: 16),
              _buildSaveButton(),
            ],
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

  Widget _buildSaveButton() {
    return ElevatedButton(
        onPressed: () {
          if (widget.blogData?.blogId == null) {
            _blogBloc.add(CreateBlogEvent(
                _markdownController.text, _titleController.text));
          } else {
            _blogBloc.add(UpdateBlogEvent(
                widget.blogData!.blogId!,
                widget.blogData!.initialContent!,
                _markdownController.text,
                _titleController.text));
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
                          return Center(
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
