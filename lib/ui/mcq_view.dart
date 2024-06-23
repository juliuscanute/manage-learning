import 'package:flutter/material.dart';
import 'package:manage_learning/ui/latex_toggle.dart';
import 'package:manage_learning/ui/mcq_controller.dart';

class MCQView extends StatefulWidget {
  final MCQController mcqController;

  const MCQView({required this.mcqController});

  @override
  _MCQViewState createState() => _MCQViewState();
}

class _MCQViewState extends State<MCQView> {
  void _addOption() {
    setState(() {
      widget.mcqController.addOption();
    });
  }

  void _removeOption(int index) {
    setState(() {
      widget.mcqController.removeOption(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ..._buildOptionsList(),
          _buildAddOptionButton(),
          _buildAnswerIndexTextField(),
        ],
      ),
    );
  }

  List<Widget> _buildOptionsList() {
    return List.generate(widget.mcqController.optionsControllers.length,
        (index) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: LatexToggle(
                normalController:
                    widget.mcqController.optionsControllers[index],
                latexController:
                    widget.mcqController.optionsTexControllers[index],
                label: 'Option ${index + 1}',
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle),
              onPressed: () => _removeOption(index),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAddOptionButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: ElevatedButton(
        onPressed: _addOption,
        child: const Text('Add Option'),
      ),
    );
  }

  Widget _buildAnswerIndexTextField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: TextField(
        controller: widget.mcqController.answerIndexController,
        decoration: const InputDecoration(labelText: 'Answer Index'),
        keyboardType: TextInputType.number,
      ),
    );
  }
}
