import '../../viewmodels/auth_viewmodel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/elections_viewmodel.dart';

import '../../services/vote_service.dart';

class ElectionDetailScreen extends ConsumerWidget {
  final String electionId;
  const ElectionDetailScreen({super.key, required this.electionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final electionAsync = ref.watch(electionDetailProvider(electionId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: electionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (election) {
          if (election == null) {
            return const Center(child: Text('Élection introuvable'));
          }
          return _ElectionDetailBody(election: election);
        },
      ),
    );
  }
}

class _ElectionDetailBody extends ConsumerWidget {
  final Election election;
  const _ElectionDetailBody({required this.election});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidatesAsync = ref.watch(candidatesProvider(
      CandidateQuery(electionId: election.id, tour: election.tourActuel),
    ));
    final voter = ref.watch(currentVoterProvider).value;

    return CustomScrollView(
      slivers: [
        // â”€â”€ AppBar avec dÃ©gradÃ© â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryGreen, Color(0xFF1A3C20)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _TypePill(type: election.type),
                    const SizedBox(height: 8),
                    Text(election.titreFr,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(election.titreAr,
                        style: const TextStyle(fontSize: 14, color: Colors.white70,
                            fontFamily: 'Cairo'),
                        textDirection: TextDirection.rtl),
                  ],
                ),
              ),
            ),
          ),
        ),

        // â”€â”€ Informations de l'Ã©lection â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _InfoCard(election: election),
          ),
        ),

        // â”€â”€ Bouton Voter â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (election.isVotable && voter != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _VoteButton(election: election, voter: voter),
            ),
          ),

        // â”€â”€ Titre liste candidats â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Row(children: [
              const Icon(Icons.people_outline, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Text(
                'Candidats — Tour ${election.tourActuel}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ]),
          ),
        ),

        // â”€â”€ Liste des candidats â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        candidatesAsync.when(
          loading: () => SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _CandidateShimmer(), childCount: 3,
            ),
          ),
          error: (e, _) => SliverToBoxAdapter(
            child: Center(child: Text('Erreur candidats: $e')),
          ),
          data: (candidates) => SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _CandidateCard(candidate: candidates[i]),
              childCount: candidates.length,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

// â”€â”€ Carte infos Ã©lection â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _InfoCard extends StatelessWidget {
  final Election election;
  const _InfoCard({required this.election});

  @override
  Widget build(BuildContext context) {
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year} '
        '${d.hour.toString().padLeft(2,'0')}h${d.minute.toString().padLeft(2,'0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.electionCardDecoration(),
      child: Column(children: [
        _InfoRow(Icons.calendar_today_outlined, 'Ouverture',  fmt(election.dateOuverture)),
        const Divider(height: 16),
        _InfoRow(Icons.event_busy_outlined,     'Fermeture',  fmt(election.dateFermeture)),
        const Divider(height: 16),
        _InfoRow(Icons.how_to_vote_outlined,    'Tours',
            '${election.nbTours} tour${election.nbTours > 1 ? "s" : ""} — Tour actuel : ${election.tourActuel}'),
        if (election.descriptionFr != null) ...[
          const Divider(height: 16),
          _InfoRow(Icons.info_outline, 'Description', election.descriptionFr!),
        ],
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: AppTheme.primaryGreen),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ]),
    ],
  );
}

// â”€â”€ Bouton Voter â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _VoteButton extends StatelessWidget {
  final Election election;
  final Voter voter;
  const _VoteButton({required this.election, required this.voter});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => context.push('/vote/${election.id}'),
      icon: const Icon(Icons.how_to_vote),
      label: Text('Voter maintenant — Tour ${election.tourActuel}'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.black87,
        elevation: 3,
      ),
    );
  }
}

// â”€â”€ Card candidat â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _CandidateCard extends StatelessWidget {
  final Candidate candidate;
  const _CandidateCard({required this.candidate});

  @override
  Widget build(BuildContext context) {
    final couleur = candidate.couleurParti != null
        ? Color(int.parse(candidate.couleurParti!.replaceAll('#', '0xFF')))
        : AppTheme.primaryGreen;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
        border: Border(left: BorderSide(color: couleur, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          // Photo ou avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: couleur.withOpacity(0.15),
            backgroundImage: candidate.photoUrl != null
                ? CachedNetworkImageProvider(candidate.photoUrl!) : null,
            child: candidate.photoUrl == null
                ? Text(candidate.nom[0], style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: couleur))
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: couleur, borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('N° ${candidate.numeroCandidat}',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(candidate.nom, style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
                ),
              ]),
              if (candidate.parti != null) ...[
                const SizedBox(height: 4),
                Text(candidate.parti!, style: TextStyle(
                    fontSize: 13, color: couleur, fontWeight: FontWeight.w500)),
                if (candidate.partiAr != null)
                  Text(candidate.partiAr!, style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary,
                      fontFamily: 'Cairo'),
                      textDirection: TextDirection.rtl),
              ] else
                const Text('Candidat indépendant',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic)),
            ]),
          ),
          Icon(Icons.chevron_right, color: couleur),
        ]),
      ),
    );
  }
}

class _CandidateShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: Colors.grey.shade200,
    highlightColor: Colors.grey.shade50,
    child: Container(
      height: 80, margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(14)),
    ),
  );
}

class _TypePill extends StatelessWidget {
  final ElectionType type;
  const _TypePill({required this.type});
  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      ElectionType.presidentielle => '\u{1F3DB} Présidentielle',
      ElectionType.legislative    => '\u{2696} Législative',
      ElectionType.municipale     => '\u{1F3D8} Municipale',
      ElectionType.regionale      => '\u{1F5FA} Régionale',
      ElectionType.referendum     => '\u{1F4DC} Référendum',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white24, borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white,
          fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
