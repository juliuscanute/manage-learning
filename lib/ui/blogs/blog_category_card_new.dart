import 'package:flutter/material.dart';
import 'package:manage_learning/ui/blog_repository.dart';
import 'package:provider/provider.dart';

class BlogCategoryCardNew extends StatefulWidget {
  final String parentPath;
  final List<Map<String, dynamic>> subFolders;
  final String folderId;
  final String category;
  final bool isPublic;

  BlogCategoryCardNew({
    required this.parentPath,
    required this.subFolders,
    required this.folderId,
    required this.category,
    required this.isPublic,
  });

  @override
  _BlogCategoryCardNewState createState() => _BlogCategoryCardNewState();
}

class _BlogCategoryCardNewState extends State<BlogCategoryCardNew> {
  late BlogRepository _blogRepository;
  bool isPublic = true;

  @override
  void initState() {
    super.initState();
    _blogRepository = Provider.of<BlogRepository>(context, listen: false);
    isPublic = widget.isPublic;
  }

  Future<void> _fetchSubFolders() async {
    final nextPath = '${widget.parentPath}/subfolders';
    final subFolders = await _blogRepository.getSubFolders(nextPath);
    Navigator.pushNamed(
      context,
      "/blog-category-screen-new",
      arguments: {
        'parentPath': nextPath,
        'subFolders': subFolders,
        'folderId': widget.folderId,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(widget.category, style: const TextStyle(fontSize: 18.0)),
        trailing: Switch(
          value: isPublic,
          onChanged: (bool value) {
            setState(() {
              isPublic = value;
            });
            _blogRepository.addIsPublicFlag(widget.parentPath, isPublic);
          },
        ),
        onTap: () async {
          _fetchSubFolders();
        },
      ),
    );
  }
}
