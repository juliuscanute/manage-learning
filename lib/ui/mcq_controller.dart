import 'package:flutter/material.dart';

class MCQController {
  List<TextEditingController> optionsControllers = [];
  List<TextEditingController> optionsTexControllers = [];
  TextEditingController answerIndexController = TextEditingController();

  void addOption() {
    optionsControllers.add(TextEditingController());
    optionsTexControllers.add(TextEditingController());
  }

  void removeOption(int index) {
    if (optionsControllers.length > 1 && index < optionsControllers.length) {
      optionsControllers.removeAt(index);
      optionsTexControllers.removeAt(index);
    }
  }

  MCQController.fromMap(Map<String, dynamic> mcqData) {
    final options = List<String>.from(mcqData['options'] ?? []);
    final optionsTex = List<String>.from(mcqData['options_tex'] ?? []);
    final answerIndex = mcqData['answer_index'];

    optionsControllers =
        options.map((option) => TextEditingController(text: option)).toList();
    optionsTexControllers = optionsTex
        .map((optionTex) => TextEditingController(text: optionTex))
        .toList();
    answerIndexController.text = answerIndex?.toString() ?? '';
  }

  MCQController.initialize() {
    optionsControllers = List.generate(1, (_) => TextEditingController());
    optionsTexControllers = List.generate(1, (_) => TextEditingController());
    answerIndexController =
        TextEditingController(text: '0'); // Default answer index
  }

  Map<String, dynamic> toMap() {
    return {
      "options": optionsControllers.map((c) => c.text).toList(),
      "options_tex": optionsTexControllers.map((c) => c.text).toList(),
      "answer_index": int.tryParse(answerIndexController.text)
    };
  }
}
