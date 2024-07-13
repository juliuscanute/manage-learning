import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';

class LatexToggle extends StatefulWidget {
  final TextEditingController normalController;
  final TextEditingController latexController;
  final String label;

  LatexToggle({
    required this.normalController,
    required this.latexController,
    required this.label,
  });

  @override
  _LatexToggleState createState() => _LatexToggleState();
}

class _LatexToggleState extends State<LatexToggle> {
  bool _isLatexVisible = false;

  String ensureLatexSyntax(String text) {
    return '<p>$text</p>';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                if (!_isLatexVisible)
                  TextField(
                    controller: widget.normalController,
                    decoration: InputDecoration(
                      labelText: widget.label,
                      border: const OutlineInputBorder(),
                    ),
                    readOnly: _isLatexVisible,
                  ),
                if (_isLatexVisible)
                  Column(
                    children: [
                      TextField(
                        controller: widget.latexController,
                        decoration: InputDecoration(
                          labelText: 'Edit ${widget.label} LaTeX',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TeXView(
                          child: TeXViewDocument(
                            widget.latexController.text.isNotEmpty
                                ? ensureLatexSyntax(widget.latexController.text)
                                : r'\text{No LaTeX content}',
                            style: const TeXViewStyle(
                              backgroundColor: Colors.transparent,
                              contentColor: Colors.black,
                            ),
                          ),
                          renderingEngine: const TeXViewRenderingEngine.mathjax(),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.toggle_on),
            onPressed: () {
              setState(() {
                _isLatexVisible = !_isLatexVisible;
              });
            },
          ),
        ],
      ),
    );
  }
}
