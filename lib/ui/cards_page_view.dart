import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manage_learning/data/firebase_service.dart';
import 'package:manage_learning/ui/deck_bloc.dart';
import 'package:manage_learning/ui/deck_event.dart';
import 'package:manage_learning/ui/deck_state.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';

class CardsPageView extends StatelessWidget {
  final String? deckId;
  final DeckOperation operation;

  const CardsPageView({required this.deckId, required this.operation, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DeckBloc(
          Provider.of<FirebaseService>(context, listen: false),
          deckId,
          operation)
        ..add(LoadDeckData(
          deckId,
        )),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            operation == DeckOperation.create
                ? 'Create Deck and Cards'
                : operation == DeckOperation.edit
                    ? 'Edit Deck and Cards'
                    : 'Load Deck and Cards',
          ),
        ),
        body: BlocBuilder<DeckBloc, DeckState>(
          builder: (context, state) {
            if (state.finishSave) {
              Navigator.of(context).pop();
            }
            return Stack(children: [
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildDeckTitle(state, context),
                            const SizedBox(height: 8),
                            _buildDeckTitleInput(state),
                            const SizedBox(height: 16),
                            _buildVideoUrlInput(state),
                            _buildEvaluatorStrictnessSwitch(context, state),
                            _buildPublicSwitch(context, state),
                            _buildMindmapImagePicker(context, state),
                            _buildTagsInput(state),
                            _buildCardsTitle(context),
                            _buildCardsList(context, state),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildButtonRow(context),
                ],
              ),
              if (state.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _buildDeckTitle(DeckState state, BuildContext context) {
    return Text('Deck Title', style: Theme.of(context).textTheme.headlineSmall);
  }

  Widget _buildDeckTitleInput(DeckState state) {
    return TextField(
      controller: state.deckTitleController,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Enter deck title',
      ),
    );
  }

  Widget _buildVideoUrlInput(DeckState state) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: state.videoUrlController,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Video URL',
          hintText: 'Enter Video URL',
        ),
      ),
    );
  }

  Widget _buildEvaluatorStrictnessSwitch(
      BuildContext context, DeckState state) {
    return Row(
      children: [
        Text(
            'Do you want the evaluator to be strict? ${state.isEvaluatorStrict ? 'YES' : 'NO'}'),
        Switch(
          value: state.isEvaluatorStrict,
          onChanged: (bool value) {
            context.read<DeckBloc>().add(UpdateEvaluatorStrictness(value));
          },
        ),
      ],
    );
  }

  Widget _buildPublicSwitch(BuildContext context, DeckState state) {
    return Row(
      children: [
        Text('Is it public? ${state.isPublic ? 'Yes' : 'No'}'),
        Switch(
          value: state.isPublic,
          onChanged: (bool value) {
            context.read<DeckBloc>().add(UpdatePublicStatus(value));
          },
        ),
      ],
    );
  }

  Widget _buildMindmapImagePicker(BuildContext context, DeckState state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _buildImagePicker(state.mindmapImageController,
          'Pick Mindmap Image', context, state, true),
    );
  }

  Widget _buildTagsInput(DeckState state) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: state.tagsController,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Tags',
          hintText: 'Enter tags (e.g., a/b/c)',
        ),
      ),
    );
  }

  Widget _buildCardsTitle(BuildContext context) {
    return Text('Cards', style: Theme.of(context).textTheme.headlineSmall);
  }

  Widget _buildCardsList(BuildContext context, DeckState state) {
    return Column(
      children: state.cardControllers
          .asMap()
          .entries
          .map((entry) => _buildCard(entry.value, entry.key, context, state))
          .toList(),
    );
  }

  Widget _buildCard(Map<String, dynamic> controller, int index,
      BuildContext context, DeckState state) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Stack(
        children: [
          Padding(
            padding:
                const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
            child: Column(
              children: [
                const SizedBox(height: 24),
                TextField(
                  controller: controller['front'] as TextEditingController,
                  decoration: const InputDecoration(
                    labelText: 'Front',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller['back'] as TextEditingController,
                  decoration: const InputDecoration(
                    labelText: 'Back',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                _buildImagePicker(
                    controller, 'Pick Recall Image', context, state, false),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.vertical_align_top),
                      onPressed: () =>
                          context.read<DeckBloc>().add(AddCardAbove(index)),
                      tooltip: 'Add Card Above',
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_upward),
                      onPressed: index == 0
                          ? null
                          : () => context
                              .read<DeckBloc>()
                              .add(MoveCard(index, index - 1)),
                      tooltip: 'Move Up',
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_downward),
                      onPressed: index == state.cardControllers.length - 1
                          ? null
                          : () => context
                              .read<DeckBloc>()
                              .add(MoveCard(index, index + 1)),
                      tooltip: 'Move Down',
                    ),
                    IconButton(
                      icon: const Icon(Icons.vertical_align_bottom),
                      onPressed: () =>
                          context.read<DeckBloc>().add(AddCardBelow(index)),
                      tooltip: 'Add Card Below',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 8,
            top: 0,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                context.read<DeckBloc>().add(DeleteImage(controller));
                state.cardControllers.removeAt(index);
              },
              tooltip: 'Delete Card',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker(
      Map<String, dynamic> cardController,
      String buttonText,
      BuildContext context,
      DeckState state,
      bool isMindmap) {
    return Column(
      children: [
        if (cardController['image'] != null ||
            cardController['imageUrl']?.isNotEmpty == true)
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: cardController['image'] != null
                ? Image.memory(
                    cardController['image'],
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    cardController['imageUrl'],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.error,
                          size: 24,
                          color: Colors.red,
                        ),
                      );
                    },
                  ),
          ),
        ElevatedButton.icon(
          onPressed: () =>
              _pickImage(cardController, context, state, isMindmap),
          icon: const Icon(Icons.image),
          label: Text(buttonText),
        ),
      ],
    );
  }

  Future<void> _pickImage(Map<String, dynamic> cardController,
      BuildContext context, DeckState state, isMindMap) async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        Uint8List fileBytes = await pickedFile.readAsBytes();
        String fileName = pickedFile.name;
        context
            .read<DeckBloc>()
            .add(UpdateImage(cardController, fileBytes, fileName, isMindMap));
      } else {
        String filePath = pickedFile.path;
        String fileName = basename(filePath);
        context
            .read<DeckBloc>()
            .add(UpdateImage(cardController, filePath, fileName, isMindMap));
      }
    }
  }

  Widget _buildButtonRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton(
                onPressed: () =>
                    context.read<DeckBloc>().add(AddCardController()),
                child: const Text('Add Another Card'),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: ElevatedButton(
                onPressed: () {
                  context.read<DeckBloc>().add(SaveDeckAndCards());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Save Deck and Cards'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum DeckOperation { create, edit, load }
