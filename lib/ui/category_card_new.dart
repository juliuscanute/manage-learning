import 'package:flutter/material.dart';
import 'package:manage_learning/data/firebase_service.dart';
import 'package:provider/provider.dart';

class CategoryCardNew extends StatefulWidget {
  final String parentPath;
  final List<Map<String, dynamic>> subFolders;
  final String folderId;
  final String category;

  CategoryCardNew({
    required this.parentPath,
    required this.subFolders,
    required this.folderId,
    required this.category,
  });

  @override
  _CategoryCardNewState createState() => _CategoryCardNewState();
}

class _CategoryCardNewState extends State<CategoryCardNew> {
  late FirebaseService _firebaseService;

  @override
  void initState() {
    super.initState();
    _firebaseService = Provider.of<FirebaseService>(context, listen: false);
  }

  Future<void> _fetchSubFolders() async {
    final nextPath = '${widget.parentPath}/subfolders';
    final subFolders = await _firebaseService.getSubFolders(nextPath);
    Navigator.pushNamed(
      context,
      "/category-screen-new",
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
        trailing: IconButton(
          icon: const Icon(Icons.copy),
          onPressed: () {
            _duplicateDeck();
          },
        ),
        onTap: () async {
          _fetchSubFolders();
        },
      ),
    );
  }

  void _duplicateDeck() async {
    // Split the parentPath into segments
    List<String> segments = widget.parentPath.split('/');

    // Remove the last two segments to move one level up
    if (segments.length > 1) {
      segments.removeLast(); // Remove the "subfolders" keyword
    }

    // Join the remaining segments to form the new path
    final nextPath = segments.join('/');

    await _firebaseService.duplicateCategory(nextPath, widget.folderId);
  }
}
