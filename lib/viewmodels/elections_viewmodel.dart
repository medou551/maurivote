import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/election_service.dart';

final electionServiceProvider = Provider<ElectionService>((_) => ElectionService());

final electionsProvider = FutureProvider<List<Election>>((ref) {
  return ref.read(electionServiceProvider).getElections();
});

final filteredElectionsProvider =
    Provider.family<AsyncValue<List<Election>>, ElectionFilter>((ref, filter) {
  return ref.watch(electionsProvider).whenData((elections) {
    return switch (filter) {
      ElectionFilter.all      => elections,
      ElectionFilter.active   => elections.where((e) => e.isActive).toList(),
      ElectionFilter.upcoming => elections.where((e) => e.statut == ElectionStatus.planifiee).toList(),
      ElectionFilter.past     => elections.where((e) => e.statut == ElectionStatus.terminee).toList(),
    };
  });
});

final electionDetailProvider = FutureProvider.family<Election?, String>((ref, id) {
  return ref.read(electionServiceProvider).getElectionById(id);
});

final candidatesProvider = FutureProvider.family<List<Candidate>, CandidateQuery>((ref, query) {
  return ref.read(electionServiceProvider).getCandidates(electionId: query.electionId, tour: query.tour);
});

final resultatsProvider = FutureProvider.family<List<Resultat>, ResultatQuery>((ref, query) {
  return ref.read(electionServiceProvider).getResultats(electionId: query.electionId, tour: query.tour);
});

enum ElectionFilter { all, active, upcoming, past }

class ElectionFilterNotifier extends Notifier<ElectionFilter> {
  @override
  ElectionFilter build() => ElectionFilter.all;
  void setFilter(ElectionFilter f) => state = f;
}

final electionFilterProvider = NotifierProvider<ElectionFilterNotifier, ElectionFilter>(ElectionFilterNotifier.new);

class CandidateQuery {
  final String electionId;
  final int tour;
  const CandidateQuery({required this.electionId, this.tour = 1});
  @override
  bool operator ==(Object o) => o is CandidateQuery && o.electionId == electionId && o.tour == tour;
  @override
  int get hashCode => Object.hash(electionId, tour);
}

class ResultatQuery {
  final String electionId;
  final int tour;
  const ResultatQuery({required this.electionId, this.tour = 1});
  @override
  bool operator ==(Object o) => o is ResultatQuery && o.electionId == electionId && o.tour == tour;
  @override
  int get hashCode => Object.hash(electionId, tour);
}