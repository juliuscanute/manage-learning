import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'category_card_new.dart';
import 'deck_list_item_new.dart';
import 'package:manage_learning/data/firebase_service.dart';

class SubfolderScreen extends StatefulWidget {
  final String parentPath;
  final String parentFolderName;
  final List<Map<String, dynamic>> subFolders;

  SubfolderScreen({
    required this.parentFolderName,
    required this.parentPath,
    required this.subFolders,
  });

  @override
  _SubfolderScreenState createState() => _SubfolderScreenState();
}

class _SubfolderScreenState extends State<SubfolderScreen> {
  late Future<List<Map<String, dynamic>>> _subFoldersFuture;

  @override
  void initState() {
    super.initState();
    _subFoldersFuture = _fetchSubFolders();
  }

  Future<List<Map<String, dynamic>>> _fetchSubFolders() async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    return await firebaseService.getSubFolders(widget.parentPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.parentFolderName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _subFoldersFuture = _fetchSubFolders();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _subFoldersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading subfolders'));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No subfolders found'));
          }

          final subFolders = snapshot.data ?? [];

          return buildSubfolderLayout(context, subFolders, widget.parentPath);
        },
      ),
    );
  }

  Widget buildSubfolderLayout(BuildContext context,
      List<Map<String, dynamic>> subFolders, String parentPath) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the number of columns based on screen width
        int crossAxisCount =
            constraints.maxWidth > 600 ? 4 : 1; // Example breakpoint at 600px

        // Calculate the width of each child based on the number of columns
        double width =
            (constraints.maxWidth - (crossAxisCount - 1) * 10) / crossAxisCount;

        return SingleChildScrollView(
          child: Wrap(
            spacing: 10, // Horizontal space between items
            runSpacing: 10, // Vertical space between items
            children: List.generate(subFolders.length, (index) {
              final folder = subFolders[index];
              if (folder['type'] != 'card') {
                return SizedBox(
                  width: width,
                  child: CategoryCardNew(
                    category: folder['id'],
                    parentPath: '$parentPath/${folder['id']}',
                    subFolders: folder['subFolders'] ?? [],
                    folderId: folder['id'],
                  ),
                );
              } else {
                final leafNode = DeckIndex(
                  title: folder['title'] ?? 'Untitled',
                  deckId: folder['deckId'],
                  videoUrl: folder['videoUrl'],
                  mapUrl: folder['mapUrl'],
                  type: 'card',
                  isPublic: folder['isPublic'] ?? false,
                  parentPath: parentPath,
                  folderId: folder['id'],
                );
                return SizedBox(
                  width: width,
                  child: DeckListItemNew(deck: leafNode.toMap()),
                );
              }
            }),
          ),
        );
      },
    );
  }
}

class DeckIndex {
  final String title;
  final String deckId;
  final String? videoUrl;
  final String? mapUrl;
  final String type;
  final bool isPublic;
  final String parentPath;
  final String folderId;

  DeckIndex({
    required this.title,
    required this.deckId,
    this.videoUrl,
    this.mapUrl,
    required this.type,
    required this.isPublic,
    required this.parentPath,
    required this.folderId,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'deckId': deckId,
      'videoUrl': videoUrl,
      'mapUrl': mapUrl,
      'type': type,
      'isPublic': isPublic,
      'parentPath': parentPath,
      'folderId': folderId,
    };
  }
}
