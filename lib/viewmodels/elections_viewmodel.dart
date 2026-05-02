import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/election_service.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final electionServiceProvider = Provider<ElectionService>(
  (_) => ElectionService(),
);

/// Liste de toutes les élections publiques
final electionsProvider = FutureProvider<List<Election>>((ref) {
  return ref.read(electionServiceProvider).getElections();
});

/// Élections filtrées par statut
final filteredElectionsProvider =
    Provider.family<AsyncValue<List<Election>>, ElectionFilter>((ref, filter) {
  return ref.watch(electionsProvider).whenData((elections) {
    return switch (filter) {
      ElectionFilter.all      => elections,
      ElectionFilter.active   => elections.where((e) => e.isActive).toList(),
      ElectionFilter.upcoming => elections
          .where((e) => e.statut == ElectionStatus.planifiee).toList(),
      ElectionFilter.past     => elections
          .where((e) => e.statut == ElectionStatus.terminee).toList(),
    };
  });
});

/// Détail d'une élection par ID
final electionDetailProvider =
    FutureProvider.family<Election?, String>((ref, id) {
  return ref.read(electionServiceProvider).getElectionById(id);
});

/// Candidats d'une élection (tour 1 par défaut)
final candidatesProvider =
    FutureProvider.family<List<Candidate>, CandidateQuery>((ref, query) {
  return ref.read(electionServiceProvider).getCandidates(
    electionId: query.electionId,
    tour: query.tour,
  );
});

/// Résultats d'une élection
final resultatsProvider =
    FutureProvider.family<List<Resultat>, ResultatQuery>((ref, query) {
  return ref.read(electionServiceProvider).getResultats(
    electionId: query.electionId,
    tour: query.tour,
  );
});

/// Filtre actif dans l'écran accueil
final electionFilterProvider =
    StateProvider<ElectionFilter>((_) => ElectionFilter.all);

// ── Types de requêtes (value objects pour les family providers) ───────────────

class CandidateQuery {
  final String electionId;
  final int tour;
  const CandidateQuery({required this.electionId, this.tour = 1});

  @override
  bool operator ==(Object other) =>
      other is CandidateQuery &&
      other.electionId == electionId &&
      other.tour == tour;

  @override
  int get hashCode => Object.hash(electionId, tour);
}

class ResultatQuery {
  final String electionId;
  final int tour;
  const ResultatQuery({required this.electionId, this.tour = 1});

  @override
  bool operator ==(Object other) =>
      other is ResultatQuery &&
      other.electionId == electionId &&
      other.tour == tour;

  @override
  int get hashCode => Object.hash(electionId, tour);
}

enum ElectionFilter { all, active, upcoming, past }
