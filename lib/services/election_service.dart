import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../main.dart';
import '../models/models.dart';
import '../utils/constants.dart';

/// Service de récupération et gestion des élections
class ElectionService {
  final _boxElections = Hive.box(AppConstants.boxElections);

  // ─────────────────────────────────────────────────────────────────────────
  // ÉLECTIONS
  // ─────────────────────────────────────────────────────────────────────────

  /// Récupère toutes les élections publiques (active + planifiées + terminées)
  Future<List<Election>> getElections({bool forceRefresh = false}) async {
    try {
      // Essai réseau
      final data = await supabase
          .from('elections')
          .select()
          .eq('is_public', true)
          .neq('statut', 'annulee')
          .order('date_ouverture', ascending: false)
          .limit(50);

      final elections = (data as List)
          .map((e) => Election.fromJson(e))
          .toList();

      // Mise en cache locale (mode offline)
      await _boxElections.put('all_elections',
          elections.map((e) => e.toJson()).toList());

      return elections;
    } catch (e) {
      debugPrint('ElectionService.getElections error: $e');
      // Fallback : cache local
      return _getElectionsFromCache();
    }
  }

  /// Élections actives uniquement (en_cours)
  Future<List<Election>> getActiveElections() async {
    try {
      final data = await supabase
          .from('elections')
          .select()
          .eq('statut', AppConstants.statusEnCours)
          .eq('is_public', true)
          .order('date_ouverture');

      return (data as List).map((e) => Election.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getActiveElections error: $e');
      return _getElectionsFromCache()
          .where((e) => e.isActive)
          .toList();
    }
  }

  /// Détail d'une élection par ID
  Future<Election?> getElectionById(String id) async {
    try {
      final data = await supabase
          .from('elections')
          .select()
          .eq('id', id)
          .single();
      return Election.fromJson(data);
    } catch (e) {
      debugPrint('getElectionById error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CANDIDATS
  // ─────────────────────────────────────────────────────────────────────────

  /// Récupère les candidats d'une élection (filtré par tour)
  Future<List<Candidate>> getCandidates({
    required String electionId,
    int tour = 1,
  }) async {
    try {
      final data = await supabase
          .from('candidates')
          .select()
          .eq('election_id', electionId)
          .eq('tour', tour)
          .eq('is_active', true)
          .order('numero_candidat');

      return (data as List).map((e) => Candidate.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getCandidates error: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RÉSULTATS
  // ─────────────────────────────────────────────────────────────────────────

  /// Résultats agrégés d'une élection (via vue sécurisée)
  Future<List<Resultat>> getResultats({
    required String electionId,
    int tour = 1,
  }) async {
    try {
      final data = await supabase
          .from('resultats_publics')
          .select()
          .eq('election_id', electionId)
          .eq('tour', tour)
          .order('nb_votes', ascending: false);

      return (data as List).map((e) => Resultat.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getResultats error: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUREAU DE VOTE
  // ─────────────────────────────────────────────────────────────────────────

  /// Bureau de vote de l'électeur connecté
  Future<BureauVote?> getBureauVote(String bureauVoteId) async {
    try {
      final data = await supabase
          .from('bureaux_vote')
          .select()
          .eq('id', bureauVoteId)
          .single();
      return BureauVote.fromJson(data);
    } catch (e) {
      debugPrint('getBureauVote error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CACHE LOCAL (mode offline)
  // ─────────────────────────────────────────────────────────────────────────
  List<Election> _getElectionsFromCache() {
    try {
      final cached = _boxElections.get('all_elections') as List?;
      if (cached == null) return [];
      return cached
          .map((e) => Election.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Précharger les élections actives en cache local (appelé au démarrage)
  Future<void> prefetchElections() async {
    try {
      await getElections(forceRefresh: true);
      final active = await getActiveElections();
      // Précharger aussi les candidats de chaque élection active
      for (final election in active) {
        await getCandidates(electionId: election.id);
      }
    } catch (_) {}
  }
}
