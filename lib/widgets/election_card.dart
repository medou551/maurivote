// ══════════════════════════════════════════════════════════════════════════════
// WIDGETS RÉUTILISABLES — MauriVote
// ══════════════════════════════════════════════════════════════════════════════

// ── election_card.dart ────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';

/// Card affichant une élection dans la liste d'accueil
class ElectionCard extends StatelessWidget {
  final Election election;
  final VoidCallback? onTap;

  const ElectionCard({super.key, required this.election, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: AppTheme.electionCardDecoration(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Ligne supérieure : type + badge statut ────────────────
              Row(
                children: [
                  _TypeBadge(type: election.type),
                  const Spacer(),
                  _StatusBadge(statut: election.statut),
                ],
              ),
              const SizedBox(height: 10),

              // ── Titre ────────────────────────────────────────────────
              Text(
                election.titreFr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Titre en arabe
              Text(
                election.titreAr,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontFamily: 'Cairo',
                ),
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // ── Ligne inférieure : dates + tour ───────────────────────
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(election.dateOuverture),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '→',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(election.dateFermeture),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (election.nbTours == 2)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Text(
                        'Tour ${election.tourActuel}/${election.nbTours}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              // ── Barre de progression (si en cours) ────────────────────
              if (election.isVotable) ...[
                const SizedBox(height: 12),
                _VoteProgressBar(election: election),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';
}

class _TypeBadge extends StatelessWidget {
  final ElectionType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (type) {
      ElectionType.presidentielle => ('Présidentielle', Icons.account_balance),
      ElectionType.legislative => ('Législative', Icons.gavel),
      ElectionType.municipale => ('Municipale', Icons.location_city),
      ElectionType.regionale => ('Régionale', Icons.map_outlined),
      ElectionType.referendum => ('Référendum', Icons.how_to_vote),
    };
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.primaryGreen),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.primaryGreen,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ElectionStatus statut;
  const _StatusBadge({required this.statut});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (statut) {
      ElectionStatus.enCours => (
          'En cours',
          Colors.green.shade700,
          Colors.green.shade50
        ),
      ElectionStatus.planifiee => (
          'À venir',
          Colors.blue.shade700,
          Colors.blue.shade50
        ),
      ElectionStatus.terminee => (
          'Terminée',
          Colors.grey.shade700,
          Colors.grey.shade100
        ),
      ElectionStatus.annulee => (
          'Annulée',
          Colors.red.shade700,
          Colors.red.shade50
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          if (statut == ElectionStatus.enCours) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _VoteProgressBar extends StatelessWidget {
  final Election election;
  const _VoteProgressBar({required this.election});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    final total =
        election.dateFermeture.difference(election.dateOuverture).inMinutes;
    final elapsed = now.difference(election.dateOuverture).inMinutes;
    final progress = (elapsed / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.primaryGreen,
            ),
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Fermeture : ${election.dateFermeture.hour}h'
          '${election.dateFermeture.minute.toString().padLeft(2, '0')}',
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGET : ConnectivityBanner
// ══════════════════════════════════════════════════════════════════════════════

/// Bannière affichée en haut de l'écran quand l'appareil est hors-ligne
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (ctx, snapshot) {
        final results = snapshot.data ?? [ConnectivityResult.none];
        final isOffline = results.every((r) => r == ConnectivityResult.none);

        if (!isOffline) return const SizedBox.shrink();

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: Colors.orange.shade700,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: const Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mode hors-ligne — Les données peuvent ne pas être à jour',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
