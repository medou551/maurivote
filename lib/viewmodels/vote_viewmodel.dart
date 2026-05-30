import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/models.dart';
import '../services/vote_service.dart';
import '../services/auth_service.dart';
import '../services/offline_service.dart';
import 'auth_viewmodel.dart';

// ── Providers ─────────────────────────────────────────────────────────────────
final voteServiceProvider    = Provider<VoteService>((_) => VoteService());
final offlineServiceProvider = Provider<OfflineService>((_) => OfflineService());

class SelectedCandidateNotifier extends Notifier<Candidate?> {
  @override
  Candidate? build() => null;
  void select(Candidate? c) => state = c;
}

final selectedCandidateProvider =
    NotifierProvider<SelectedCandidateNotifier, Candidate?>(
  SelectedCandidateNotifier.new,
);

final voteStateProvider =
    NotifierProvider<VoteNotifier, VoteState>(VoteNotifier.new);

/// Vérifie si l'électeur a déjà voté pour une élection donnée
final hasVotedProvider =
    FutureProvider.family<bool, HasVotedQuery>((ref, query) async {
  final nni = await ref.read(authServiceProvider).getCurrentNni();
  if (nni == null) return false;
  return ref.read(voteServiceProvider).aDejaVote(
    nni: nni, electionId: query.electionId, tour: query.tour,
  );
});

// ── État du vote ───────────────────────────────────────────────────────────────
enum VoteStatus { idle, loading, success, alreadyVoted, electionClosed, offline, error }

class VoteState {
  final VoteStatus status;
  final String?    recuHash;
  final String?    errorMessage;
  final bool       isOfflineQueued;

  const VoteState({
    required this.status,
    this.recuHash,
    this.errorMessage,
    this.isOfflineQueued = false,
  });

  VoteState copyWith({
    VoteStatus? status,
    String?     recuHash,
    String?     errorMessage,
    bool?       isOfflineQueued,
  }) => VoteState(
    status:          status          ?? this.status,
    recuHash:        recuHash        ?? this.recuHash,
    errorMessage:    errorMessage    ?? this.errorMessage,
    isOfflineQueued: isOfflineQueued ?? this.isOfflineQueued,
  );

  factory VoteState.initial() => const VoteState(status: VoteStatus.idle);
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class VoteNotifier extends Notifier<VoteState> {
  late final VoteService          _voteService;
  late final SupabaseAuthService  _auth;
  late final OfflineService       _offline;

  @override
  VoteState build() {
    _voteService = ref.read(voteServiceProvider);
    _auth        = ref.read(authServiceProvider);
    _offline     = ref.read(offlineServiceProvider);
    return VoteState.initial();
  }

  Future<void> soumettre({
    required String electionId,
    required String candidateId,
    required int    tour,
  }) async {
    state = state.copyWith(status: VoteStatus.loading);

    final nni = await _auth.getCurrentNni();
    if (nni == null) {
      state = state.copyWith(
        status:       VoteStatus.error,
        errorMessage: 'Session expirée. Reconnectez-vous.',
      );
      return;
    }

    final connectivity = await Connectivity().checkConnectivity();
    final hasNet = connectivity.any((r) => r != ConnectivityResult.none);

    if (!hasNet) {
      final recuHash = DateTime.now().millisecondsSinceEpoch.toString();
      await _offline.savePendingVote(
        nni: nni, electionId: electionId,
        candidateId: candidateId, tour: tour, recuHash: recuHash,
      );
      state = state.copyWith(
        status:          VoteStatus.offline,
        recuHash:        recuHash,
        isOfflineQueued: true,
        errorMessage:
            'Pas de connexion Internet. Votre vote sera envoyé automatiquement '
            'dès que la connexion sera rétablie.',
      );
      return;
    }

    final result = await _voteService.soumettreVote(
      nni: nni, electionId: electionId,
      candidateId: candidateId, tour: tour,
    );

    if (result.isSuccess) {
      state = state.copyWith(status: VoteStatus.success, recuHash: result.recuHash);
    } else {
      state = state.copyWith(
        status:       _mapError(result.errorType),
        errorMessage: _errorMsg(result.errorType),
      );
    }
  }

  Future<bool> verifierRecu(String hash) => _voteService.verifierRecu(hash);

  void reset() => state = VoteState.initial();

  VoteStatus _mapError(VoteErrorType? t) => switch (t) {
    VoteErrorType.alreadyVoted   => VoteStatus.alreadyVoted,
    VoteErrorType.electionClosed => VoteStatus.electionClosed,
    VoteErrorType.sessionExpired => VoteStatus.error,
    _                            => VoteStatus.error,
  };

  String _errorMsg(VoteErrorType? t) => switch (t) {
    VoteErrorType.alreadyVoted   => 'Vous avez déjà voté pour cette élection.',
    VoteErrorType.electionClosed => 'La période de vote est terminée.',
    VoteErrorType.sessionExpired => 'Session expirée. Reconnectez-vous.',
    _                            => 'Erreur lors de la soumission. Réessayez.',
  };
}

// ── Query objects ─────────────────────────────────────────────────────────────
class HasVotedQuery {
  final String electionId;
  final int    tour;
  const HasVotedQuery({required this.electionId, this.tour = 1});

  @override
  bool operator ==(Object other) =>
      other is HasVotedQuery && other.electionId == electionId && other.tour == tour;
  @override
  int get hashCode => Object.hash(electionId, tour);
}
