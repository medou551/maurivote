// ══════════════════════════════════════════════════════════════════════════════
// ÉCRANS STUB — seront implémentés dans les sprints S2 et S3
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

// ── election_detail_screen.dart ────────────────────────────────────────────────
class ElectionDetailScreen extends StatelessWidget {
  final String electionId;
  const ElectionDetailScreen({super.key, required this.electionId});

  @override
  Widget build(BuildContext context) => _Stub(
    title: 'Détail Élection',
    subtitle: 'electionId: $electionId',
    icon: Icons.ballot_outlined,
    sprint: 'Sprint 2 — J8',
  );
}

// ── vote_screen.dart ───────────────────────────────────────────────────────────
class VoteScreen extends StatelessWidget {
  final String electionId;
  const VoteScreen({super.key, required this.electionId});

  @override
  Widget build(BuildContext context) => _Stub(
    title: 'Vote',
    subtitle: 'electionId: $electionId',
    icon: Icons.how_to_vote_outlined,
    sprint: 'Sprint 2 — J9',
  );
}

// ── vote_confirmation_screen.dart ──────────────────────────────────────────────
class VoteConfirmationScreen extends StatelessWidget {
  final String electionId;
  final String? candidateId;
  const VoteConfirmationScreen({
    super.key, required this.electionId, this.candidateId,
  });

  @override
  Widget build(BuildContext context) => _Stub(
    title: 'Confirmation du Vote',
    icon: Icons.check_circle_outline,
    sprint: 'Sprint 2 — J10',
  );
}

// ── vote_receipt_screen.dart ───────────────────────────────────────────────────
class VoteReceiptScreen extends StatelessWidget {
  final String? recuHash;
  const VoteReceiptScreen({super.key, this.recuHash});

  @override
  Widget build(BuildContext context) => _Stub(
    title: 'Reçu de Vote',
    subtitle: recuHash != null ? 'Hash: ${recuHash!.substring(0, 16)}...' : '',
    icon: Icons.qr_code_outlined,
    sprint: 'Sprint 2 — J11',
  );
}

// ── resultats_screen.dart ──────────────────────────────────────────────────────
class ResultatsScreen extends StatelessWidget {
  final String? electionId;
  const ResultatsScreen({super.key, this.electionId});

  @override
  Widget build(BuildContext context) => _Stub(
    title: 'Résultats',
    subtitle: electionId != null ? 'electionId: $electionId' : 'Toutes les élections',
    icon: Icons.bar_chart_outlined,
    sprint: 'Sprint 3 — J15',
  );
}

// ── profil_screen.dart ─────────────────────────────────────────────────────────
class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) => _Stub(
    title: 'Mon Profil',
    icon: Icons.person_outline,
    sprint: 'Sprint 2 — J11',
  );
}

// ── bureau_vote_screen.dart ────────────────────────────────────────────────────
class BureauVoteScreen extends StatelessWidget {
  const BureauVoteScreen({super.key});

  @override
  Widget build(BuildContext context) => _Stub(
    title: 'Mon Bureau de Vote',
    icon: Icons.location_on_outlined,
    sprint: 'Sprint 2 — J12',
  );
}

// ── admin_dashboard_screen.dart ────────────────────────────────────────────────
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => _Stub(
    title: 'Administration CENI',
    icon: Icons.admin_panel_settings_outlined,
    sprint: 'Sprint 3 — J19',
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// Widget Stub générique
// ══════════════════════════════════════════════════════════════════════════════
class _Stub extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String sprint;

  const _Stub({
    required this.title,
    this.subtitle = '',
    required this.icon,
    required this.sprint,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 24),
              Text(title,
                  style: const TextStyle(fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(subtitle,
                    style: const TextStyle(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryGreen),
                ),
                child: Text(
                  '🚧 Sera implémenté au $sprint',
                  style: const TextStyle(color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
