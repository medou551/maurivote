import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:maurivote/utils/validators.dart';
import 'package:maurivote/utils/crypto_utils.dart';
import 'package:maurivote/models/models.dart';

// ══════════════════════════════════════════════════════════════════════════════
// TESTS J3 — AuthService + Validators + Modèles complets
// ══════════════════════════════════════════════════════════════════════════════

void main() {
  // ── Validators ─────────────────────────────────────────────────────────────
  group('AppValidators — NNI', () {
    final validCases = ['1234567890', '0000000000', '9999999999', '5555555555'];
    final invalidCases = {
      '':            'vide',
      '123456789':   '9 chiffres',
      '12345678901': '11 chiffres',
      '123456789A':  'avec lettre',
      '123 456789':  'avec espace',
      '123-456789':  'avec tiret',
      '!234567890':  'avec caractère spécial',
    };

    for (final nni in validCases) {
      test('accepte "$nni"', () => expect(AppValidators.validateNni(nni), isNull));
    }
    for (final entry in invalidCases.entries) {
      test('rejette "${entry.key}" (${entry.value})',
          () => expect(AppValidators.validateNni(entry.key), isNotNull));
    }
    test('rejette null', () => expect(AppValidators.validateNni(null), isNotNull));
  });

  group('AppValidators — Téléphone mauritanien', () {
    test('accepte +22220001234', () => expect(AppValidators.validatePhone('+22220001234'), isNull));
    test('accepte +22246123456', () => expect(AppValidators.validatePhone('+22246123456'), isNull));
    test('rejette sans code pays', () => expect(AppValidators.validatePhone('20001234'), isNotNull));
    test('rejette code pays incorrect', () => expect(AppValidators.validatePhone('+33612345678'), isNotNull));
    test('rejette trop court', () => expect(AppValidators.validatePhone('+2222000'), isNotNull));
    test('rejette null', () => expect(AppValidators.validatePhone(null), isNotNull));
  });

  group('AppValidators — isElectionActive', () {
    test('retourne true si dans la période', () {
      final now = DateTime.now().toUtc();
      expect(AppValidators.isElectionActive(
        ouverture: now.subtract(const Duration(hours: 2)),
        fermeture: now.add(const Duration(hours: 8)),
      ), isTrue);
    });
    test('retourne false si pas encore ouverte', () {
      final now = DateTime.now().toUtc();
      expect(AppValidators.isElectionActive(
        ouverture: now.add(const Duration(hours: 2)),
        fermeture: now.add(const Duration(hours: 10)),
      ), isFalse);
    });
    test('retourne false si déjà fermée', () {
      final now = DateTime.now().toUtc();
      expect(AppValidators.isElectionActive(
        ouverture: now.subtract(const Duration(hours: 12)),
        fermeture: now.subtract(const Duration(hours: 1)),
      ), isFalse);
    });
    test('retourne false si ouverture == fermeture', () {
      final now = DateTime.now().toUtc();
      expect(AppValidators.isElectionActive(ouverture: now, fermeture: now), isFalse);
    });
  });

  group('AppValidators — UUID', () {
    test('accepte UUID v4 valide', () {
      expect(AppValidators.isValidUuid('f47ac10b-58cc-4372-a567-0e02b2c3d479'), isTrue);
      expect(AppValidators.isValidUuid('550e8400-e29b-41d4-a716-446655440000'), isTrue);
    });
    test('rejette non-UUID', () {
      expect(AppValidators.isValidUuid('not-a-uuid'), isFalse);
      expect(AppValidators.isValidUuid(''), isFalse);
      expect(AppValidators.isValidUuid(null), isFalse);
      expect(AppValidators.isValidUuid('1234567890'), isFalse);
    });
  });

  // ── CryptoUtils ─────────────────────────────────────────────────────────────
  group('CryptoUtils — Suite complète', () {
    const sel = 'sel-test-de-32-caracteres-minimum!!';
    const nni = '1234567890';
    const eId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
    const cId = 'a47ac10b-58cc-4372-a567-0e02b2c3d480';
    const tok = 'mock-session-token';

    group('generateIV', () {
      test('taille 16 bytes', () => expect(CryptoUtils.generateIV().length, 16));
      test('100 IVs tous distincts', () {
        final set = List.generate(100, (_) => CryptoUtils.generateIV().toString()).toSet();
        expect(set.length, 100);
      });
    });

    group('deriveAesKey', () {
      test('retourne 32 bytes', () => expect(CryptoUtils.deriveAesKey(tok, sel).length, 32));
      test('déterministe', () {
        expect(CryptoUtils.deriveAesKey(tok, sel), equals(CryptoUtils.deriveAesKey(tok, sel)));
      });
      test('sensible au token', () {
        expect(CryptoUtils.deriveAesKey('A', sel), isNot(equals(CryptoUtils.deriveAesKey('B', sel))));
      });
    });

    group('chiffrerVote', () {
      late Map<String, String> result;
      setUp(() => result = CryptoUtils.chiffrerVote(
        candidateId: cId, electionId: eId, sessionToken: tok, selServeur: sel));

      test('contient les 3 clés', () =>
          expect(result.keys, containsAll(['vote_chiffre', 'iv', 'signature'])));
      test('candidat absent du chiffré', () {
        expect(result['vote_chiffre'], isNot(contains(cId)));
        expect(result['vote_chiffre'], isNot(contains(eId)));
      });
      test('signature 64 chars hex', () {
        expect(result['signature']!.length, 64);
        expect(RegExp(r'^[0-9a-f]+$').hasMatch(result['signature']!), isTrue);
      });
      test('IV aléatoire → chiffrés différents', () {
        final r2 = CryptoUtils.chiffrerVote(
            candidateId: cId, electionId: eId, sessionToken: tok, selServeur: sel);
        expect(result['iv'], isNot(equals(r2['iv'])));
        expect(result['vote_chiffre'], isNot(equals(r2['vote_chiffre'])));
      });
      test('signature valide', () {
        expect(CryptoUtils.verifySignature(
          data: result['vote_chiffre']! + result['iv']!,
          signature: result['signature']!,
          key: sel,
        ), isTrue);
      });
    });

    group('hashVoter', () {
      test('64 chars', () => expect(CryptoUtils.hashVoter(nni: nni, electionId: eId, selServeur: sel).length, 64));
      test('déterministe', () => expect(
        CryptoUtils.hashVoter(nni: nni, electionId: eId, selServeur: sel),
        equals(CryptoUtils.hashVoter(nni: nni, electionId: eId, selServeur: sel)),
      ));
      test('NNI non visible dans hash', () =>
          expect(CryptoUtils.hashVoter(nni: nni, electionId: eId, selServeur: sel), isNot(contains(nni))));
      test('NNIs différents → hashs différents', () =>
          expect(
            CryptoUtils.hashVoter(nni: '1111111111', electionId: eId, selServeur: sel),
            isNot(equals(CryptoUtils.hashVoter(nni: '2222222222', electionId: eId, selServeur: sel))),
          ));
    });

    group('generateRecuHash', () {
      test('retourne 64 chars', () {
        final h = CryptoUtils.generateRecuHash(
          voterHash: 'a' * 64, voteChiffre: 'ENCRYPTED', timestamp: '2026-01-01T10:00:00Z');
        expect(h.length, 64);
      });
      test('déterministe avec mêmes paramètres', () {
        const params = ('a' * 64, 'ENC', '2026-01-01T10:00:00Z');
        expect(
          CryptoUtils.generateRecuHash(voterHash: params.$1, voteChiffre: params.$2, timestamp: params.$3),
          equals(CryptoUtils.generateRecuHash(voterHash: params.$1, voteChiffre: params.$2, timestamp: params.$3)),
        );
      });
    });

    group('verifySignature', () {
      test('valide pour signature correcte', () {
        const data = 'données-test-importante';
        final sig = CryptoUtils.hmacSign(data: data, key: sel);
        expect(CryptoUtils.verifySignature(data: data, signature: sig, key: sel), isTrue);
      });
      test('invalide si signature altérée', () {
        const data = 'données-test';
        final sig = CryptoUtils.hmacSign(data: data, key: sel);
        final bad = '${sig.substring(0, 60)}XXXX';
        expect(CryptoUtils.verifySignature(data: data, signature: bad, key: sel), isFalse);
      });
      test('invalide si données altérées', () {
        final sig = CryptoUtils.hmacSign(data: 'original', key: sel);
        expect(CryptoUtils.verifySignature(data: 'modifié', signature: sig, key: sel), isFalse);
      });
      test('invalide si longueurs différentes', () {
        final sig = CryptoUtils.hmacSign(data: 'test', key: sel);
        expect(CryptoUtils.verifySignature(data: 'test', signature: '${sig}extra', key: sel), isFalse);
      });
    });

    group('generateNonce', () {
      test('50 nonces distincts', () {
        final nonces = List.generate(50, (_) => CryptoUtils.generateNonce()).toSet();
        expect(nonces.length, 50);
      });
      test('non vide', () => expect(CryptoUtils.generateNonce().length, greaterThan(10)));
    });
  });

  // ── Modèles ─────────────────────────────────────────────────────────────────
  group('Modèle Voter', () {
    late Map<String, dynamic> json;
    setUp(() => json = {
      'id': 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
      'nni': '1234567890', 'nom': 'Ould Ahmed', 'prenom': 'Mohamed',
      'date_naissance': '1990-06-15', 'sexe': 'M',
      'commune_id': 'c1', 'wilaya_id': 'w1', 'bureau_vote_id': null,
      'telephone': '+22220001234', 'photo_url': null,
      'is_verified': true, 'is_active': true,
      'created_at': '2026-01-01T00:00:00Z',
    });

    test('désérialise depuis JSON', () {
      final v = Voter.fromJson(json);
      expect(v.nni, '1234567890');
      expect(v.nom, 'Ould Ahmed');
      expect(v.isVerified, isTrue);
    });
    test('nomComplet combine prénom et nom', () {
      final v = Voter.fromJson(json);
      expect(v.nomComplet, 'Mohamed Ould Ahmed');
    });
    test('nniMasque cache les chiffres centraux', () {
      final v = Voter.fromJson(json);
      expect(v.nniMasque, contains('****'));
      expect(v.nniMasque, isNot(equals(v.nni)));
    });
    test('serialise en JSON', () {
      final v = Voter.fromJson(json);
      final out = v.toJson();
      expect(out['nni'], '1234567890');
      expect(out['nom'], 'Ould Ahmed');
    });
  });

  group('Modèle Election', () {
    late Map<String, dynamic> json;
    setUp(() {
      final now = DateTime.now().toUtc();
      json = {
        'id': 'e1', 'titre_fr': 'Présidentielle 2026', 'titre_ar': 'رئاسية 2026',
        'type_election': 'presidentielle', 'nb_tours': 2,
        'date_ouverture': now.subtract(const Duration(hours: 2)).toIso8601String(),
        'date_fermeture': now.add(const Duration(hours: 10)).toIso8601String(),
        'statut': 'en_cours', 'tour_actuel': 1, 'is_public': true,
      };
    });

    test('désérialise le type', () => expect(Election.fromJson(json).type, ElectionType.presidentielle));
    test('isActive quand en_cours', () => expect(Election.fromJson(json).isActive, isTrue));
    test('isVotable dans la période', () => expect(Election.fromJson(json).isVotable, isTrue));
    test('isVotable false si terminée', () {
      json['statut'] = 'terminee';
      json['date_fermeture'] = DateTime.now().subtract(const Duration(hours: 1)).toIso8601String();
      expect(Election.fromJson(json).isVotable, isFalse);
    });
    test('typeLabel correct', () => expect(Election.fromJson(json).typeLabel, 'Présidentielle'));
    test('tous les types mappent correctement', () {
      for (final type in ['presidentielle','legislative','municipale','regionale','referendum']) {
        json['type_election'] = type;
        final e = Election.fromJson(json);
        expect(e.typeLabel, isNotEmpty);
      }
    });
  });

  group('Modèle Candidate', () {
    test('désérialise depuis JSON', () {
      final c = Candidate.fromJson({
        'id': 'c1', 'election_id': 'e1', 'numero_candidat': 1,
        'nom': 'Alpha Diallo', 'parti': 'Parti de la Réforme',
        'parti_ar': 'حزب الإصلاح', 'photo_url': null,
        'couleur_parti': '#1565C0', 'tour': 1, 'is_active': true,
      });
      expect(c.nom, 'Alpha Diallo');
      expect(c.numeroCandidat, 1);
      expect(c.isActive, isTrue);
    });
    test('accepte candidat indépendant (parti null)', () {
      final c = Candidate.fromJson({
        'id': 'c2', 'election_id': 'e1', 'numero_candidat': 2,
        'nom': 'Beta Sow', 'tour': 1, 'is_active': true,
      });
      expect(c.parti, isNull);
    });
  });

  group('Modèle Resultat', () {
    test('désérialise depuis JSON', () {
      final r = Resultat.fromJson({
        'election_id': 'e1', 'candidate_id': 'c1', 'tour': 1,
        'nb_votes': 15000, 'pourcentage': 48.5,
        'valide_ceni': true, 'valide_cc': false,
      });
      expect(r.nbVotes, 15000);
      expect(r.pourcentage, 48.5);
      expect(r.valideCeni, isTrue);
      expect(r.valideCc, isFalse);
    });
    test('gère les valeurs nulles gracieusement', () {
      final r = Resultat.fromJson({
        'election_id': 'e1', 'candidate_id': 'c1',
      });
      expect(r.nbVotes, 0);
      expect(r.pourcentage, 0.0);
      expect(r.tour, 1);
    });
  });

  group('VotePayload', () {
    test('toJson contient tous les champs requis', () {
      final payload = VotePayload(
        voterHash: 'h' * 64, electionId: 'e1', candidateId: 'c1', tour: 1,
        voteChiffre: 'ENC', iv: 'IV', signature: 's' * 64, recuHash: 'r' * 64,
      );
      final json = payload.toJson();
      expect(json.keys, containsAll([
        'voter_hash', 'election_id', 'candidate_id', 'tour',
        'vote_chiffre', 'iv', 'signature', 'recu_hash',
      ]));
      expect(json['tour'], 1);
    });
  });
}
