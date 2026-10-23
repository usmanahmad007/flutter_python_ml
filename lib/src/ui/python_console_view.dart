import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/python_bridge.dart';

/// Interactive developer console displaying live stdout and stderr streams
/// from on-device Python script execution.
class PythonConsoleView extends StatefulWidget {
  final PythonBridge? bridge;
  final String title;
  final double height;
  final Color backgroundColor;

  const PythonConsoleView({
    super.key,
    this.bridge,
    this.title = 'Python Runtime Output',
    this.height = 220,
    this.backgroundColor = const Color(0xFF0F172A),
  });

  @override
  State<PythonConsoleView> createState() => _PythonConsoleViewState();
}

class _PythonConsoleViewState extends State<PythonConsoleView> {
  final List<_ConsoleLine> _lines = [];
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    final b = widget.bridge ?? PythonBridge.instance;
    _stdoutSub = b.stdout.listen((msg) => _addLine(msg, isError: false));
    _stderrSub = b.stderr.listen((msg) => _addLine(msg, isError: true));
  }

  void _addLine(String text, {required bool isError}) {
    if (!mounted) return;
    setState(() {
      _lines.add(_ConsoleLine(
        text: text.trimRight(),
        isError: isError,
        timestamp: DateTime.now(),
      ));
    });
    if (_autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  void _clearLogs() {
    setState(() => _lines.clear());
  }

  void _copyAllLogs() {
    final buffer = StringBuffer();
    for (final l in _lines) {
      buffer.writeln('${l.isError ? "[STDERR]" : "[STDOUT]"} ${l.text}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Console logs copied to clipboard'),
          duration: Duration(seconds: 1)),
    );
  }

  @override
  void dispose() {
    _stdoutSub?.cancel();
    _stderrSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                const Icon(Icons.terminal_rounded,
                    size: 16, color: Colors.cyanAccent),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _autoScroll ? Icons.vertical_align_bottom : Icons.pause,
                    size: 15,
                    color: _autoScroll ? Colors.cyanAccent : Colors.grey,
                  ),
                  tooltip: _autoScroll ? 'Autoscroll ON' : 'Autoscroll PAUSED',
                  splashRadius: 16,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  onPressed: () => setState(() => _autoScroll = !_autoScroll),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy_rounded,
                      size: 15, color: Colors.grey),
                  tooltip: 'Copy all',
                  splashRadius: 16,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  onPressed: _copyAllLogs,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: Colors.grey),
                  tooltip: 'Clear',
                  splashRadius: 16,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  onPressed: _clearLogs,
                ),
              ],
            ),
          ),
          // Output Area
          Expanded(
            child: _lines.isEmpty
                ? const Center(
                    child: Text(
                      'Ready. Python stdout / stderr will appear here...',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Colors.white38),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(10),
                    itemCount: _lines.length,
                    itemBuilder: (context, idx) {
                      final l = _lines[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: SelectableText(
                          l.text,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            height: 1.35,
                            color: l.isError
                                ? const Color(0xFFF87171)
                                : const Color(0xFF34D399),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ConsoleLine {
  final String text;
  final bool isError;
  final DateTime timestamp;

  _ConsoleLine(
      {required this.text, required this.isError, required this.timestamp});
}
