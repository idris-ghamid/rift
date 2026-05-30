import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'systems/asset_manager.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final assetManager = AssetManager();

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(
          'About',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: accent),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // ── Profile Header with Real Photo ──
          _Card(
            isDark: isDark,
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Real profile photo with shadow
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withAlpha(51),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: assetManager.buildManagedImage(
                    path: AssetManager.profileImagePath,
                    width: 100,
                    height: 100,
                    circular: true,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Idris Ghamid',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'إدريس غامد',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : Colors.black38,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent.withAlpha(26), accent.withAlpha(15)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: accent.withAlpha(51)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.business_rounded, size: 14, color: accent),
                      const SizedBox(width: 6),
                      Text(
                        'Founder @ IDRISIUM Corp',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Programmer building mobile apps, web systems & games (Unity) | Editor (AE, Photoshop)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: isDark
                        ? const Color(0xFFEBEBF5)
                        : const Color(0xFF3C3C43),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Overview ──
          _SectionHeader(
              title: 'Overview', icon: Icons.person_outline, isDark: isDark),
          const SizedBox(height: 8),
          _Card(
            isDark: isDark,
            child: Text(
              'I build scalable software systems, developer tools, and AI-powered products across mobile and web. I also work on game development and creative digital production.',
              style: TextStyle(
                fontSize: 15,
                height: 1.7,
                color:
                    isDark ? const Color(0xFFEBEBF5) : const Color(0xFF3C3C43),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Focus Areas ──
          _SectionHeader(
              title: 'Focus Areas',
              icon: Icons.track_changes_outlined,
              isDark: isDark),
          const SizedBox(height: 8),
          _Card(
            isDark: isDark,
            child: Column(
              children: [
                _FocusRow(
                    icon: Icons.phone_android_rounded,
                    label: 'Mobile & Web Development',
                    isDark: isDark),
                _FocusRow(
                    icon: Icons.psychology_rounded,
                    label: 'AI Systems & Automation',
                    isDark: isDark),
                _FocusRow(
                    icon: Icons.construction_rounded,
                    label: 'Developer Tools & Infrastructure',
                    isDark: isDark),
                _FocusRow(
                    icon: Icons.sports_esports_rounded,
                    label: 'Game Development (Unity)',
                    isDark: isDark),
                _FocusRow(
                    icon: Icons.palette_rounded,
                    label: 'Creative Editing (AE, Photoshop)',
                    isDark: isDark,
                    last: true),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Tech Stack ──
          _SectionHeader(
              title: 'Tech Stack', icon: Icons.code_rounded, isDark: isDark),
          const SizedBox(height: 8),
          _Card(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TechCategory(
                  label: 'Mobile',
                  tags: ['Flutter', 'Dart', 'Kotlin'],
                  color: const Color(0xFF007AFF),
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _TechCategory(
                  label: 'Web',
                  tags: [
                    'React',
                    'Next.js',
                    'JavaScript',
                    'HTML',
                    'CSS',
                    'Tailwind'
                  ],
                  color: const Color(0xFF34C759),
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _TechCategory(
                  label: 'AI',
                  tags: ['LLMs', 'Gemini API', 'Automation'],
                  color: const Color(0xFFAF52DE),
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _TechCategory(
                  label: 'Game Dev',
                  tags: ['Unity'],
                  color: const Color(0xFFFF9500),
                  isDark: isDark,
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── IDRISIUM Corp with Real Logo ──
          _SectionHeader(
              title: 'IDRISIUM Corp',
              icon: Icons.business_rounded,
              isDark: isDark),
          const SizedBox(height: 8),
          _Card(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company logo with shadow
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5856D6).withAlpha(26),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: assetManager.buildManagedImage(
                      path: AssetManager.companyLogoPath,
                      width: 220,
                      height: 110,
                      borderRadius: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF5856D6).withAlpha(26),
                            const Color(0xFF5856D6).withAlpha(15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.rocket_launch_rounded,
                          size: 20, color: Color(0xFF5856D6)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Building modern digital products, developer tools, and AI-driven systems.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: isDark
                              ? const Color(0xFFEBEBF5)
                              : const Color(0xFF3C3C43),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoRow(
                    icon: Icons.phone_android_rounded,
                    text: 'Mobile & Web Apps',
                    isDark: isDark),
                _InfoRow(
                    icon: Icons.build_rounded,
                    text: 'Developer Tools',
                    isDark: isDark),
                _InfoRow(
                    icon: Icons.smart_toy_rounded,
                    text: 'AI Systems & Automation',
                    isDark: isDark,
                    last: true),
                const SizedBox(height: 16),
                _LinkButton(
                  label: 'Visit Website',
                  url: 'http://idrisium.linkpc.net/',
                  isDark: isDark,
                  onTap: () => _launchUrl('http://idrisium.linkpc.net/'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Connect ──
          _SectionHeader(
              title: 'Connect', icon: Icons.link_rounded, isDark: isDark),
          const SizedBox(height: 8),
          _Card(
            isDark: isDark,
            child: Column(
              children: [
                _SocialRow(
                  icon: Icons.work_rounded,
                  label: 'LinkedIn',
                  value: 'idris-ghamid',
                  color: const Color(0xFF0077B5),
                  isDark: isDark,
                  onTap: () =>
                      _launchUrl('https://linkedin.com/in/idris-ghamid'),
                ),
                _Divider(isDark: isDark),
                _SocialRow(
                  icon: Icons.close_rounded,
                  label: 'X (Twitter)',
                  value: '@IdrisGhamid',
                  color: isDark ? Colors.white : Colors.black,
                  isDark: isDark,
                  onTap: () => _launchUrl('https://twitter.com/IdrisGhamid'),
                ),
                _Divider(isDark: isDark),
                _SocialRow(
                  icon: Icons.camera_alt_rounded,
                  label: 'Instagram',
                  value: '@idris.ghamid',
                  color: const Color(0xFFE1306C),
                  isDark: isDark,
                  onTap: () => _launchUrl('https://instagram.com/idris.ghamid'),
                ),
                _Divider(isDark: isDark),
                _SocialRow(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Threads',
                  value: '@idris.ghamid',
                  color: isDark ? Colors.white : Colors.black,
                  isDark: isDark,
                  onTap: () => _launchUrl('https://threads.net/@idris.ghamid'),
                ),
                _Divider(isDark: isDark),
                _SocialRow(
                  icon: Icons.music_note_rounded,
                  label: 'TikTok',
                  value: '@idris.ghamid',
                  color: const Color(0xFF000000),
                  isDark: isDark,
                  onTap: () => _launchUrl('https://tiktok.com/@idris.ghamid'),
                ),
                _Divider(isDark: isDark),
                _SocialRow(
                  icon: Icons.forum_rounded,
                  label: 'Reddit',
                  value: 'IdrisGhamid',
                  color: const Color(0xFFFF4500),
                  isDark: isDark,
                  onTap: () =>
                      _launchUrl('https://reddit.com/user/IdrisGhamid'),
                ),
                _Divider(isDark: isDark),
                _SocialRow(
                  icon: Icons.send_rounded,
                  label: 'Telegram',
                  value: '@IDRV72',
                  color: const Color(0xFF0088CC),
                  isDark: isDark,
                  onTap: () => _launchUrl('https://t.me/IDRV72'),
                ),
                _Divider(isDark: isDark),
                _SocialRow(
                  icon: Icons.push_pin_rounded,
                  label: 'Pinterest',
                  value: 'idrisghamid',
                  color: const Color(0xFFBD081C),
                  isDark: isDark,
                  onTap: () => _launchUrl('https://pinterest.com/idrisghamid'),
                ),
                _Divider(isDark: isDark),
                _SocialRow(
                  icon: Icons.code_rounded,
                  label: 'GitHub',
                  value: 'idris-ghamid',
                  color: isDark ? Colors.white : const Color(0xFF24292F),
                  isDark: isDark,
                  onTap: () => _launchUrl('https://github.com/idris-ghamid'),
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Rift ──
          _SectionHeader(
              title: 'Rift Database', icon: Icons.bolt_rounded, isDark: isDark),
          const SizedBox(height: 8),
          _Card(
            isDark: isDark,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accent.withAlpha(26), accent.withAlpha(15)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.bolt_rounded, size: 28, color: accent),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rift',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1C1C1E),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'The next-generation NoSQL database for Flutter & Dart',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _StatBadge(
                        label: '75+', sublabel: 'Features', isDark: isDark),
                    const SizedBox(width: 12),
                    _StatBadge(
                        label: '100%', sublabel: 'Pure Dart', isDark: isDark),
                    const SizedBox(width: 12),
                    _StatBadge(
                        label: '6', sublabel: 'Platforms', isDark: isDark),
                  ],
                ),
                const SizedBox(height: 18),
                _LinkButton(
                  label: 'View on GitHub',
                  url: 'https://github.com/idris-ghamid/rift',
                  isDark: isDark,
                  onTap: () =>
                      _launchUrl('https://github.com/idris-ghamid/rift'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Helper Widgets
// ══════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  const _SectionHeader(
      {required this.title, required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF007AFF).withAlpha(15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF007AFF)),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const _Card({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(51)
                : Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: isDark ? Colors.white.withAlpha(13) : Colors.black.withAlpha(13),
    );
  }
}

class _FocusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool last;
  const _FocusRow(
      {required this.icon,
      required this.label,
      required this.isDark,
      this.last = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withAlpha(15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF007AFF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TechCategory extends StatelessWidget {
  final String label;
  final List<String> tags;
  final Color color;
  final bool isDark;
  final bool last;
  const _TechCategory(
      {required this.label,
      required this.tags,
      required this.color,
      required this.isDark,
      this.last = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags
              .map((tag) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withAlpha(38)),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? color.withAlpha(230) : color,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  final bool last;
  const _InfoRow(
      {required this.icon,
      required this.text,
      required this.isDark,
      this.last = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF5856D6)),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFEBEBF5) : const Color(0xFF3C3C43),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  final bool last;
  final VoidCallback onTap;

  const _SocialRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    required this.onTap,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  final String label;
  final String url;
  final bool isDark;
  final VoidCallback onTap;

  const _LinkButton({
    required this.label,
    required this.url,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF007AFF).withAlpha(26),
                const Color(0xFF007AFF).withAlpha(15),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF007AFF).withAlpha(38)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.open_in_new_rounded,
                  size: 18, color: const Color(0xFF007AFF)),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF007AFF),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool isDark;
  const _StatBadge(
      {required this.label, required this.sublabel, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF007AFF).withAlpha(26),
              const Color(0xFF007AFF).withAlpha(15),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF007AFF).withAlpha(26)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF007AFF),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
