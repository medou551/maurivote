import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/models.dart';

/// Service Supabase Realtime — Résultats en temps réel via WebSocket
class RealtimeService {
  RealtimeChannel? _channel;
  final _resultatsController = StreamController<List<Resultat>>.broadcast();

  /// Stream de résultats mis à jour en temps réel
  Stream<List<Resultat>> get resultatsStream => _resultatsController.stream;

  // ─────────────────────────────────────────────────────────────────────────
  // ABONNEMENT — Écoute les changements sur resultats pour une élection
  // ─────────────────────────────────────────────────────────────────────────
  void subscribeToResultats(String electionId) {
    // Fermer l'abonnement précédent si existant
    unsubscribe();

    debugPrint('RealtimeService: Abonnement résultats élection $electionId');

    _channel = supabase
        .channel('resultats_$electionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'resultats',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'election_id',
            value: electionId,
          ),
          callback: (payload) async {
            debugPrint('Realtime: Changement détecté → ${payload.eventType}');
            // Re-fetch les résultats complets à chaque changement
            final resultats = await _fetchResultats(electionId);
            if (!_resultatsController.isClosed) {
              _resultatsController.add(resultats);
            }
          },
        )
        .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            debugPrint('Realtime: Connecté au canal résultats_$electionId');
          } else if (status == RealtimeSubscribeStatus.channelError) {
            debugPrint('Realtime: Erreur canal — $error');
          }
        });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BROADCAST — Écoute les votes en temps réel (comptage live)
  // ─────────────────────────────────────────────────────────────────────────
  void subscribeToVotesCount(String electionId,
      {required Function(int) onCount}) {
    _channel = supabase
        .channel('votes_count_$electionId')
        .onBroadcast(
          event: 'vote_count_update',
          callback: (payload) {
            final count = payload['count'] as int? ?? 0;
            onCount(count);
          },
        )
        .subscribe();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FETCH Résultats depuis Supabase
  // ─────────────────────────────────────────────────────────────────────────
  Future<List<Resultat>> _fetchResultats(String electionId) async {
    try {
      final data = await supabase
          .from('resultats_publics')
          .select()
          .eq('election_id', electionId)
          .order('nb_votes', ascending: false);

      return (data as List).map((e) => Resultat.fromJson(e)).toList();
    } catch (e) {
      debugPrint('RealtimeService._fetchResultats error: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DÉSABONNEMENT
  // ─────────────────────────────────────────────────────────────────────────
  void unsubscribe() {
    if (_channel != null) {
      supabase.removeChannel(_channel!);
      _channel = null;
      debugPrint('RealtimeService: Canal fermé');
    }
  }

  void dispose() {
    unsubscribe();
    _resultatsController.close();
  }
}
