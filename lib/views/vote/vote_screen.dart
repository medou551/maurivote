import '../../viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/elections_viewmodel.dart';
import '../../viewmodels/vote_viewmodel.dart';
import '../../services/vote_service.dart';

final voteLoadingProvider =
    NotifierProvider<VoteLoadingNotifier, bool>(VoteLoadingNotifier.new);

class VoteLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setLoading(bool v) => state = v;
}

class VoteScreen extends ConsumerWidget {
  final String electionId;
  const VoteScreen({super.key, required this.electionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final electionAsync = ref.watch(electionDetailProvider(electionId));
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Voter'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
            icon: const Icon(Icons.close), onPressed: () => context.pop()),
      ),
      body: electionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (election) => election == null
            ? const Center(child: Text('Élection introuvable'))
            : _VoteBody(election: election),
      ),
    );
  }
}

class _VoteBody extends ConsumerWidget {
  final Election election;
  const _VoteBody({required this.election});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidatesAsync = ref.watch(candidatesProvider(
      CandidateQuery(electionId: election.id, tour: election.tourActuel),
    ));
    final selected = ref.watch(selectedCandidateProvider);
    final isLoading = ref.watch(voteLoadingProvider);

    return Column(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        color: AppTheme.lightGreen.withOpacity(0.4),
        child: Text('${election.titreFr} — Tour ${election.tourActuel}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      Expanded(
        child: candidatesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e')),
          data: (candidates) => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: candidates.length,
            itemBuilder: (_, i) => _CandidateCard(
              candidate: candidates[i],
              isSelected: selected?.id == candidates[i].id,
              onTap: () {
                HapticFeedback.selectionClick();
                ref
                    .read(selectedCandidateProvider.notifier)
                    .select(candidates[i]);
              },
            ),
          ),
        ),
      ),
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12)
        ]),
        child: ElevatedButton.icon(
          onPressed: selected == null || isLoading
              ? null
              : () => _voter(context, ref, election, selected),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                selected != null ? AppTheme.primaryGold : Colors.grey.shade300,
            foregroundColor: Colors.black87,
          ),
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.how_to_vote),
          label: Text(selected == null
              ? 'Sélectionnez un candidat'
              : 'Confirmer mon vote'),
        ),
      ),
    ]);
  }

  Future<void> _voter(BuildContext ctx, WidgetRef ref, Election election,
      Candidate selected) async {
    ref.read(voteLoadingProvider.notifier).setLoading(true);
    try {
      final nni = await ref.read(authServiceProvider).getCurrentNni();
      if (nni == null || !ctx.mounted) return;
      final result = await VoteService().soumettreVote(
        nni: nni,
        electionId: election.id,
        candidateId: selected.id,
        tour: election.tourActuel,
      );
      if (!ctx.mounted) return;
      if (result.isSuccess) {
        ctx.pushReplacement('/vote/receipt',
            extra: {'recuHash': result.recuHash});
      } else {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text(result.errorType == VoteErrorType.alreadyVoted
              ? 'Vous avez déjà voté'
              : 'Erreur lors du vote'),
          backgroundColor: AppTheme.errorRed,
        ));
      }
    } finally {
      ref.read(voteLoadingProvider.notifier).setLoading(false);
    }
  }
}

class _CandidateCard extends StatelessWidget {
  final Candidate candidate;
  final bool isSelected;
  final VoidCallback onTap;
  const _CandidateCard(
      {required this.candidate, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final couleur = candidate.couleurParti != null
        ? Color(int.parse(candidate.couleurParti!.replaceAll('#', '0xFF')))
        : AppTheme.primaryGreen;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? couleur.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isSelected ? couleur : Colors.grey.shade200,
              width: isSelected ? 2.5 : 1),
        ),
        child: Row(children: [
          CircleAvatar(
              radius: 20,
              backgroundColor: isSelected ? couleur : couleur.withOpacity(0.1),
              child: Text(candidate.numeroCandidat.toString(),
                  style: TextStyle(
                      color: isSelected ? Colors.white : couleur,
                      fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(candidate.nom,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(candidate.parti ?? 'Indépendant',
                    style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? couleur : AppTheme.textSecondary)),
              ])),
          Radio<String>(
              value: candidate.id,
              groupValue: isSelected ? candidate.id : null,
              onChanged: (_) => onTap(),
              activeColor: couleur),
        ]),
      ),
    );
  }
}
