import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_learning/data/firebase_service.dart';
import 'package:manage_learning/ui/study_deck/app_bloc.dart';
import 'package:manage_learning/ui/study_deck/app_event.dart';
import 'package:manage_learning/ui/study_deck/app_state.dart';
import 'package:provider/provider.dart';
import 'category_card_new.dart';
import 'deck_list_item_new.dart';

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
  late List<Map<String, dynamic>> foldersToShow;

  @override
  void initState() {
    super.initState();
    foldersToShow = widget.subFolders;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AppBloc(Provider.of<FirebaseService>(context, listen: false)),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.parentFolderName),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    context
                        .read<AppBloc>()
                        .add(RefreshCategories(widget.parentPath));
                  },
                ),
              ],
            ),
            body: BlocListener<AppBloc, AppState>(
              listener: (context, state) {
                _handleAppState(context, state);
              },
              child: BlocBuilder<AppBloc, AppState>(
                builder: (context, state) {
                  if (state is CategoriesLoaded) {
                    foldersToShow = state.categories;
                  }
                  return Stack(
                    children: [
                      buildSubfolderLayout(
                          context, foldersToShow, widget.parentPath),
                      if (state is AppLoading)
                        const Center(child: CircularProgressIndicator()),
                      if (state is AppError) Center(child: Text(state.message)),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleAppState(BuildContext context, AppState state) {
    if (state is AppError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  }

  Widget buildSubfolderLayout(BuildContext context,
      List<Map<String, dynamic>> subFolders, String parentPath) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 600 ? 4 : 1;
        double width =
            (constraints.maxWidth - (crossAxisCount - 1) * 10) / crossAxisCount;

        return SingleChildScrollView(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
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
