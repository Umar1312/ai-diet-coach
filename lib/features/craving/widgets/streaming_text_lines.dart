import 'package:flutter/material.dart';

/// Streams text lines one-by-one with a typewriter effect.
/// Each line fades in and characters appear sequentially.
class StreamingTextLines extends StatefulWidget {
  final List<String> lines;
  final Duration lineDelay;
  final Duration charDuration;
  final TextStyle? style;

  const StreamingTextLines({
    super.key,
    required this.lines,
    this.lineDelay = const Duration(milliseconds: 600),
    this.charDuration = const Duration(milliseconds: 25),
    this.style,
  });

  @override
  State<StreamingTextLines> createState() => _StreamingTextLinesState();
}

class _StreamingTextLinesState extends State<StreamingTextLines> {
  final List<String> _visibleLines = [];
  final List<String> _typedLines = [];

  @override
  void initState() {
    super.initState();
    _startSequence();
  }

  @override
  void didUpdateWidget(covariant StreamingTextLines oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lines.join() != oldWidget.lines.join()) {
      _visibleLines.clear();
      _typedLines.clear();
      _startSequence();
    }
  }

  Future<void> _startSequence() async {
    for (int i = 0; i < widget.lines.length; i++) {
      await Future.delayed(widget.lineDelay);
      if (!mounted) return;
      setState(() => _visibleLines.add(widget.lines[i]));
      await _typeLine(i);
    }
  }

  Future<void> _typeLine(int index) async {
    final text = widget.lines[index];
    for (int i = 1; i <= text.length; i++) {
      await Future.delayed(widget.charDuration);
      if (!mounted) return;
      setState(() {
        if (_typedLines.length <= index) {
          _typedLines.add(text.substring(0, i));
        } else {
          _typedLines[index] = text.substring(0, i);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final style =
        widget.style ??
        const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF6E6E80),
          height: 1.6,
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(widget.lines.length, (index) {
        final isVisible = index < _visibleLines.length;
        final typed = index < _typedLines.length ? _typedLines[index] : '';
        return AnimatedOpacity(
          opacity: isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(typed, style: style, textAlign: TextAlign.center),
          ),
        );
      }),
    );
  }
}
