import 'package:hive/hive.dart';
import '../main.dart';
import '../models/models.dart';
import '../utils/constants.dart';

class ElectionService {
  final _boxElections = Hive.box(AppConstants.boxElections);

  Future<List<Election>> getElections() async {
    try {
      final data = await supabase.from('elections')
          .select('*').order('created_at', ascending: false);
      final elections = (data as List)
          .map((e) => Election.fromJson(Map<String, dynamic>.from(e))).toList();
      await _boxElections.put('elections', data);
      return elections;
    } catch (_) {
      final cached = _boxElections.get('elections');
      if (cached == null) return [];
      return (cached as List)
          .map((e) => Election.fromJson(Map<String, dynamic>.from(e))).toList();
    }
  }

  Future<List<Election>> getActiveElections() async {
    try {
      final data = await supabase.from('elections')
          .select('*').eq('statut', 'en_cours')
          .order('created_at', ascending: false);
      return (data as List)
          .map((e) => Election.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) { return []; }
  }

  Future<Election?> getElection(String id) => getElectionById(id);
  Future<Election?> getElectionById(String id) async {
    try {
      final data = await supabase.from('elections')
          .select('*').eq('id', id).single();
      return Election.fromJson(Map<String, dynamic>.from(data));
    } catch (_) { return null; }
  }

  Future<List<Candidate>> getCandidates({required String electionId, int tour = 1}) async {
    try {
      final data = await supabase.from('candidates')
          .select('*').eq('election_id', electionId)
          .eq('is_active', true).order('numero_candidat');
      return (data as List)
          .map((c) => Candidate.fromJson(Map<String, dynamic>.from(c))).toList();
    } catch (_) { return []; }
  }

  Future<List<Resultat>> getResultats({required String electionId, int tour = 1}) async {
    try {
      final data = await supabase.from('candidates')
          .select('*').eq('election_id', electionId)
          .eq('is_active', true).order('nb_voix', ascending: false);
      return (data as List)
          .map((r) => Resultat.fromJson(Map<String, dynamic>.from(r))).toList();
    } catch (_) { return []; }
  }
}
