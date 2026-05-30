import 'package:flutter/material.dart';
import '../systems/theme_system.dart';
import '../main.dart';

/// Settings page
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _themeSystem = ThemeSystem();
  bool _reduceMotion = false;
  double _textScale = 1.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = context.findAncestorStateOfType<RiftDemoAppState>();

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance Section
          _buildSectionHeader('Appearance', isDark),
          const SizedBox(height: 8),
          _buildSettingsCard(
            isDark,
            children: [
              _buildSettingTile(
                isDark,
                icon: Icons.palette_rounded,
                iconColor: const Color(0xFF007AFF),
                title: 'Theme Mode',
                subtitle: _getThemeModeLabel(_themeSystem.currentMode),
                trailing: DropdownButton<ThemeMode>(
                  value: _themeSystem.currentMode,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('System'),
                    ),
                  ],
                  onChanged: (mode) {
                    if (mode != null) {
                      _themeSystem.setThemeMode(mode);
                      appState?.setState(() {});
                      setState(() {});
                    }
                  },
                ),
              ),
              const Divider(height: 1),
              _buildSettingTile(
                isDark,
                icon: Icons.format_size_rounded,
                iconColor: const Color(0xFF5856D6),
                title: 'Text Scale',
                subtitle: '${(_textScale * 100).toInt()}%',
                trailing: SizedBox(
                  width: 150,
                  child: Slider(
                    value: _textScale,
                    min: 0.8,
                    max: 2.0,
                    divisions: 12,
                    label: '${(_textScale * 100).toInt()}%',
                    onChanged: (value) {
                      setState(() => _textScale = value);
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Behavior Section
          _buildSectionHeader('Behavior', isDark),
          const SizedBox(height: 8),
          _buildSettingsCard(
            isDark,
            children: [
              _buildSettingTile(
                isDark,
                icon: Icons.animation_rounded,
                iconColor: const Color(0xFFFF9500),
                title: 'Reduce Motion',
                subtitle: 'Minimize animations',
                trailing: Switch(
                  value: _reduceMotion,
                  onChanged: (value) {
                    setState(() => _reduceMotion = value);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About', isDark),
          const SizedBox(height: 8),
          _buildSettingsCard(
            isDark,
            children: [
              _buildSettingTile(
                isDark,
                icon: Icons.info_rounded,
                iconColor: const Color(0xFF34C759),
                title: 'Version',
                subtitle: '1.0.0',
              ),
              const Divider(height: 1),
              _buildSettingTile(
                isDark,
                icon: Icons.description_rounded,
                iconColor: const Color(0xFF5AC8FA),
                title: 'Licenses',
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                onTap: () {
                  showLicensePage(context: context);
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Reset Button
          Center(
            child: TextButton(
              onPressed: () {
                _showResetDialog();
              },
              child: const Text(
                'Reset to Defaults',
                style: TextStyle(
                  color: Color(0xFFFF3B30),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white38 : Colors.black38,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(bool isDark, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingTile(
    bool isDark, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _showResetDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Reset Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
          ),
        ),
        content: Text(
          'Are you sure you want to reset all settings to their default values?',
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetSettings();
            },
            child: const Text(
              'Reset',
              style: TextStyle(
                color: Color(0xFFFF3B30),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetSettings() {
    setState(() {
      _reduceMotion = false;
      _textScale = 1.0;
    });
    _themeSystem.setThemeMode(ThemeMode.system);
    final appState = context.findAncestorStateOfType<RiftDemoAppState>();
    appState?.setState(() {});
  }
}
