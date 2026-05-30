import 'package:connectivity_plus/connectivity_plus.dart';
import '../main.dart';
import 'local_db_service.dart';

class SmartDbService {
  static Future<bool> isOnline() async {
    try {
      final r = await Connectivity().checkConnectivity();
      return r != ConnectivityResult.none;
    } catch (_) { return false; }
  }

  static Future<Map<String, dynamic>?> login(String nni) async {
    final local = await LocalDbService.getVoterByNni(nni);
    if (local != null) return local;
    if (!await isOnline()) return null;
    try {
      final r = await supabase.from('voters').select('*')
          .eq('nni', nni).eq('is_active', true).maybeSingle();
      if (r != null) {
        await LocalDbService.insertVoter({
          'nni': r['nni'], 'nom': r['nom'] ?? '',
          'prenom': r['prenom'] ?? '',
          'account_type': r['account_type'] ?? 'user',
          'kyc_completed': r['kyc_completed'] == true ? 1 : 0,
          'is_active': 1, 'synced': 1,
        });
      }
      return r;
    } catch (_) { return null; }
  }

  static Future<List<Map<String, dynamic>>> getElections() async {
    if (await isOnline()) {
      try {
        final data = await supabase.from('elections').select('*')
            .eq('is_public', true).order('created_at', ascending: false);
        final list = List<Map<String, dynamic>>.from(data as List);
        for (final e in list) {
          await LocalDbService.insertElection({
            'id': e['id'], 'titre_fr': e['titre_fr'] ?? '',
            'titre_ar': e['titre_ar'] ?? '',
            'type_election': e['type_election'] ?? '',
            'statut': e['statut'] ?? 'planifiee', 'is_public': 1,
            'date_ouverture': e['date_ouverture'] ?? '',
            'date_fermeture': e['date_fermeture'] ?? '',
            'nb_tours': e['nb_tours'] ?? 1,
            'tour_actuel': e['tour_actuel'] ?? 1, 'synced': 1,
          });
        }
        return list;
      } catch (_) {}
    }
    return await LocalDbService.getElections();
  }

  static Future<List<Map<String, dynamic>>> getCandidats(String electionId) async {
    if (await isOnline()) {
      try {
        final data = await supabase.from('candidates').select('*')
            .eq('election_id', electionId)
            .eq('is_active', true).order('numero_candidat');
        final list = List<Map<String, dynamic>>.from(data as List);
        for (final c in list) {
          await LocalDbService.insertCandidat({
            'id': c['id'], 'election_id': electionId,
            'nom': c['nom'] ?? '', 'parti': c['parti'] ?? '',
            'parti_ar': c['parti_ar'] ?? '',
            'numero_candidat': c['numero_candidat'] ?? 1,
            'nb_voix': c['nb_voix'] ?? 0,
            'is_active': 1, 'tour': c['tour'] ?? 1, 'synced': 1,
          });
        }
        return list;
      } catch (_) {}
    }
    return await LocalDbService.getCandidats(electionId);
  }

  static Future<String> voter({
    required String electionId,
    required String candidateId,
    required String voterId,
  }) async {
    final recuHash = await LocalDbService.insertVote(
      electionId: electionId,
      candidateId: candidateId,
      voterId: voterId,
    );
    if (await isOnline()) {
      await LocalDbService.syncVersSupabase();
    }
    return recuHash;
  }

  static Future<void> inscrire(Map<String, dynamic> voter) async {
    await LocalDbService.insertVoter({
      'nni': voter['nni'], 'nom': voter['nom'] ?? '',
      'prenom': voter['prenom'] ?? '',
      'account_type': 'user',
      'kyc_completed': 0, 'is_active': 1, 'synced': 0,
    });
    if (await isOnline()) {
      try {
        await supabase.from('voters').insert(voter);
        await LocalDbService.updateVoter(voter['nni'], {'synced': 1});
      } catch (_) {}
    }
  }

  static Future<Map<String, int>> getStats() async {
    if (await isOnline()) {
      try {
        final voters = await supabase.from('voters').select('id');
        final elections = await supabase.from('elections').select('id');
        final votes = await supabase.from('votes').select('id');
        final enCours = await supabase.from('elections')
            .select('id').eq('statut', 'en_cours');
        return {
          'voters': (voters as List).length,
          'elections': (elections as List).length,
          'votes': (votes as List).length,
          'en_cours': (enCours as List).length,
          'non_sync': 0,
        };
      } catch (_) {}
    }
    return await LocalDbService.getStats();
  }
}
