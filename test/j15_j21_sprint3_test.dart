import 'package:flutter_test/flutter_test.dart';
import 'package:maurivote/models/models.dart';
import 'package:maurivote/utils/crypto_utils.dart';
import 'package:maurivote/utils/validators.dart';
import 'package:maurivote/viewmodels/resultats_viewmodel.dart';
import 'package:maurivote/viewmodels/vote_viewmodel.dart';

/// Tests Sprint 3 — J15–J21
/// Résultats temps réel, sécurité, performance, offline
void main() {

  group('ResultatsState — Temps Réel', () {
    test('initial → loading, vide, non realtime', () {
      final s = ResultatsState.initial();
      expect(s.status, ResultatsStatus.loading);
      expect(s.resultats, isEmpty);
      expect(s.isRealtime, isFalse);
      expect(s.updateCount, 0);
      expect(s.hasData, isFalse);
    });

    test('copyWith préserve les champs non modifiés', () {
      final s = ResultatsState.initial()
          .copyWith(status: ResultatsStatus.live, isRealtime: true, updateCount: 5);
      expect(s.status, ResultatsStatus.live);
      expect(s.updateCount, 5);
      expect(s.resultats, isEmpty);
    });

    test('hasData true si resultats non vides', () {
      final r = Resultat.fromJson({'election_id':'e1','candidate_id':'c1',
        'tour':1,'nb_votes':500,'pourcentage':50.0,'valide_ceni':true,'valide_cc':false});
      final s = ResultatsState.initial().copyWith(
        status: ResultatsStatus.snapshot, resultats: [r]);
      expect(s.hasData, isTrue);
    });

    test('4 statuts distincts', () =>
        expect(ResultatsStatus.values.toSet().length, ResultatsStatus.values.length));
  });

  group('ParticipationStats — Calculs', () {
    test('empty() retourne valeurs nulles', () {
      final s = ParticipationStats.empty();
      expect(s.totalVotes, 0);
      expect(s.hasAbsoluteMajority, isFalse);
      expect(s.nbCandidates, 0);
    });

    test('gap calculé correctement', () {
      final s = ParticipationStats(totalVotes: 1000, leaderId: 'c1',
          leaderPct: 60.0, secondId: 'c2', secondPct: 40.0,
          hasAbsoluteMajority: true, nbCandidates: 2);
      expect(s.gap, closeTo(20.0, 0.01));
      expect(s.get isClose, isFalse);
    });

    test('isClose = true si gap < 5%', () {
      final s = ParticipationStats(totalVotes: 1000, leaderId: 'c1',
          leaderPct: 50.2, secondId: 'c2', secondPct: 48.5,
          hasAbsoluteMajority: false, nbCandidates: 2);
      expect(s.gap, lessThan(5.0));
      expect(s.get isClose, isTrue);
    });

    test('hasAbsoluteMajority si > 50%', () {
      expect(ParticipationStats(totalVotes: 100, leaderId: 'c1', leaderPct: 50.1,
          secondPct: 49.9, hasAbsoluteMajority: true, nbCandidates: 2).hasAbsoluteMajority,
          isTrue);
    });
  });

  group('Sécurité Approfondie', () {
    const sel = 'sel-test-de-32-caracteres-minimum!!';
    const eId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';

    test('100 NNIs différents → 100 hashs distincts', () {
      final set = List.generate(100, (i) => CryptoUtils.hashVoter(
          nni: i.toString().padLeft(10,'0'), electionId: eId, selServeur: sel)).toSet();
      expect(set.length, 100);
    });

    test('Altérer IV invalide la signature', () {
      final enc = CryptoUtils.chiffrerVote(
          candidateId: 'c1', electionId: eId, sessionToken: 'tok', selServeur: sel);
      expect(CryptoUtils.verifySignature(
          data: enc['vote_chiffre']! + 'TAMPERED',
          signature: enc['signature']!, key: sel), isFalse);
    });

    test('1000 nonces distincts', () {
      expect(List.generate(1000, (_) => CryptoUtils.generateNonce()).toSet().length, 1000);
    });

    test('Injections SQL rejetées dans NNI', () {
      for (final inj in ["1' OR '1'='1", '"; DROP TABLE voters;', '<script>']) {
        expect(AppValidators.validateNni(inj), isNotNull);
      }
    });

    test('UUIDs invalides rejetés', () {
      for (final bad in ['not-uuid', 'injection;DROP TABLE', '', null]) {
        expect(AppValidators.isValidUuid(bad), isFalse);
      }
    });
  });

  group('Performance Cryptographie', () {
    const sel = 'sel-test-perf-32-caracteres-ok!!!';

    test('100 chiffrements AES < 1 seconde', () {
      final sw = Stopwatch()..start();
      for (int i = 0; i < 100; i++) {
        CryptoUtils.chiffrerVote(candidateId: 'c$i', electionId: 'e1',
            sessionToken: 'tok', selServeur: sel);
      }
      expect(sw.elapsed.inMilliseconds, lessThan(1000));
    });

    test('1000 HMAC-SHA256 < 500ms', () {
      final sw = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        CryptoUtils.hmacSign(data: 'data-$i', key: sel);
      }
      expect(sw.elapsed.inMilliseconds, lessThan(500));
    });
  });

  group('VoteState Offline Sprint 3', () {
    test('Offline avec reçu en attente', () {
      final s = VoteState.initial().copyWith(
          status: VoteStatus.offline, isOfflineQueued: true, recuHash: 'r' * 64);
      expect(s.isOfflineQueued, isTrue);
      expect(s.recuHash, isNotNull);
    });
  });
}
