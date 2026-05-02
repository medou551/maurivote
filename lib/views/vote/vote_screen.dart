import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/elections_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../services/vote_service.dart';

// ── Provider du vote en cours ──────────────────────────────────────────────────
final selectedCandidateProvider = StateProvider<Candidate?>(_ => null);
final voteLoadingProvider       = StateProvider<bool>(_ => false);

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
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: electionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
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
    final selected  = ref.watch(selectedCandidateProvider);
    final isLoading = ref.watch(voteLoadingProvider);

    return Column(
      children: [
        // ── Bandeau info élection ────────────────────────────────────────────
        _ElectionBanner(election: election),

        // ── Liste candidats ──────────────────────────────────────────────────
        Expanded(
          child: candidatesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur chargement candidats: $e')),
            data: (candidates) => ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: candidates.length,
              itemBuilder: (_, i) => _CandidateVoteCard(
                candidate: candidates[i],
                isSelected: selected?.id == candidates[i].id,
                onTap: () => ref.read(selectedCandidateProvider.notifier).state = candidates[i],
              ).animate().fadeIn(delay: (i * 80).ms).slideX(begin: 0.15, end: 0),
            ),
          ),
        ),

        // ── Bouton confirmer fixe en bas ─────────────────────────────────────
        _ConfirmButton(
          election: election,
          selected: selected,
          isLoading: isLoading,
        ),
      ],
    );
  }
}

// ── Bandeau supérieur ──────────────────────────────────────────────────────────
class _ElectionBanner extends StatelessWidget {
  final Election election;
  const _ElectionBanner({required this.election});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.lightGreen.withOpacity(0.4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(election.titreFr,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 2),
        Row(children: [
          const Icon(Icons.info_outline, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text('Tour ${election.tourActuel} — Sélectionnez un candidat',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ]),
      ]),
    );
  }
}

// ── Card candidat avec radio ────────────────────────────────────────────────────
class _CandidateVoteCard extends StatelessWidget {
  final Candidate candidate;
  final bool isSelected;
  final VoidCallback onTap;

  const _CandidateVoteCard({
    required this.candidate, required this.isSelected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final couleur = candidate.couleurParti != null
        ? Color(int.parse(candidate.couleurParti!.replaceAll('#', '0xFF')))
        : AppTheme.primaryGreen;

    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? couleur.withOpacity(0.08) : AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? couleur : Colors.grey.shade200,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: couleur.withOpacity(0.2),
                  blurRadius: 12, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withOpacity(0.04),
                  blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          // Numéro candidat
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isSelected ? couleur : couleur.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(candidate.numeroCandidat.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16,
                    color: isSelected ? Colors.white : couleur,
                  )),
            ),
          ),
          const SizedBox(width: 12),

          // Photo
          CircleAvatar(
            radius: 26,
            backgroundColor: couleur.withOpacity(0.1),
            backgroundImage: candidate.photoUrl != null
                ? CachedNetworkImageProvider(candidate.photoUrl!) : null,
            child: candidate.photoUrl == null
                ? Text(candidate.nom[0],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: couleur))
                : null,
          ),
          const SizedBox(width: 12),

          // Infos
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(candidate.nom,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                candidate.parti ?? 'Indépendant',
                style: TextStyle(fontSize: 12,
                    color: isSelected ? couleur : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
              ),
              if (candidate.partiAr != null)
                Text(candidate.partiAr!,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary,
                        fontFamily: 'Cairo'),
                    textDirection: TextDirection.rtl),
            ]),
          ),

          // Radio
          Radio<String>(
            value: candidate.id,
            groupValue: isSelected ? candidate.id : null,
            onChanged: (_) { HapticFeedback.selectionClick(); onTap(); },
            activeColor: couleur,
          ),
        ]),
      ),
    );
  }
}

// ── Bouton Confirmer ───────────────────────────────────────────────────────────
class _ConfirmButton extends ConsumerWidget {
  final Election election;
  final Candidate? selected;
  final bool isLoading;

  const _ConfirmButton({
    required this.election, required this.selected, required this.isLoading,
  });

  Future<void> _confirmer(BuildContext context, WidgetRef ref) async {
    if (selected == null) return;

    // Dialogue de confirmation double
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ConfirmDialog(candidate: selected!, election: election),
    );
    if (confirmed != true || !context.mounted) return;

    // Soumettre le vote
    ref.read(voteLoadingProvider.notifier).state = true;
    try {
      final nni = await ref.read(authServiceProvider).getCurrentNni();
      if (nni == null) { _showError(context, 'Session expirée. Reconnectez-vous.'); return; }

      final result = await VoteService().soumettrVote(
        nni: nni,
        electionId: election.id,
        candidateId: selected!.id,
        tour: election.tourActuel,
      );

      if (!context.mounted) return;

      if (result.isSuccess) {
        HapticFeedback.heavyImpact();
        context.pushReplacement('/vote/receipt',
            extra: {'recuHash': result.recuHash});
      } else {
        _showError(context, _errorMessage(result.errorType));
      }
    } finally {
      if (context.mounted) ref.read(voteLoadingProvider.notifier).state = false;
    }
  }

  void _showError(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: AppTheme.errorRed,
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _errorMessage(VoteErrorType? type) => switch (type) {
    VoteErrorType.alreadyVoted   => 'Vous avez déjà voté pour cette élection.',
    VoteErrorType.electionClosed => 'La période de vote est terminée.',
    VoteErrorType.sessionExpired => 'Session expirée. Reconnectez-vous.',
    _                            => 'Erreur lors du vote. Réessayez.',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08),
            blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: ElevatedButton.icon(
        onPressed: selected == null || isLoading ? null : () => _confirmer(context, ref),
        style: ElevatedButton.styleFrom(
          backgroundColor: selected != null ? AppTheme.primaryGold : Colors.grey.shade300,
          foregroundColor: Colors.black87,
          elevation: selected != null ? 3 : 0,
        ),
        icon: isLoading
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54))
            : const Icon(Icons.how_to_vote),
        label: Text(selected == null ? 'Sélectionnez un candidat' : 'Confirmer mon vote'),
      ),
    );
  }
}

// ── Dialogue de confirmation ────────────────────────────────────────────────────
class _ConfirmDialog extends StatelessWidget {
  final Candidate candidate;
  final Election election;
  const _ConfirmDialog({required this.candidate, required this.election});

  @override
  Widget build(BuildContext context) {
    final couleur = candidate.couleurParti != null
        ? Color(int.parse(candidate.couleurParti!.replaceAll('#', '0xFF')))
        : AppTheme.primaryGreen;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Confirmer votre vote',
          style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Vous êtes sur le point de voter pour :',
            style: TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: couleur.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: couleur.withOpacity(0.4)),
          ),
          child: Row(children: [
            CircleAvatar(
              backgroundColor: couleur,
              child: Text(candidate.numeroCandidat.toString(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(candidate.nom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(candidate.parti ?? 'Indépendant',
                  style: TextStyle(color: couleur, fontSize: 13)),
            ])),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8)),
          child: const Row(children: [
            Icon(Icons.warning_amber_outlined, color: Colors.orange, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text('Ce vote est définitif et ne peut pas être annulé.',
                style: TextStyle(fontSize: 12, color: Colors.orange))),
          ]),
        ),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
          child: const Text('Oui, je confirme'),
        ),
      ],
    );
  }
}
