import 'package:flutter/material.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'auth/admin_login_screen.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            backgroundColor: cs.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cs.primary, const Color(0xFF0D47A1)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_rounded,
                          size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'SafeZone',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Text(
                      'Community Incident Reporter',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdminLoginScreen()),
                ),
                icon: const Icon(Icons.admin_panel_settings,
                    color: Colors.white70, size: 18),
                label: const Text('Admin',
                    style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // SDG 16 Banner
                  _SdgBanner(),
                  const SizedBox(height: 20),

                  // About Section
                  _SectionCard(
                    icon: Icons.info_outline_rounded,
                    title: 'About SafeZone',
                    color: Colors.blue.shade700,
                    child: const Text(
                      'SafeZone is a community-powered incident reporting platform aligned with '
                      'UN Sustainable Development Goal 16 — Peace, Justice and Strong Institutions.\n\n'
                      'Citizens report incidents pseudonymously to protect their identity from '
                      'the public while enabling verified institutions to hold bad actors accountable.',
                      style: TextStyle(height: 1.6, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // How It Works
                  _SectionCard(
                    icon: Icons.lightbulb_outline_rounded,
                    title: 'How It Works',
                    color: Colors.amber.shade700,
                    child: Column(
                      children: const [
                        _FeatureRow(
                          icon: Icons.person_outline,
                          text: 'Register with your real IC — you get an anonymous alias.',
                        ),
                        _FeatureRow(
                          icon: Icons.report_problem_outlined,
                          text: 'Report incidents like theft, harassment, or suspicious activity.',
                        ),
                        _FeatureRow(
                          icon: Icons.analytics_outlined,
                          text: 'View a live Area Safety Score calculated from recent reports.',
                        ),
                        _FeatureRow(
                          icon: Icons.verified_user_outlined,
                          text: 'Admins verify reports and can share verified info with authorities.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // SDG 16 Pillars
                  _SectionCard(
                    icon: Icons.gavel_rounded,
                    title: 'SDG 16 Pillars We Support',
                    color: Colors.green.shade700,
                    child: Column(
                      children: const [
                        _PillarRow(number: '16.1',
                            text: 'Reduce all forms of violence and related death rates everywhere.'),
                        _PillarRow(number: '16.6',
                            text: 'Develop effective, accountable and transparent institutions.'),
                        _PillarRow(number: '16.10',
                            text: 'Ensure public access to information and protect fundamental freedoms.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // CTA Buttons
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Login as Citizen',
                        style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen()),
                    ),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Register New Account',
                        style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _SdgBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.indigo.shade700],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('16',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0))),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SDG 16',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 1.5)),
                Text('Peace, Justice &\nStrong Institutions',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Icon(Icons.verified_rounded, color: Colors.white70, size: 28),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ]),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.amber.shade700),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text, style: const TextStyle(fontSize: 13.5, height: 1.4))),
        ],
      ),
    );
  }
}

class _PillarRow extends StatelessWidget {
  final String number;
  final String text;
  const _PillarRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(number,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 13.5, height: 1.4))),
        ],
      ),
    );
  }
}
