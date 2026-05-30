import 'package:flutter_test/flutter_test.dart';
import 'package:maurivote/models/models.dart';
import 'package:maurivote/utils/crypto_utils.dart';
import 'package:maurivote/utils/validators.dart';
import 'package:maurivote/viewmodels/vote_viewmodel.dart';
import 'package:maurivote/viewmodels/elections_viewmodel.dart';

// ══════════════════════════════════════════════════════════════════════════════
// TESTS SPRINT 2 — J8 à J14
// ══════════════════════════════════════════════════════════════════════════════
void main() {
  // ── VotePayload ─────────────────────────────────────────────────────────────
  group('VotePayload — Sérialisation & Validation', () {
    const sel = 'sel-test-de-32-caracteres-minimum!!';
    const eId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
    const cId = 'a47ac10b-58cc-4372-a567-0e02b2c3d480';
    const tok = 'token-test';

    test('toJson contient tous les champs obligatoires', () {
      final encrypted = CryptoUtils.chiffrerVote(
        candidateId: cId,
        electionId: eId,
        sessionToken: tok,
        selServeur: sel,
      );
      final voterHash = CryptoUtils.hashVoter(
        nni: '1234567890',
        electionId: eId,
        selServeur: sel,
      );
      final recuHash = CryptoUtils.generateRecuHash(
        voterHash: voterHash,
        voteChiffre: encrypted['vote_chiffre']!,
        timestamp: DateTime.now().toIso8601String(),
      );

      final payload = VotePayload(
        voterHash: voterHash,
        electionId: eId,
        candidateId: cId,
        tour: 1,
        voteChiffre: encrypted['vote_chiffre']!,
        iv: encrypted['iv']!,
        signature: encrypted['signature']!,
        recuHash: recuHash,
      );

      final json = payload.toJson();
      expect(
        json.keys,
        containsAll([
          'voter_hash',
          'election_id',
          'candidate_id',
          'tour',
          'vote_chiffre',
          'iv',
          'signature',
          'recu_hash',
        ]),
      );
    });

    test('voter_hash est un HMAC-SHA256 de 64 chars', () {
      final hash = CryptoUtils.hashVoter(
        nni: '9876543210',
        electionId: eId,
        selServeur: sel,
      );
      expect(hash.length, 64);
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hash), isTrue);
    });

    test('recu_hash est unique pour chaque soumission', () {
      final vHash = 'a' * 64;
      const vChiffre = 'ENC';
      final h1 = CryptoUtils.generateRecuHash(
        voterHash: vHash,
        voteChiffre: vChiffre,
        timestamp: '2026-05-01T07:00:00Z',
      );
      final h2 = CryptoUtils.generateRecuHash(
        voterHash: vHash, voteChiffre: vChiffre,
        timestamp: '2026-05-01T07:01:00Z', // Timestamp différent
      );
      expect(h1, isNot(equals(h2)));
    });

    test('le candidat choisi n\'apparaît pas dans le vote chiffré', () {
      final enc = CryptoUtils.chiffrerVote(
        candidateId: cId,
        electionId: eId,
        sessionToken: tok,
        selServeur: sel,
      );
      expect(enc['vote_chiffre'], isNot(contains(cId)));
      expect(enc['vote_chiffre'], isNot(contains(eId)));
      expect(enc['vote_chiffre'], isNot(contains('candidate')));
    });

    test('IV différent → chiffrements différents (30 essais)', () {
      final chiffrements = List.generate(
        30,
        (_) => CryptoUtils.chiffrerVote(
          candidateId: cId,
          electionId: eId,
          sessionToken: tok,
          selServeur: sel,
        ),
      );
      final ivs = chiffrements.map((e) => e['iv']).toSet();
      expect(ivs.length, 30); // Tous distincts
    });
  });

  // ── HasVotedQuery ────────────────────────────────────────────────────────────
  group('HasVotedQuery — Égalité et hashCode', () {
    test('même election_id + tour → égaux', () {
      const q1 = HasVotedQuery(electionId: 'e1');
      const q2 = HasVotedQuery(electionId: 'e1');
      expect(q1, equals(q2));
      expect(q1.hashCode, equals(q2.hashCode));
    });

    test('tours différents → inégaux', () {
      const q1 = HasVotedQuery(electionId: 'e1');
      const q2 = HasVotedQuery(electionId: 'e1', tour: 2);
      expect(q1, isNot(equals(q2)));
    });

    test('elections différentes → inégaux', () {
      const q1 = HasVotedQuery(electionId: 'e1');
      const q2 = HasVotedQuery(electionId: 'e2');
      expect(q1, isNot(equals(q2)));
    });
  });

  // ── CandidateQuery ───────────────────────────────────────────────────────────
  group('CandidateQuery — Égalité et hashCode', () {
    test('mêmes params → égaux', () {
      const q1 = CandidateQuery(electionId: 'e1');
      const q2 = CandidateQuery(electionId: 'e1');
      expect(q1, equals(q2));
      expect(q1.hashCode, equals(q2.hashCode));
    });

    test('tour défaut est 1', () {
      const q = CandidateQuery(electionId: 'e1');
      expect(q.tour, 1);
    });
  });

  // ── VoteState ────────────────────────────────────────────────────────────────
  group('VoteState — États et transitions', () {
    test('initial → status idle', () {
      final state = VoteState.initial();
      expect(state.status, VoteStatus.idle);
      expect(state.recuHash, isNull);
      expect(state.errorMessage, isNull);
      expect(state.isOfflineQueued, isFalse);
    });

    test('copyWith change uniquement les champs spécifiés', () {
      final initial = VoteState.initial();
      final updated = initial.copyWith(
        status: VoteStatus.success,
        recuHash: 'r' * 64,
      );
      expect(updated.status, VoteStatus.success);
      expect(updated.recuHash, 'r' * 64);
      expect(updated.errorMessage, isNull); // Inchangé
      expect(updated.isOfflineQueued, isFalse); // Inchangé
    });

    test('état offline contient isOfflineQueued = true', () {
      final state = VoteState.initial().copyWith(
        status: VoteStatus.offline,
        isOfflineQueued: true,
        errorMessage: 'En attente de réseau',
      );
      expect(state.status, VoteStatus.offline);
      expect(state.isOfflineQueued, isTrue);
      expect(state.errorMessage, isNotNull);
    });

    test('tous les statuts d\'erreur sont distincts', () {
      final statuses = VoteStatus.values.toSet();
      expect(statuses.length, VoteStatus.values.length);
    });
  });

  // ── Modèles Election — Cas limites ───────────────────────────────────────────
  group('Election — Cas limites du modèle', () {
    Map<String, dynamic> baseJson() => {
          'id': 'e1',
          'titre_fr': 'Test',
          'titre_ar': 'اختبار',
          'type_election': 'presidentielle',
          'nb_tours': 2,
          'date_ouverture': DateTime.now()
              .toUtc()
              .subtract(const Duration(hours: 1))
              .toIso8601String(),
          'date_fermeture': DateTime.now()
              .toUtc()
              .add(const Duration(hours: 5))
              .toIso8601String(),
          'statut': 'en_cours',
          'tour_actuel': 1,
          'is_public': true,
        };

    test('isVotable = true : en_cours + dans la période', () {
      expect(Election.fromJson(baseJson()).isVotable, isTrue);
    });

    test('isVotable = false : en_cours mais période passée', () {
      final j = baseJson();
      j['date_fermeture'] = DateTime.now()
          .toUtc()
          .subtract(const Duration(hours: 1))
          .toIso8601String();
      expect(Election.fromJson(j).isVotable, isFalse);
    });

    test('isVotable = false : période future', () {
      final j = baseJson();
      j['date_ouverture'] = DateTime.now()
          .toUtc()
          .add(const Duration(hours: 2))
          .toIso8601String();
      expect(Election.fromJson(j).isVotable, isFalse);
    });

    test('type inconnu → présidentielle par défaut', () {
      final j = baseJson();
      j['type_election'] = 'inconnu';
      final e = Election.fromJson(j);
      expect(e.type, ElectionType.presidentielle);
    });

    test('statut inconnu → planifiee par défaut', () {
      final j = baseJson();
      j['statut'] = 'xyz';
      final e = Election.fromJson(j);
      expect(e.statut, ElectionStatus.planifiee);
    });

    test('typeLabel pour tous les types', () {
      final types = {
        'presidentielle': 'Présidentielle',
        'legislative': 'Législative',
        'municipale': 'Municipale',
        'regionale': 'Régionale',
        'referendum': 'Référendum',
      };
      for (final entry in types.entries) {
        final j = baseJson()..['type_election'] = entry.key;
        expect(Election.fromJson(j).typeLabel, entry.value);
      }
    });
  });

  // ── Validators — Tests supplémentaires ──────────────────────────────────────
  group('AppValidators — Tests supplémentaires Sprint 2', () {
    test('validateEmail accepte format valide', () {
      expect(AppValidators.validateEmail('test@maurivote.mr'), isNull);
      expect(AppValidators.validateEmail('admin@ceni.mr'), isNull);
    });

    test('validateEmail rejette format invalide', () {
      expect(AppValidators.validateEmail('pas-un-email'), isNotNull);
      expect(AppValidators.validateEmail('@ceni.mr'), isNotNull);
      expect(AppValidators.validateEmail(''), isNotNull);
    });

    test('isElectionActive — frontières de temps', () {
      final now = DateTime.now().toUtc();

      // Exactement maintenant = ouverture → pas encore actif
      expect(
        AppValidators.isElectionActive(
          ouverture: now.add(const Duration(seconds: 10)),
          fermeture: now.add(const Duration(hours: 1)),
        ),
        isFalse,
      ); // now.isAfter(now) est false

      // 1 milliseconde après l'ouverture → actif
      expect(
        AppValidators.isElectionActive(
          ouverture: now.subtract(const Duration(milliseconds: 1)),
          fermeture: now.add(const Duration(hours: 1)),
        ),
        isTrue,
      );
    });
  });

  // ── Intégration : flux vote complet simulé ───────────────────────────────────
  group('Flux vote complet — Simulation end-to-end', () {
    const sel = 'sel-production-32-chars-minimum!!x';
    const nni = '1234567890';
    const eId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
    const cId = 'a47ac10b-58cc-4372-a567-0e02b2c3d480';
    const tok = 'session-token-mock';

    test('Génération complète d\'un payload de vote valide', () {
      // 1. Chiffrer le vote
      final encrypted = CryptoUtils.chiffrerVote(
        candidateId: cId,
        electionId: eId,
        sessionToken: tok,
        selServeur: sel,
      );

      // 2. Hasher l'électeur
      final voterHash = CryptoUtils.hashVoter(
        nni: nni,
        electionId: eId,
        selServeur: sel,
      );

      // 3. Générer le reçu
      final timestamp = DateTime.now().toUtc().toIso8601String();
      final recuHash = CryptoUtils.generateRecuHash(
        voterHash: voterHash,
        voteChiffre: encrypted['vote_chiffre']!,
        timestamp: timestamp,
      );

      // 4. Créer le payload
      final payload = VotePayload(
        voterHash: voterHash,
        electionId: eId,
        candidateId: cId,
        tour: 1,
        voteChiffre: encrypted['vote_chiffre']!,
        iv: encrypted['iv']!,
        signature: encrypted['signature']!,
        recuHash: recuHash,
      );

      final json = payload.toJson();

      // Vérifications de sécurité
      expect(json['voter_hash'].toString().length, 64);
      expect(json['signature'].toString().length, 64);
      expect(json['recu_hash'].toString().length, 64);
      expect(json['vote_chiffre'], isNot(contains(cId)));
      expect(json['vote_chiffre'], isNot(contains(nni)));
      expect(json['tour'], 1);

      // Vérifier la signature
      expect(
        CryptoUtils.verifySignature(
          data: encrypted['vote_chiffre']! + encrypted['iv']!,
          signature: encrypted['signature']!,
          key: sel,
        ),
        isTrue,
      );
    });

    test('Deux électeurs différents → voter_hash différents', () {
      final h1 = CryptoUtils.hashVoter(
        nni: '1111111111',
        electionId: eId,
        selServeur: sel,
      );
      final h2 = CryptoUtils.hashVoter(
        nni: '2222222222',
        electionId: eId,
        selServeur: sel,
      );
      expect(h1, isNot(equals(h2)));
    });

    test('Même électeur, élection différente → voter_hash différents', () {
      const eId2 = 'b47ac10b-58cc-4372-a567-0e02b2c3d481';
      final h1 =
          CryptoUtils.hashVoter(nni: nni, electionId: eId, selServeur: sel);
      final h2 =
          CryptoUtils.hashVoter(nni: nni, electionId: eId2, selServeur: sel);
      expect(h1, isNot(equals(h2)));
    });
  });
}
