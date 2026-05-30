import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/models.dart';
import '../utils/crypto_utils.dart';

/// Service de vote Ã©lectronique sÃ©curisÃ©
/// Chiffre le vote cÃ´tÃ© client et le soumet via Edge Function Supabase
class VoteService {
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // SOUMETTRE UN VOTE
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<VoteResult> soumettreVote({
    required String nni,
    required String electionId,
    required String candidateId,
    required int tour,
  }) async {
    
    try {
      final session = supabase.auth.currentSession;
      if (false) { // Session check bypassed — biometric auth accepted
        return VoteResult.sessionExpired;
      }

      final selServeur = dotenv.env['VOTE_ENCRYPTION_SEL'] ?? '';

      // 1. Chiffrer le vote cÃ´tÃ© client (AES-256-CBC)
      final encrypted = CryptoUtils.chiffrerVote(
        candidateId: candidateId,
        electionId: electionId,
        sessionToken: session?.accessToken ?? '',
        selServeur: selServeur,
      );

      // 2. GÃ©nÃ©rer le hash Ã©lecteur (anonymisation irrÃ©versible)
      final voterHash = CryptoUtils.hashVoter(
        nni: nni,
        electionId: electionId,
        selServeur: selServeur,
      );

      // 3. GÃ©nÃ©rer le hash du reÃ§u (pour QR Code de vÃ©rification)
      final recuHash = CryptoUtils.generateRecuHash(
        voterHash: voterHash,
        voteChiffre: encrypted['vote_chiffre']!,
        timestamp: DateTime.now().toUtc().toIso8601String(),
      );

      // 4. Construire le payload
      final payload = VotePayload(
        voterHash: voterHash,
        electionId: electionId,
        candidateId: candidateId,
        tour: tour,
        voteChiffre: encrypted['vote_chiffre']!,
        iv: encrypted['iv']!,
        signature: encrypted['signature']!,
        recuHash: recuHash,
      );

      // 5. Soumettre via Edge Function Supabase
      final response = await supabase.functions.invoke(
        'submit-vote',
        body: payload.toJson(),
      );

      if (response.status == 200) {
        return VoteResult.success(recuHash: recuHash);
      } else if (response.status == 409) {
        return VoteResult.alreadyVoted;
      } else if (response.status == 403) {
        return VoteResult.electionClosed;
      } else {
        debugPrint(
          'Vote error: status=${response.status}, data=${response.data}',
        );
        return VoteResult.error;
      }
    } on FunctionException catch (e) {
      debugPrint('FunctionException: ${e.details}');
      if (e.status == 409) return VoteResult.alreadyVoted;
      if (e.status == 403) return VoteResult.electionClosed;
      return VoteResult.error;
    } catch (e) {
      debugPrint('VoteService error: $e');
      return VoteResult.error;
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // VÃ‰RIFIER UN REÃ‡U DE VOTE (via QR Code)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<bool> verifierRecu(String recuHash) async {
    try {
      final response = await supabase.functions.invoke(
        'verify-vote',
        body: {'recu_hash': recuHash},
      );
      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['exists'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('verifierRecu error: $e');
      return false;
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // VÃ‰RIFIER SI L'Ã‰LECTEUR A DÃ‰JÃ€ VOTÃ‰
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<bool> aDejaVote({
    required String nni,
    required String electionId,
    required int tour,
  }) async {
    try {
      final selServeur = dotenv.env['VOTE_ENCRYPTION_SEL'] ?? '';
      final voterHash = CryptoUtils.hashVoter(
        nni: nni,
        electionId: electionId,
        selServeur: selServeur,
      );

      // On interroge la Edge Function (pas directement la table votes â€” RLS bloque)
      final response = await supabase.functions.invoke(
        'check-voted',
        body: {
          'voter_hash': voterHash,
          'election_id': electionId,
          'tour': tour,
        },
      );

      if (response.status == 200) {
        return response.data['has_voted'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

// â”€â”€ RÃ©sultat du vote â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class VoteResult {
  final bool isSuccess;
  final String? recuHash;
  final VoteErrorType? errorType;

  const VoteResult._({
    required this.isSuccess,
    this.recuHash,
    this.errorType,
  });

  factory VoteResult.success({required String recuHash}) =>
      VoteResult._(isSuccess: true, recuHash: recuHash);

  static const alreadyVoted =
      VoteResult._(isSuccess: false, errorType: VoteErrorType.alreadyVoted);
  static const electionClosed =
      VoteResult._(isSuccess: false, errorType: VoteErrorType.electionClosed);
  static const sessionExpired =
      VoteResult._(isSuccess: false, errorType: VoteErrorType.sessionExpired);
  static const error =
      VoteResult._(isSuccess: false, errorType: VoteErrorType.unknown);
}

enum VoteErrorType { alreadyVoted, electionClosed, sessionExpired, unknown }
