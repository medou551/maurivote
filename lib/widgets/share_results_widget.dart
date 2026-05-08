import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../utils/app_theme.dart';
import '../../models/models.dart';

// ── Widget partage résultats ─────────────────────────────────────────────────
class ShareResultsButton extends StatelessWidget {
  final Election election;
  final List<Resultat> resultats;
  const ShareResultsButton({
    super.key, required this.election, required this.resultats});

  Future<void> _share(BuildContext context) async {
    if (resultats.isEmpty) return;

    final sorted = List<Resultat>.from(resultats)
      ..sort((a, b) => b.nbVotes.compareTo(a.nbVotes));

    final buffer = StringBuffer();
    buffer.writeln('🗳️ Résultats — ${election.titreFr}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');

    for (var i = 0; i < sorted.length; i++) {
      final r    = sorted[i];
      final medal = i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : '  ';
      buffer.writeln('$medal ${r.candidatNom ?? 'Candidat ${i+1}'}');
      buffer.writeln('   ${r.pourcentage.toStringAsFixed(1)}% — ${r.nbVotes} voix');
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('🇲🇷 MauriVote — Vote électronique sécurisé');

    await Share.share(buffer.toString(),
        subject: 'Résultats ${election.titreFr}');
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _share(context),
      icon: const Icon(Icons.share_outlined),
      tooltip: 'Partager les résultats',
      color: Colors.white,
    );
  }
}

// ── Bannière résultats officiels ─────────────────────────────────────────────
class OfficialResultsBanner extends StatelessWidget {
  final bool isOfficial;
  const OfficialResultsBanner({super.key, required this.isOfficial});

  @override
  Widget build(BuildContext context) {
    if (!isOfficial) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: AppTheme.primaryGold.withOpacity(0.15),
      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.verified, color: AppTheme.primaryGold, size: 16),
        SizedBox(width: 8),
        Text('Résultats officiels validés par la CENI',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                color: AppTheme.primaryGold)),
      ]),
    );
  }
}

// ── Carte résultat wilaya ────────────────────────────────────────────────────
class ParticipationCard extends StatelessWidget {
  final String wilaya;
  final double taux;
  final int nbVotes;
  const ParticipationCard({
    super.key, required this.wilaya,
    required this.taux, required this.nbVotes});

  @override
  Widget build(BuildContext context) {
    final color = taux >= 60
        ? AppTheme.primaryGreen
        : taux >= 40
            ? Colors.orange
            : AppTheme.errorRed;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(wilaya, style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13)),
          Text('$nbVotes voix',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${taux.toStringAsFixed(1)}%',
              style: TextStyle(fontWeight: FontWeight.bold,
                  color: color, fontSize: 16)),
          const Text('participation',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        ]),
        const SizedBox(width: 8),
        SizedBox(width: 8, height: 40,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: taux / 100,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          )),
      ]),
    );
  }
}
