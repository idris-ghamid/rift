import 'package:flutter/material.dart';

/// Apple-style demo page with clean sections for description, code, and output.
class RiftDemoPage extends StatefulWidget {
  final String title;
  final String description;
  final String codeExample;
  final Future<String> Function() runDemo;
  final IconData? icon;
  final Color? accentColor;

  const RiftDemoPage({
    super.key,
    required this.title,
    required this.description,
    required this.codeExample,
    required this.runDemo,
    this.icon,
    this.accentColor,
  });

  @override
  State<RiftDemoPage> createState() => _RiftDemoPageState();
}

class _RiftDemoPageState extends State<RiftDemoPage> {
  String _output = '';
  bool _isRunning = false;
  bool _hasRun = false;

  Future<void> _run() async {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
    });
    try {
      final result = await widget.runDemo();
      if (mounted) {
        setState(() {
          _output = result;
          _isRunning = false;
          _hasRun = true;
        });
      }
    } catch (e, st) {
      if (mounted) {
        setState(() {
          _output = 'Error: $e\n\n$st';
          _isRunning = false;
          _hasRun = true;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Auto-run on open
    Future.microtask(() => _run());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accentColor ?? const Color(0xFF007AFF);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: accent,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isRunning)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Description Section
          _Section(
            icon: Icons.info_outline,
            iconColor: accent,
            title: 'About',
            isDark: isDark,
            child: Text(
              widget.description,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color:
                    isDark ? const Color(0xFFEBEBF5) : const Color(0xFF3C3C43),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Code Section
          _Section(
            icon: Icons.code_rounded,
            iconColor: const Color(0xFF34C759), // Apple green
            title: 'Code',
            isDark: isDark,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1C1C1E) : const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                widget.codeExample,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: const Color(0xFFA9DC76),
                  height: 1.6,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Output Section
          _Section(
            icon: Icons.terminal_rounded,
            iconColor: const Color(0xFFFF9500), // Apple orange
            title: 'Output',
            isDark: isDark,
            trailing: _isRunning
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: const Color(0xFFFF9500),
                    ),
                  )
                : null,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 140),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1C1C1E) : const Color(0xFF0D1117),
                borderRadius: BorderRadius.circular(8),
              ),
              child: !_hasRun && !_isRunning
                  ? Center(
                      child: Text(
                        'Press Run to execute',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : SelectableText(
                      _output,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        color: isDark
                            ? const Color(0xFFEBEBF5)
                            : const Color(0xFFE6EDF3),
                        height: 1.5,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isRunning ? null : _run,
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: _isRunning
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.play_arrow_rounded, size: 22),
        label: Text(
          _isRunning ? 'Running...' : 'Run Demo',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final bool isDark;
  final Widget child;
  final Widget? trailing;

  const _Section({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.isDark,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
