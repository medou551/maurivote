import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/election_service.dart';
import '../services/realtime_service.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final resultatsViewModelProvider =
    StateNotifierProvider.family<ResultatsNotifier, ResultatsState, String>(
  (ref, electionId) {
    final notifier = ResultatsNotifier(
      electionId: electionId,
      electionService: ref.read(electionServiceProvider),
      realtimeService: ref.read(realtimeServiceProvider),
    );
    ref.onDispose(() => notifier.dispose());
    return notifier;
  },
);

/// Statistiques de participation calculées à la volée
final participationStatsProvider =
    Provider.family<ParticipationStats, List<Resultat>>((_, resultats) {
  if (resultats.isEmpty) return ParticipationStats.empty();
  final totalVotes = resultats.fold<int>(0, (s, r) => s + r.nbVotes);
  final leader = resultats.reduce((a, b) => a.nbVotes > b.nbVotes ? a : b);
  final secondPlace = resultats.length > 1
      ? resultats.where((r) => r.candidateId != leader.candidateId)
            .reduce((a, b) => a.nbVotes > b.nbVotes ? a : b)
      : null;
  return ParticipationStats(
    totalVotes: totalVotes,
    leaderId: leader.candidateId,
    leaderPct: leader.pourcentage,
    secondId: secondPlace?.candidateId,
    secondPct: secondPlace?.pourcentage ?? 0,
    hasAbsoluteMajority: leader.pourcentage > 50,
    nbCandidates: resultats.length,
  );
});

// ── État ──────────────────────────────────────────────────────────────────────
enum ResultatsStatus { loading, live, snapshot, error }

class ResultatsState {
  final ResultatsStatus status;
  final List<Resultat>  resultats;
  final String?         errorMessage;
  final bool            isRealtime;
  final DateTime?       lastUpdated;
  final int             updateCount;   // Nb de mises à jour reçues

  const ResultatsState({
    required this.status,
    this.resultats = const [],
    this.errorMessage,
    this.isRealtime = false,
    this.lastUpdated,
    this.updateCount = 0,
  });

  ResultatsState copyWith({
    ResultatsStatus? status,
    List<Resultat>?  resultats,
    String?          errorMessage,
    bool?            isRealtime,
    DateTime?        lastUpdated,
    int?             updateCount,
  }) => ResultatsState(
    status:       status       ?? this.status,
    resultats:    resultats    ?? this.resultats,
    errorMessage: errorMessage ?? this.errorMessage,
    isRealtime:   isRealtime   ?? this.isRealtime,
    lastUpdated:  lastUpdated  ?? this.lastUpdated,
    updateCount:  updateCount  ?? this.updateCount,
  );

  factory ResultatsState.initial() =>
      const ResultatsState(status: ResultatsStatus.loading);

  bool get hasData => resultats.isNotEmpty;
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class ResultatsNotifier extends StateNotifier<ResultatsState> {
  final String           electionId;
  final ElectionService  electionService;
  final RealtimeService  realtimeService;
  StreamSubscription<List<Resultat>>? _sub;

  ResultatsNotifier({
    required this.electionId,
    required this.electionService,
    required this.realtimeService,
  }) : super(ResultatsState.initial()) {
    _init();
  }

  Future<void> _init() async {
    // 1. Chargement initial depuis la BDD (snapshot)
    await _fetchSnapshot();
    // 2. Abonnement WebSocket temps réel
    _subscribeRealtime();
  }

  Future<void> _fetchSnapshot() async {
    try {
      final data = await electionService.getResultats(electionId: electionId);
      state = state.copyWith(
        status:      ResultatsStatus.snapshot,
        resultats:   data,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      debugPrint('ResultatsNotifier._fetchSnapshot error: $e');
      state = state.copyWith(
        status:       ResultatsStatus.error,
        errorMessage: 'Impossible de charger les résultats. Réessayez.',
      );
    }
  }

  void _subscribeRealtime() {
    realtimeService.subscribeToResultats(electionId);
    _sub = realtimeService.resultatsStream.listen(
      (resultats) {
        state = state.copyWith(
          status:      ResultatsStatus.live,
          resultats:   resultats,
          isRealtime:  true,
          lastUpdated: DateTime.now(),
          updateCount: state.updateCount + 1,
        );
        debugPrint(
            'Realtime update #${state.updateCount} — ${resultats.length} candidats');
      },
      onError: (e) {
        debugPrint('Realtime error: $e');
        // Garder les données existantes, signaler la perte du temps réel
        state = state.copyWith(isRealtime: false);
      },
    );
  }

  /// Rafraîchissement manuel
  Future<void> refresh() async {
    state = state.copyWith(status: ResultatsStatus.loading);
    await _fetchSnapshot();
  }

  void dispose() {
    _sub?.cancel();
    realtimeService.unsubscribe();
    super.dispose();
  }
}

// ── Statistiques de participation ─────────────────────────────────────────────
class ParticipationStats {
  final int    totalVotes;
  final String leaderId;
  final double leaderPct;
  final String? secondId;
  final double  secondPct;
  final bool    hasAbsoluteMajority;
  final int     nbCandidates;

  const ParticipationStats({
    required this.totalVotes,
    required this.leaderId,
    required this.leaderPct,
    this.secondId,
    required this.secondPct,
    required this.hasAbsoluteMajority,
    required this.nbCandidates,
  });

  factory ParticipationStats.empty() => const ParticipationStats(
    totalVotes: 0, leaderId: '', leaderPct: 0,
    secondPct: 0, hasAbsoluteMajority: false, nbCandidates: 0,
  );

  /// Gap entre le 1er et le 2e (points de %)
  double get gap => leaderPct - secondPct;
  bool get get isClose => gap < 5.0;
}
