// ══════════════════════════════════════════════════════════════════════════════
// TESTS UNITAIRES — MauriVote
// Fichier groupant les tests des utilitaires crypto et du validateur NNI
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter_test/flutter_test.dart';
import 'package:maurivote/utils/crypto_utils.dart';
import 'package:maurivote/utils/validators.dart';
import 'package:maurivote/utils/constants.dart';

void main() {
  const testSel = 'sel-test-de-32-caracteres-minimum!!';
  const testNni = '1234567890';
  const testElectionId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
  const testCandidateId = 'a47ac10b-58cc-4372-a567-0e02b2c3d480';
  const testToken = 'mock-session-token-pour-les-tests';

  // ══════════════════════════════════════════════════════════════════════════
  // TESTS : CryptoUtils
  // ══════════════════════════════════════════════════════════════════════════
  group('CryptoUtils', () {

    group('generateIV()', () {
      test('génère un IV de 16 bytes', () {
        final iv = CryptoUtils.generateIV();
        expect(iv.length, equals(16));
      });

      test('deux IVs consécutifs sont différents (aléatoire)', () {
        final iv1 = CryptoUtils.generateIV();
        final iv2 = CryptoUtils.generateIV();
        expect(iv1, isNot(equals(iv2)));
      });

      test('génère 100 IVs tous distincts (qualité aléatoire)', () {
        final ivs = List.generate(100, (_) => CryptoUtils.generateIV());
        final uniqueIvs = ivs.map((iv) => iv.toString()).toSet();
        expect(uniqueIvs.length, equals(100));
      });
    });

    group('deriveAesKey()', () {
      test('retourne une clé de 32 bytes (256 bits)', () {
        final key = CryptoUtils.deriveAesKey(testToken, testSel);
        expect(key.length, equals(32));
      });

      test('deux appels identiques → même clé (déterministe)', () {
        final key1 = CryptoUtils.deriveAesKey(testToken, testSel);
        final key2 = CryptoUtils.deriveAesKey(testToken, testSel);
        expect(key1, equals(key2));
      });

      test('tokens différents → clés différentes', () {
        final key1 = CryptoUtils.deriveAesKey('token-A', testSel);
        final key2 = CryptoUtils.deriveAesKey('token-B', testSel);
        expect(key1, isNot(equals(key2)));
      });

      test('sels différents → clés différentes', () {
        final key1 = CryptoUtils.deriveAesKey(testToken, 'sel-1-de-32-caract-eres-ok!!!!!');
        final key2 = CryptoUtils.deriveAesKey(testToken, 'sel-2-de-32-caract-eres-ok!!!!!');
        expect(key1, isNot(equals(key2)));
      });
    });

    group('chiffrerVote()', () {
      test('le candidat ne figure pas dans le payload chiffré', () {
        final result = CryptoUtils.chiffrerVote(
          candidateId:  testCandidateId,
          electionId:   testElectionId,
          sessionToken: testToken,
          selServeur:   testSel,
        );
        expect(result['vote_chiffre'], isNot(contains(testCandidateId)));
        expect(result['vote_chiffre'], isNot(contains(testElectionId)));
      });

      test('retourne vote_chiffre, iv, et signature', () {
        final result = CryptoUtils.chiffrerVote(
          candidateId: testCandidateId, electionId: testElectionId,
          sessionToken: testToken, selServeur: testSel,
        );
        expect(result.keys, containsAll(['vote_chiffre', 'iv', 'signature']));
        expect(result['vote_chiffre'], isNotEmpty);
        expect(result['iv'], isNotEmpty);
        expect(result['signature']!.length, equals(64)); // SHA-256 hex
      });

      test('deux chiffrements identiques → résultats différents (IV aléatoire)', () {
        final r1 = CryptoUtils.chiffrerVote(
          candidateId: testCandidateId, electionId: testElectionId,
          sessionToken: testToken, selServeur: testSel,
        );
        final r2 = CryptoUtils.chiffrerVote(
          candidateId: testCandidateId, electionId: testElectionId,
          sessionToken: testToken, selServeur: testSel,
        );
        // L'IV aléatoire garantit des chiffrements différents
        expect(r1['iv'], isNot(equals(r2['iv'])));
        expect(r1['vote_chiffre'], isNot(equals(r2['vote_chiffre'])));
      });

      test('la signature est valide', () {
        final result = CryptoUtils.chiffrerVote(
          candidateId: testCandidateId, electionId: testElectionId,
          sessionToken: testToken, selServeur: testSel,
        );
        final isValid = CryptoUtils.verifySignature(
          data: result['vote_chiffre']! + result['iv']!,
          signature: result['signature']!,
          key: testSel,
        );
        expect(isValid, isTrue);
      });
    });

    group('hashVoter()', () {
      test('retourne un hash de 64 caractères (SHA-256 hex)', () {
        final hash = CryptoUtils.hashVoter(
          nni: testNni, electionId: testElectionId, selServeur: testSel,
        );
        expect(hash.length, equals(64));
      });

      test('hash déterministe — mêmes entrées → même hash', () {
        final h1 = CryptoUtils.hashVoter(
            nni: testNni, electionId: testElectionId, selServeur: testSel);
        final h2 = CryptoUtils.hashVoter(
            nni: testNni, electionId: testElectionId, selServeur: testSel);
        expect(h1, equals(h2));
      });

      test('NNIs différents → hashs différents', () {
        final h1 = CryptoUtils.hashVoter(
            nni: '1111111111', electionId: testElectionId, selServeur: testSel);
        final h2 = CryptoUtils.hashVoter(
            nni: '2222222222', electionId: testElectionId, selServeur: testSel);
        expect(h1, isNot(equals(h2)));
      });

      test('le NNI original ne peut pas être retrouvé depuis le hash', () {
        final hash = CryptoUtils.hashVoter(
            nni: testNni, electionId: testElectionId, selServeur: testSel);
        // Le hash ne contient pas le NNI en clair
        expect(hash, isNot(contains(testNni)));
      });
    });

    group('hmacSign()', () {
      test('signature déterministe — mêmes entrées → même résultat', () {
        final s1 = CryptoUtils.hmacSign(data: 'données-test', key: testSel);
        final s2 = CryptoUtils.hmacSign(data: 'données-test', key: testSel);
        expect(s1, equals(s2));
      });

      test('données différentes → signatures différentes', () {
        final s1 = CryptoUtils.hmacSign(data: 'données-A', key: testSel);
        final s2 = CryptoUtils.hmacSign(data: 'données-B', key: testSel);
        expect(s1, isNot(equals(s2)));
      });

      test('retourne 64 caractères hexadécimaux', () {
        final sig = CryptoUtils.hmacSign(data: 'test', key: testSel);
        expect(sig.length, equals(64));
        expect(RegExp(r'^[0-9a-f]+$').hasMatch(sig), isTrue);
      });
    });

    group('verifySignature()', () {
      test('retourne true pour une signature valide', () {
        const data = 'données-importantes';
        final sig = CryptoUtils.hmacSign(data: data, key: testSel);
        expect(CryptoUtils.verifySignature(
            data: data, signature: sig, key: testSel), isTrue);
      });

      test('retourne false pour une signature altérée', () {
        const data = 'données-importantes';
        final sig = CryptoUtils.hmacSign(data: data, key: testSel);
        final alteredSig = '${sig.substring(0, 60)}XXXX'; // Altération
        expect(CryptoUtils.verifySignature(
            data: data, signature: alteredSig, key: testSel), isFalse);
      });

      test('retourne false pour des données altérées', () {
        const data = 'données-originales';
        final sig = CryptoUtils.hmacSign(data: data, key: testSel);
        expect(CryptoUtils.verifySignature(
            data: 'données-altérées', signature: sig, key: testSel), isFalse);
      });
    });

    group('generateNonce()', () {
      test('génère des nonces uniques', () {
        final nonces = List.generate(50, (_) => CryptoUtils.generateNonce());
        final uniqueNonces = nonces.toSet();
        expect(uniqueNonces.length, equals(50));
      });

      test('nonce est une chaîne non vide', () {
        final nonce = CryptoUtils.generateNonce();
        expect(nonce, isNotEmpty);
        expect(nonce.length, greaterThan(10));
      });
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // TESTS : AppValidators
  // ══════════════════════════════════════════════════════════════════════════
  group('AppValidators', () {

    group('validateNni()', () {
      test('accepte un NNI valide de 10 chiffres', () {
        expect(AppValidators.validateNni('1234567890'), isNull);
        expect(AppValidators.validateNni('0000000000'), isNull);
        expect(AppValidators.validateNni('9999999999'), isNull);
      });

      test('rejette un NNI vide', () {
        expect(AppValidators.validateNni(''), isNotNull);
        expect(AppValidators.validateNni(null), isNotNull);
      });

      test('rejette un NNI trop court', () {
        expect(AppValidators.validateNni('123456789'), isNotNull);  // 9 chiffres
        expect(AppValidators.validateNni('1'), isNotNull);
      });

      test('rejette un NNI trop long', () {
        expect(AppValidators.validateNni('12345678901'), isNotNull); // 11 chiffres
      });

      test('rejette un NNI avec des lettres', () {
        expect(AppValidators.validateNni('123456789A'), isNotNull);
        expect(AppValidators.validateNni('ABCDEFGHIJ'), isNotNull);
      });

      test('rejette un NNI avec des espaces', () {
        expect(AppValidators.validateNni('12345 6789'), isNotNull);
      });

      test('rejette un NNI avec des caractères spéciaux', () {
        expect(AppValidators.validateNni('123456789!'), isNotNull);
        expect(AppValidators.validateNni('123-456-78'), isNotNull);
      });
    });

    group('validatePhone()', () {
      test('accepte un numéro mauritanien valide', () {
        expect(AppValidators.validatePhone('+22220001234'), isNull);
        expect(AppValidators.validatePhone('+22236000000'), isNull);
      });

      test('rejette un numéro sans code pays', () {
        expect(AppValidators.validatePhone('20001234'), isNotNull);
      });

      test('rejette un numéro avec mauvais code pays', () {
        expect(AppValidators.validatePhone('+33612345678'), isNotNull);
      });

      test('rejette un numéro trop court', () {
        expect(AppValidators.validatePhone('+2222000'), isNotNull);
      });
    });

    group('isElectionActive()', () {
      test('retourne true si maintenant est dans la période', () {
        final now = DateTime.now().toUtc();
        expect(AppValidators.isElectionActive(
          ouverture: now.subtract(const Duration(hours: 2)),
          fermeture: now.add(const Duration(hours: 8)),
        ), isTrue);
      });

      test('retourne false si pas encore ouverte', () {
        final now = DateTime.now().toUtc();
        expect(AppValidators.isElectionActive(
          ouverture: now.add(const Duration(hours: 1)),
          fermeture: now.add(const Duration(hours: 9)),
        ), isFalse);
      });

      test('retourne false si déjà fermée', () {
        final now = DateTime.now().toUtc();
        expect(AppValidators.isElectionActive(
          ouverture: now.subtract(const Duration(hours: 10)),
          fermeture: now.subtract(const Duration(hours: 1)),
        ), isFalse);
      });
    });

    group('isValidUuid()', () {
      test('accepte un UUID v4 valide', () {
        expect(AppValidators.isValidUuid(testElectionId), isTrue);
        expect(AppValidators.isValidUuid('550e8400-e29b-41d4-a716-446655440000'), isTrue);
      });

      test('rejette une chaîne non-UUID', () {
        expect(AppValidators.isValidUuid('not-a-uuid'), isFalse);
        expect(AppValidators.isValidUuid(''), isFalse);
        expect(AppValidators.isValidUuid(null), isFalse);
        expect(AppValidators.isValidUuid(testNni), isFalse);
      });
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // TESTS : Modèles de données
  // ══════════════════════════════════════════════════════════════════════════
  group('Modèle Election', () {
    late Map<String, dynamic> electionJson;

    setUp(() {
      electionJson = {
        'id': testElectionId,
        'titre_fr': 'Élection Présidentielle 2024',
        'titre_ar': 'الانتخابات الرئاسية 2024',
        'type_election': 'presidentielle',
        'nb_tours': 2,
        'date_ouverture': DateTime.now()
            .subtract(const Duration(hours: 2)).toIso8601String(),
        'date_fermeture': DateTime.now()
            .add(const Duration(hours: 8)).toIso8601String(),
        'statut': 'en_cours',
        'tour_actuel': 1,
        'is_public': true,
      };
    });

    test('désérialise correctement depuis JSON', () {
      final election = Election.fromJson(electionJson);
      expect(election.id, equals(testElectionId));
      expect(election.titreFr, equals('Élection Présidentielle 2024'));
      expect(election.type, equals(ElectionType.presidentielle));
      expect(election.statut, equals(ElectionStatus.en_cours));
    });

    test('isVotable retourne true quand ouverte et en_cours', () {
      final election = Election.fromJson(electionJson);
      expect(election.isVotable, isTrue);
    });

    test('isVotable retourne false quand terminée', () {
      electionJson['statut'] = 'terminee';
      electionJson['date_fermeture'] = DateTime.now()
          .subtract(const Duration(hours: 1)).toIso8601String();
      final election = Election.fromJson(electionJson);
      expect(election.isVotable, isFalse);
    });
  });
}

// Import nécessaire pour les tests de modèle
import 'package:maurivote/models/models.dart';
