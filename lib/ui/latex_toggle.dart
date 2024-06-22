import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';

class LatexToggle extends StatefulWidget {
  final TextEditingController normalController;
  final TextEditingController latexController;

  LatexToggle({
    required this.normalController,
    required this.latexController,
  });

  @override
  _LatexToggleState createState() => _LatexToggleState();
}

class _LatexToggleState extends State<LatexToggle> {
  bool _isLatexVisible = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      child: Row(
        children: [
          if (!_isLatexVisible)
            Expanded(
              child: TextField(
                controller: widget.normalController,
                decoration: const InputDecoration(
                  labelText: 'Front',
                  border: OutlineInputBorder(),
                ),
                readOnly: _isLatexVisible,
              ),
            ),
          if (_isLatexVisible)
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: widget.latexController,
                      decoration: const InputDecoration(
                        labelText: 'Edit LaTeX',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: TeXView(
                        child: TeXViewDocument(
                          widget.latexController.text.isNotEmpty
                              ? "\\(${widget.latexController.text}\\)"
                              : r'\text{No LaTeX content}',
                          style: const TeXViewStyle(
                            backgroundColor: Colors.transparent,
                            contentColor: Colors.black,
                          ),
                        ),
                        renderingEngine: const TeXViewRenderingEngine.mathjax(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (widget.latexController.text.isNotEmpty)
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
