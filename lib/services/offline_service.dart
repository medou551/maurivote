import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/constants.dart';
import 'vote_service.dart';

/// Service de gestion offline — Hive DB + synchronisation différée
class OfflineService {
  final _boxPending = Hive.box(AppConstants.boxVotesPending);
  final _voteService = VoteService();

  // ─────────────────────────────────────────────────────────────────────────
  // VOTE EN ATTENTE (queue offline)
  // ─────────────────────────────────────────────────────────────────────────

  /// Enregistrer un vote localement quand il n'y a pas de réseau
  Future<void> savePendingVote({
    required String nni,
    required String electionId,
    required String candidateId,
    required int tour,
    required String recuHash,
  }) async {
    final key = 'vote_${electionId}_${tour}_${DateTime.now().millisecondsSinceEpoch}';
    await _boxPending.put(key, {
      'nni':          nni,
      'election_id':  electionId,
      'candidate_id': candidateId,
      'tour':         tour,
      'recu_hash':    recuHash,
      'saved_at':     DateTime.now().toIso8601String(),
      'synced':       false,
    });
    debugPrint('OfflineService: Vote mis en attente — clé $key');
  }

  /// Nombre de votes en attente de synchronisation
  int get pendingVotesCount =>
      _boxPending.values.where((v) => v['synced'] == false).length;

  // ─────────────────────────────────────────────────────────────────────────
  // SYNCHRONISATION — Dès que le réseau revient
  // ─────────────────────────────────────────────────────────────────────────

  /// Écouter le retour de connexion et synchroniser automatiquement
  void startAutoSync() {
    Connectivity().onConnectivityChanged.listen((results) {
      final hasNetwork = results.any((r) => r != ConnectivityResult.none);
      if (hasNetwork && pendingVotesCount > 0) {
        debugPrint('OfflineService: Réseau rétabli — sync de $pendingVotesCount votes');
        syncPendingVotes();
      }
    });
  }

  /// Synchroniser tous les votes en attente
  Future<SyncResult> syncPendingVotes() async {
    final pending = _boxPending.toMap().entries
        .where((e) => e.value['synced'] == false)
        .toList();

    if (pending.isEmpty) return const SyncResult(synced: 0, failed: 0);

    int synced = 0;
    int failed = 0;

    for (final entry in pending) {
      final data = Map<String, dynamic>.from(entry.value);
      try {
        final result = await _voteService.soumettreVote(
          nni:         data['nni'],
          electionId:  data['election_id'],
          candidateId: data['candidate_id'],
          tour:        data['tour'],
        );

        if (result.isSuccess || result.errorType == VoteErrorType.alreadyVoted) {
          // Marquer comme synchronisé (succès ou déjà voté = OK)
          await _boxPending.put(entry.key, {
            ...data,
            'synced': true,
            'synced_at': DateTime.now().toIso8601String(),
          });
          synced++;
        } else {
          failed++;
          debugPrint('OfflineService: Échec sync vote ${entry.key}');
        }
      } catch (e) {
        failed++;
        debugPrint('OfflineService: Exception sync ${entry.key} — $e');
      }
    }

    debugPrint('OfflineService: Sync terminée — $synced réussis, $failed échoués');
    return SyncResult(synced: synced, failed: failed);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NETTOYAGE
  // ─────────────────────────────────────────────────────────────────────────

  /// Supprimer les votes déjà synchronisés (garder seulement les 30 derniers jours)
  Future<void> cleanup() async {
    final threshold = DateTime.now().subtract(const Duration(days: 30));
    final toDelete = <dynamic>[];

    for (final entry in _boxPending.toMap().entries) {
      final data = Map<String, dynamic>.from(entry.value);
      if (data['synced'] == true) {
        final syncedAt = DateTime.tryParse(data['synced_at'] ?? '');
        if (syncedAt != null && syncedAt.isBefore(threshold)) {
          toDelete.add(entry.key);
        }
      }
    }

    await _boxPending.deleteAll(toDelete);
    debugPrint('OfflineService: Nettoyage — ${toDelete.length} entrées supprimées');
  }
}

class SyncResult {
  final int synced;
  final int failed;
  const SyncResult({required this.synced, required this.failed});
  bool get hasFailures => failed > 0;
  int get total => synced + failed;
}
  // Precharger elections pour mode offline
  Future<void> preloadElections(List<Map<String, dynamic>> elections) async {
    final box = Hive.box(AppConstants.boxElections);
    for (final e in elections) {
      await box.put(e['id'], e);
    }
    debugPrint('OfflineService: \ elections mises en cache');
  }

  // Recuperer elections depuis cache
  List<Map<String, dynamic>> getCachedElections() {
    final box = Hive.box(AppConstants.boxElections);
    return box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // Verifier connectivite
  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }
