import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/vote_viewmodel.dart';
import '../../viewmodels/elections_viewmodel.dart';

class VoteConfirmationScreen extends ConsumerStatefulWidget {
  final String electionId;
  final String? candidateId;

  const VoteConfirmationScreen({
    super.key,
    required this.electionId,
    this.candidateId,
  });

  @override
  ConsumerState<VoteConfirmationScreen> createState() =>
      _VoteConfirmationScreenState();
}

class _VoteConfirmationScreenState
    extends ConsumerState<VoteConfirmationScreen> {
  bool _confirmed = false;
  bool _understood = false;

  @override
  Widget build(BuildContext context) {
    final voteState = ref.watch(voteStateProvider);
    final electionAsync = ref.watch(electionDetailProvider(widget.electionId));
    final candidatesAsync = ref.watch(
      candidatesProvider(CandidateQuery(electionId: widget.electionId)),
    );

    // Écouter le succès du vote → naviguer vers le reçu
    ref.listen(voteStateProvider, (prev, next) {
      if (next.status == VoteStatus.success && next.recuHash != null) {
        context.pushReplacement(
          '/vote/receipt',
          extra: {'recuHash': next.recuHash},
        );
      } else if (next.status == VoteStatus.offline) {
        context.pushReplacement(
          '/vote/receipt',
          extra: {'recuHash': next.recuHash, 'offline': true},
        );
      }
    });

    final election = electionAsync.value;
    final candidates = candidatesAsync.value ?? [];
    final candidate = candidates.firstWhere(
      (c) => c.id == widget.candidateId,
      orElse: () => candidates.isNotEmpty ? candidates.first : _dummyCandidate,
    );

    final couleur = candidate.couleurParti != null
        ? Color(int.parse(candidate.couleurParti!.replaceAll('#', '0xFF')))
        : AppTheme.primaryGreen;

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Confirmation du vote'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: voteState.status == VoteStatus.loading
              ? null
              : () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Titre ──────────────────────────────────────────────────────
            const Text(
              'Vous êtes sur le point de voter',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 6),
            if (election != null)
              Text(
                '${election.titreFr} — Tour ${election.tourActuel}',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 28),

            // ── Carte candidat ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: couleur.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: couleur, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: couleur.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(children: [
                // Numéro + photo
                Stack(alignment: Alignment.bottomRight, children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: couleur.withOpacity(0.15),
                    backgroundImage: candidate.photoUrl != null
                        ? CachedNetworkImageProvider(candidate.photoUrl!)
                        : null,
                    child: candidate.photoUrl == null
                        ? Text(
                            candidate.nom[0],
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              color: couleur,
                            ),
                          )
                        : null,
                  ),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: couleur,
                    child: Text(
                      candidate.numeroCandidat.toString(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                Text(
                  candidate.nom,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  candidate.parti ?? 'Candidat indépendant',
                  style: TextStyle(
                    fontSize: 15,
                    color: couleur,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (candidate.partiAr != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    candidate.partiAr!,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontFamily: 'Cairo'),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                  ),
                ],
              ]),
            ).animate().fadeIn(delay: 200.ms).scale(
                begin: const Offset(0.92, 0.92), end: const Offset(1, 1)),

            const SizedBox(height: 28),

            // ── Cases à cocher de confirmation ─────────────────────────────
            _CheckItem(
              checked: _confirmed,
              label:
                  'Je confirme que ce candidat est bien mon choix définitif.',
              onChanged: (v) => setState(() => _confirmed = v ?? false),
            ),
            const SizedBox(height: 10),
            _CheckItem(
              checked: _understood,
              label:
                  'Je comprends que mon vote est irrévocable et sera chiffré de façon anonyme.',
              onChanged: (v) => setState(() => _understood = v ?? false),
            ),
            const SizedBox(height: 24),

            // ── Avertissement ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ce vote est définitif et ne peut être ni modifié ni annulé après soumission.',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Erreur si présente ─────────────────────────────────────────
            if (voteState.status == VoteStatus.error ||
                voteState.status == VoteStatus.alreadyVoted)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline,
                      color: AppTheme.errorRed, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      voteState.errorMessage ?? 'Erreur inconnue',
                      style: const TextStyle(
                          color: AppTheme.errorRed, fontSize: 13),
                    ),
                  ),
                ]),
              ),

            // ── Bouton soumettre ───────────────────────────────────────────
            ElevatedButton.icon(
              onPressed: (_confirmed && _understood &&
                      voteState.status != VoteStatus.loading)
                  ? () => _soumettre(context, ref, candidate)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: couleur,
                foregroundColor: Colors.white,
                elevation: 4,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: voteState.status == VoteStatus.loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.how_to_vote_rounded, size: 22),
              label: Text(
                voteState.status == VoteStatus.loading
                    ? 'Envoi en cours...'
                    : 'Soumettre mon vote',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            // Annuler
            TextButton(
              onPressed: voteState.status == VoteStatus.loading
                  ? null
                  : () => context.pop(),
              child: const Text('Annuler et revenir',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _soumettre(
      BuildContext context, WidgetRef ref, Candidate candidate) async {
    HapticFeedback.heavyImpact();
    await ref.read(voteStateProvider.notifier).soumettre(
          electionId: widget.electionId,
          candidateId: candidate.id,
          tour: 1,
        );
  }

  static final _dummyCandidate = Candidate(
    id: '', electionId: '', numeroCandidat: 1,
    nom: 'Candidat', tour: 1, isActive: true,
  );
}

class _CheckItem extends StatelessWidget {
  final bool checked;
  final String label;
  final ValueChanged<bool?> onChanged;

  const _CheckItem({
    required this.checked,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!checked),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: checked,
            onChanged: onChanged,
            activeColor: AppTheme.primaryGreen,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
