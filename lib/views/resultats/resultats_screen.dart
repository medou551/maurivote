import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/elections_viewmodel.dart';
import '../../services/realtime_service.dart';

// ── Provider Realtime pour les résultats ───────────────────────────────────────
final realtimeServiceProvider = Provider<RealtimeService>((_) => RealtimeService());

final realtimeResultatsProvider =
    StreamProvider.family<List<Resultat>, String>((ref, electionId) {
  final svc = ref.watch(realtimeServiceProvider);
  svc.subscribeToResultats(electionId);
  ref.onDispose(() => svc.unsubscribe());
  return svc.resultatsStream;
});

class ResultatsScreen extends ConsumerWidget {
  final String? electionId;
  const ResultatsScreen({super.key, this.electionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Si pas d'élection sélectionnée → liste des élections terminées
    if (electionId == null) return _AllResultatsScreen();

    final electionAsync = ref.watch(electionDetailProvider(electionId!));
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Résultats'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(resultatsProvider(
                ResultatQuery(electionId: electionId!))),
          ),
        ],
      ),
      body: electionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (e) => e == null
            ? const Center(child: Text('Élection introuvable'))
            : _ResultatsBody(election: e),
      ),
    );
  }
}

// ── Corps des résultats ────────────────────────────────────────────────────────
class _ResultatsBody extends ConsumerWidget {
  final Election election;
  const _ResultatsBody({required this.election});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Résultats statiques (snapshot BDD)
    final staticAsync = ref.watch(resultatsProvider(
      ResultatQuery(electionId: election.id, tour: election.tourActuel)));
    // Résultats temps réel (WebSocket)
    final realtimeAsync = ref.watch(realtimeResultatsProvider(election.id));

    // Utiliser les temps réel si disponibles, sinon statiques
    final resultats = realtimeAsync.valueOrNull ?? staticAsync.valueOrNull ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Bandeau temps réel ─────────────────────────────────────────────
        _RealtimeBadge(isLive: election.isActive),
        const SizedBox(height: 16),

        // ── En-tête élection ──────────────────────────────────────────────
        Text(election.titreFr,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text('Tour ${election.tourActuel}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 20),

        if (resultats.isEmpty)
          _EmptyResultats(election: election)
        else ...[
          // ── Graphique circulaire ─────────────────────────────────────────
          _PieChartSection(resultats: resultats, electionId: election.id),
          const SizedBox(height: 24),

          // ── Barres de progression ─────────────────────────────────────────
          const Text('Résultats détaillés',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...resultats.map((r) => _ResultatBar(resultat: r, electionId: election.id)),
        ],
      ]),
    );
  }
}

// ── Badge Temps Réel ──────────────────────────────────────────────────────────
class _RealtimeBadge extends StatelessWidget {
  final bool isLive;
  const _RealtimeBadge({required this.isLive});

  @override
  Widget build(BuildContext context) {
    if (!isLive) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.shade50, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _PulsingDot(),
        const SizedBox(width: 6),
        const Text('Mise à jour en direct',
            style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => Container(
      width: 8, height: 8,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.4 + _ctrl.value * 0.6),
        shape: BoxShape.circle,
      ),
    ),
  );
}

// ── Graphique camembert ────────────────────────────────────────────────────────
class _PieChartSection extends ConsumerWidget {
  final List<Resultat> resultats;
  final String electionId;
  const _PieChartSection({required this.resultats, required this.electionId});

  static const _colors = [
    Color(0xFF1565C0), Color(0xFF1B5E20), Color(0xFFE65100),
    Color(0xFF4A148C), Color(0xFF00695C), Color(0xFFBF360C),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidatesAsync = ref.watch(candidatesProvider(
      CandidateQuery(electionId: electionId)));
    final candidates = candidatesAsync.valueOrNull ?? [];

    final total = resultats.fold<int>(0, (s, r) => s + r.nbVotes);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.electionCardDecoration(),
      child: Column(children: [
        const Text('Répartition des votes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: resultats.asMap().entries.map((e) {
                final i = e.key;
                final r = e.value;
                return PieChartSectionData(
                  value: r.pourcentage,
                  color: _colors[i % _colors.length],
                  title: '${r.pourcentage.toStringAsFixed(1)}%',
                  radius: 80,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                      color: Colors.white),
                );
              }).toList(),
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Total votes
        Text('Total : ${_formatNumber(total)} voix exprimées',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ]),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ── Barre de résultat candidat ────────────────────────────────────────────────
class _ResultatBar extends ConsumerWidget {
  final Resultat resultat;
  final String electionId;
  const _ResultatBar({required this.resultat, required this.electionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidatesAsync = ref.watch(candidatesProvider(
      CandidateQuery(electionId: electionId)));
    final candidate = candidatesAsync.valueOrNull?.firstWhere(
      (c) => c.id == resultat.candidateId,
      orElse: () => Candidate(id: '', electionId: '', numeroCandidat: 0,
          nom: 'Candidat ${resultat.candidateId.substring(0, 6)}',
          tour: 1, isActive: true),
    );

    final progress = resultat.pourcentage / 100;
    final couleur = candidate?.couleurParti != null
        ? Color(int.parse(candidate!.couleurParti!.replaceAll('#', '0xFF')))
        : AppTheme.primaryGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.electionCardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
            child: Center(child: Text(
              candidate?.numeroCandidat.toString() ?? '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            )),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(candidate?.nom ?? 'Inconnu',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
          Text('${resultat.pourcentage.toStringAsFixed(1)}%',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: couleur)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(couleur),
              minHeight: 12,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text('${_fmt(resultat.nbVotes)} voix',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ]),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ── Résultats vides ───────────────────────────────────────────────────────────
class _EmptyResultats extends StatelessWidget {
  final Election election;
  const _EmptyResultats({required this.election});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(children: [
        const Icon(Icons.bar_chart_outlined, size: 64, color: AppTheme.textSecondary),
        const SizedBox(height: 16),
        Text(
          election.isActive
              ? 'Les résultats seront disponibles à la fermeture des bureaux de vote'
              : 'Résultats en cours de traitement par la CENI',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
      ]),
    ),
  );
}

// ── Liste toutes les élections ────────────────────────────────────────────────
class _AllResultatsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final electionsAsync = ref.watch(electionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Résultats'),
          backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
      body: electionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (elections) {
          final relevant = elections
              .where((e) => e.statut == ElectionStatus.terminee || e.isActive)
              .toList();
          if (relevant.isEmpty) {
            return const Center(child: Text('Aucun résultat disponible'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: relevant.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(relevant[i].titreFr, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(relevant[i].typeLabel),
              leading: const Icon(Icons.bar_chart, color: AppTheme.primaryGreen),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ResultatsScreen(electionId: relevant[i].id))),
            ),
          );
        },
      ),
    );
  }
}
