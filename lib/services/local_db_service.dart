import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../main.dart';

class LocalDbService {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'maurivote.db');
    return openDatabase(path, version: 1, onCreate: (db, v) async {
      await db.execute('''
        CREATE TABLE voters (
          nni TEXT PRIMARY KEY,
          nom TEXT, prenom TEXT,
          account_type TEXT DEFAULT "user",
          kyc_completed INTEGER DEFAULT 0,
          is_active INTEGER DEFAULT 1,
          synced INTEGER DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE elections (
          id TEXT PRIMARY KEY,
          titre_fr TEXT, titre_ar TEXT,
          type_election TEXT, statut TEXT,
          is_public INTEGER DEFAULT 1,
          date_ouverture TEXT, date_fermeture TEXT,
          nb_tours INTEGER DEFAULT 1,
          tour_actuel INTEGER DEFAULT 1,
          synced INTEGER DEFAULT 1
        )
      ''');
      await db.execute('''
        CREATE TABLE candidates (
          id TEXT PRIMARY KEY,
          election_id TEXT, nom TEXT,
          parti TEXT, parti_ar TEXT,
          numero_candidat INTEGER,
          nb_voix INTEGER DEFAULT 0,
          is_active INTEGER DEFAULT 1,
          tour INTEGER DEFAULT 1,
          synced INTEGER DEFAULT 1
        )
      ''');
      await db.execute('''
        CREATE TABLE votes (
          id TEXT PRIMARY KEY,
          election_id TEXT, candidate_id TEXT,
          voter_hash TEXT, recu_hash TEXT UNIQUE,
          vote_chiffre TEXT, timestamp_vote TEXT,
          is_valid INTEGER DEFAULT 1,
          synced INTEGER DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE wilayas (
          id TEXT PRIMARY KEY,
          code TEXT UNIQUE, nom_fr TEXT, nom_ar TEXT,
          chef_lieu TEXT, synced INTEGER DEFAULT 1
        )
      ''');
      await db.execute('''
        CREATE TABLE bureaux_vote (
          id TEXT PRIMARY KEY,
          code_bureau TEXT, nom TEXT,
          wilaya_id TEXT, commune_id TEXT,
          latitude REAL, longitude REAL,
          capacite INTEGER, is_actif INTEGER DEFAULT 1,
          synced INTEGER DEFAULT 1
        )
      ''');
      await _insertDonneesBase(db);
    });
  }

  // Données de base préchargées
  static Future<void> _insertDonneesBase(Database db) async {
    // Voters demo
    await db.insert('voters', {
      'nni': '1234567890', 'nom': 'TEST',
      'prenom': 'Electeur', 'account_type': 'user',
      'kyc_completed': 1, 'is_active': 1, 'synced': 1
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('voters', {
      'nni': '3333333333', 'nom': 'MOHAMEDOU',
      'prenom': 'baba', 'account_type': 'admin',
      'kyc_completed': 1, 'is_active': 1, 'synced': 1
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('voters', {
      'nni': '9876543210', 'nom': 'TEST2',
      'prenom': 'Electrice', 'account_type': 'user',
      'kyc_completed': 1, 'is_active': 1, 'synced': 1
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // Elections
    await db.insert('elections', {
      'id': 'election-presidentielle-2024',
      'titre_fr': 'Election Presidentielle 2024',
      'titre_ar': 'الانتخابات الرئاسية 2024',
      'type_election': 'presidentielle',
      'statut': 'terminee', 'is_public': 1,
      'date_ouverture': '2024-06-29T08:00:00',
      'date_fermeture': '2024-06-29T18:00:00',
      'nb_tours': 1, 'tour_actuel': 1, 'synced': 1
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('elections', {
      'id': 'election-municipale-2026',
      'titre_fr': 'Municipale Nouakchott 2026',
      'titre_ar': 'انتخابات نواكشوط البلدية 2026',
      'type_election': 'municipale',
      'statut': 'en_cours', 'is_public': 1,
      'date_ouverture': '2026-01-01T08:00:00',
      'date_fermeture': '2026-12-31T18:00:00',
      'nb_tours': 1, 'tour_actuel': 1, 'synced': 1
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // Candidats Presidentielle 2024
    final candidats2024 = [
      {'id':'c1','nom':'Mohamed Ould Cheikh El Ghazouani','parti':'Insaf','nb_voix':891754,'num':1},
      {'id':'c2','nom':'Biram Dah Abeid','parti':'Assawab / IRA','nb_voix':351623,'num':2},
      {'id':'c3','nom':'Hamadi Ould Sidi El Mokhtar','parti':'Tawassoul','nb_voix':202847,'num':3},
      {'id':'c4','nom':'Mokhtar Ould Djay','parti':'Sawab','nb_voix':58234,'num':4},
      {'id':'c5','nom':'Kane Hamidou Baba','parti':'MPJ','nb_voix':28456,'num':5},
      {'id':'c6','nom':'Mohamed Lemine Ould El Wavi','parti':'Independant','nb_voix':15423,'num':6},
      {'id':'c7','nom':'Lalla Mariem Mint Moulaye Idriss','parti':'Independante','nb_voix':12891,'num':7},
    ];
    for (final c in candidats2024) {
      await db.insert('candidates', {
        'id': c['id'], 'election_id': 'election-presidentielle-2024',
        'nom': c['nom'], 'parti': c['parti'],
        'nb_voix': c['nb_voix'], 'numero_candidat': c['num'],
        'is_active': 1, 'tour': 1, 'synced': 1
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // Candidats Municipale 2026
    final candidats2026 = [
      {'id':'m1','nom':'Ahmed Ould Mohamed','parti':'Insaf','num':1},
      {'id':'m2','nom':'Fatima Mint Ahmed','parti':'Tawassoul','num':2},
      {'id':'m3','nom':'Mohamed Lemine Ould Bah','parti':'Sawab','num':3},
      {'id':'m4','nom':'Aicha Mint Cheikh','parti':'UFP','num':4},
      {'id':'m5','nom':'Sidi Ould Abdallahi','parti':'RFD','num':5},
    ];
    for (final c in candidats2026) {
      await db.insert('candidates', {
        'id': c['id'], 'election_id': 'election-municipale-2026',
        'nom': c['nom'], 'parti': c['parti'],
        'nb_voix': 0, 'numero_candidat': c['num'],
        'is_active': 1, 'tour': 1, 'synced': 1
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // Wilayas
    final wilayas = [
      {'id':'w01','code':'MR-01','nom_fr':'Hodh Ech Chargui','nom_ar':'حوض الشرقي','chef_lieu':'Nema'},
      {'id':'w02','code':'MR-02','nom_fr':'Hodh El Gharbi','nom_ar':'حوض الغربي','chef_lieu':'Aioun'},
      {'id':'w03','code':'MR-03','nom_fr':'Assaba','nom_ar':'عصابة','chef_lieu':'Kiffa'},
      {'id':'w04','code':'MR-04','nom_fr':'Gorgol','nom_ar':'كوركول','chef_lieu':'Kaedi'},
      {'id':'w05','code':'MR-05','nom_fr':'Brakna','nom_ar':'بركنة','chef_lieu':'Aleg'},
      {'id':'w06','code':'MR-06','nom_fr':'Trarza','nom_ar':'ترارزة','chef_lieu':'Rosso'},
      {'id':'w07','code':'MR-07','nom_fr':'Adrar','nom_ar':'آدرار','chef_lieu':'Atar'},
      {'id':'w08','code':'MR-08','nom_fr':'Dakhlet Nouadhibou','nom_ar':'نواذيبو','chef_lieu':'Nouadhibou'},
      {'id':'w09','code':'MR-09','nom_fr':'Tagant','nom_ar':'تاكانت','chef_lieu':'Tidjikja'},
      {'id':'w10','code':'MR-10','nom_fr':'Guidimagha','nom_ar':'كيديماغة','chef_lieu':'Selibaby'},
      {'id':'w11','code':'MR-11','nom_fr':'Tiris Zemmour','nom_ar':'تيرس زمور','chef_lieu':'Zouerat'},
      {'id':'w12','code':'MR-12','nom_fr':'Inchiri','nom_ar':'إينشيري','chef_lieu':'Akjoujt'},
      {'id':'w13','code':'MR-13','nom_fr':'Nouakchott Nord','nom_ar':'نواكشوط الشمالية','chef_lieu':'Dar Naim'},
      {'id':'w14','code':'MR-14','nom_fr':'Nouakchott Ouest','nom_ar':'نواكشوط الغربية','chef_lieu':'Tevragh-Zeina'},
      {'id':'w15','code':'MR-15','nom_fr':'Nouakchott Sud','nom_ar':'نواكشوط الجنوبية','chef_lieu':'Arafat'},
    ];
    for (final w in wilayas) {
      await db.insert('wilayas', {
        'id': w['id'], 'code': w['code'],
        'nom_fr': w['nom_fr'], 'nom_ar': w['nom_ar'],
        'chef_lieu': w['chef_lieu'], 'synced': 1
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // ═══ VOTERS ═══
  static Future<Map<String, dynamic>?> getVoterByNni(String nni) async {
    final database = await db;
    final results = await database.query('voters',
        where: 'nni = ? AND is_active = 1', whereArgs: [nni]);
    return results.isEmpty ? null : results.first;
  }

  static Future<bool> nniExists(String nni) async {
    final v = await getVoterByNni(nni);
    return v != null;
  }

  static Future<void> insertVoter(Map<String, dynamic> voter) async {
    final database = await db;
    await database.insert('voters', voter,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getAllVoters() async {
    final database = await db;
    return database.query('voters', orderBy: 'nom');
  }

  static Future<void> updateVoter(String nni, Map<String, dynamic> data) async {
    final database = await db;
    await database.update('voters', data, where: 'nni = ?', whereArgs: [nni]);
  }

  // ═══ ELECTIONS ═══
  static Future<List<Map<String, dynamic>>> getElections({bool publicOnly = true}) async {
    final database = await db;
    if (publicOnly) {
      return database.query('elections',
          where: 'is_public = 1', orderBy: 'date_ouverture DESC');
    }
    return database.query('elections', orderBy: 'date_ouverture DESC');
  }

  static Future<Map<String, dynamic>?> getElectionById(String id) async {
    final database = await db;
    final results = await database.query('elections',
        where: 'id = ?', whereArgs: [id]);
    return results.isEmpty ? null : results.first;
  }

  static Future<void> insertElection(Map<String, dynamic> election) async {
    final database = await db;
    await database.insert('elections', election,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateElectionStatut(String id, String statut) async {
    final database = await db;
    await database.update('elections',
        {'statut': statut, 'synced': 0},
        where: 'id = ?', whereArgs: [id]);
  }

  // ═══ CANDIDATES ═══
  static Future<List<Map<String, dynamic>>> getCandidats(String electionId) async {
    final database = await db;
    return database.query('candidates',
        where: 'election_id = ? AND is_active = 1',
        whereArgs: [electionId],
        orderBy: 'numero_candidat');
  }

  static Future<void> insertCandidat(Map<String, dynamic> c) async {
    final database = await db;
    await database.insert('candidates', c,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ═══ VOTES ═══
  static Future<bool> hasVoted(String voterHash, String electionId) async {
    final database = await db;
    final results = await database.query('votes',
        where: 'voter_hash = ? AND election_id = ?',
        whereArgs: [voterHash, electionId]);
    return results.isNotEmpty;
  }

  static Future<String> insertVote({
    required String electionId,
    required String candidateId,
    required String voterId,
  }) async {
    final database = await db;
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final voterHash = sha256.convert(utf8.encode(voterId)).toString();
    final recuHash = sha256.convert(utf8.encode(voterId + timestamp))
        .toString().substring(0, 32);

    // Anti double vote
    final exists = await hasVoted(voterHash, electionId);
    if (exists) throw Exception('Vous avez deja vote pour cette election !');

    await database.insert('votes', {
      'id': 'local-$timestamp',
      'election_id': electionId,
      'candidate_id': candidateId,
      'voter_hash': voterHash,
      'recu_hash': recuHash,
      'vote_chiffre': base64.encode(utf8.encode('$voterId:$electionId:$timestamp')),
      'timestamp_vote': DateTime.now().toIso8601String(),
      'is_valid': 1,
      'synced': 0,
    });

    return recuHash;
  }

  static Future<List<Map<String, dynamic>>> getAllVotes() async {
    final database = await db;
    return database.query('votes', orderBy: 'timestamp_vote DESC');
  }

  static Future<Map<String, dynamic>?> getVoteByRecuHash(String hash) async {
    final database = await db;
    final results = await database.query('votes',
        where: 'recu_hash = ?', whereArgs: [hash]);
    return results.isEmpty ? null : results.first;
  }

  // ═══ WILAYAS ═══
  static Future<List<Map<String, dynamic>>> getWilayas() async {
    final database = await db;
    return database.query('wilayas', orderBy: 'code');
  }

  // ═══ SYNC GSM ═══
  static Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  static Future<void> syncVersSupabase() async {
    if (!await isOnline()) return;
    final database = await db;
    final votes = await database.query('votes',
        where: 'synced = 0');

    for (final vote in votes) {
      try {
        await supabase.from('votes').insert({
          'election_id': vote['election_id'],
          'candidate_id': vote['candidate_id'],
          'voter_hash': vote['voter_hash'],
          'recu_hash': vote['recu_hash'],
          'vote_chiffre': vote['vote_chiffre'],
          'timestamp_vote': vote['timestamp_vote'],
          'is_valid': true,
          'tour': 1,
        });
        await database.update('votes', {'synced': 1},
            where: 'id = ?', whereArgs: [vote['id']]);
      } catch (_) {}
    }
  }

  static Future<Map<String, int>> getStats() async {
    final database = await db;
    final voters = await database.rawQuery('SELECT COUNT(*) as count FROM voters');
    final elections = await database.rawQuery('SELECT COUNT(*) as count FROM elections');
    final votes = await database.rawQuery('SELECT COUNT(*) as count FROM votes');
    final enCours = await database.rawQuery(
        "SELECT COUNT(*) as count FROM elections WHERE statut = 'en_cours'");
    final nonSync = await database.rawQuery(
        'SELECT COUNT(*) as count FROM votes WHERE synced = 0');
    return {
      'voters': Sqflite.firstIntValue(voters) ?? 0,
      'elections': Sqflite.firstIntValue(elections) ?? 0,
      'votes': Sqflite.firstIntValue(votes) ?? 0,
      'en_cours': Sqflite.firstIntValue(enCours) ?? 0,
      'non_sync': Sqflite.firstIntValue(nonSync) ?? 0,
    };
  }
}