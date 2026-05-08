import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ══════════════════════════════════════════════════════════════════════════════
// SERVICE — Vérification RAVEL (Registre Electoral Mauritanien)
// Intégration avec la base de données officielle des électeurs
// ══════════════════════════════════════════════════════════════════════════════

enum RavelStatus {
  verified,      // NNI trouvé et valide
  notFound,      // NNI non trouvé dans RAVEL
  suspended,     // Compte suspendu
  notEligible,   // Non éligible (âge, etc.)
  error,         // Erreur système
}

class RavelResult {
  final RavelStatus status;
  final String? nom;
  final String? prenom;
  final String? telephone;
  final String? commune;
  final String? wilaya;
  final String? bureauVote;
  final String? photoUrl;
  final String? message;

  const RavelResult({
    required this.status,
    this.nom,
    this.prenom,
    this.telephone,
    this.commune,
    this.wilaya,
    this.bureauVote,
    this.photoUrl,
    this.message,
  });
}

class RavelVerificationService {
  static final _sb = Supabase.instance.client;

  // ── Vérifier un NNI dans la BDD RAVEL ─────────────────────────────────────
  static Future<RavelResult> verifyNni(String nni) async {
    try {
      // Appel via Edge Function sécurisée
      // (la vérification RAVEL se fait côté serveur)
      final response = await _sb.functions.invoke(
        'verify-ravel-nni',
        body: {'nni': nni},
      );

      if (response.data == null) {
        return const RavelResult(
          status: RavelStatus.error,
          message: 'Erreur de connexion au registre',
        );
      }

      final data = response.data as Map<String, dynamic>;
      final statusStr = data['status'] as String? ?? 'error';

      switch (statusStr) {
        case 'verified':
          return RavelResult(
            status: RavelStatus.verified,
            nom       : data['nom'],
            prenom    : data['prenom'],
            telephone : data['telephone'],
            commune   : data['commune'],
            wilaya    : data['wilaya'],
            bureauVote: data['bureau_vote'],
            photoUrl  : data['photo_url'],
          );
        case 'not_found':
          return const RavelResult(
            status: RavelStatus.notFound,
            message: 'NNI non trouve dans le registre electoral',
          );
        case 'suspended':
          return const RavelResult(
            status: RavelStatus.suspended,
            message: 'Ce NNI est suspendu. Contactez votre administration.',
          );
        case 'not_eligible':
          return const RavelResult(
            status: RavelStatus.notEligible,
            message: 'Non eligible au vote.',
          );
        default:
          return const RavelResult(
            status: RavelStatus.error,
            message: 'Erreur inattendue',
          );
      }
    } catch (e) {
      debugPrint('RavelVerificationService error: $e');
      // En mode dev/test — simuler une réponse positive
      if (kDebugMode && _isTestNni(nni)) {
        return _getTestResult(nni);
      }
      return RavelResult(
        status: RavelStatus.error,
        message: 'Erreur reseau: $e',
      );
    }
  }

  // ── Données test pour DEV ──────────────────────────────────────────────────
  static bool _isTestNni(String nni) =>
      ['1234567890', '9876543210'].contains(nni);

  static RavelResult _getTestResult(String nni) {
    if (nni == '1234567890') {
      return const RavelResult(
        status    : RavelStatus.verified,
        nom       : 'TEST',
        prenom    : 'Electeur',
        telephone : '+22220000001',
        commune   : 'Tevragh-Zeina',
        wilaya    : 'Nouakchott Ouest',
        bureauVote: 'Ecole Tevragh-Zeina A',
      );
    }
    return const RavelResult(
      status    : RavelStatus.verified,
      nom       : 'TEST2',
      prenom    : 'Electrice',
      telephone : '+22220000002',
      commune   : 'Ksar',
      wilaya    : 'Nouakchott Nord',
      bureauVote: 'Ecole Ksar Centre',
    );
  }

  // ── Synchroniser les données RAVEL dans la BDD locale ─────────────────────
  static Future<bool> syncVoterData(String nni, RavelResult result) async {
    if (result.status != RavelStatus.verified) return false;
    try {
      await _sb.from('voters').upsert({
        'nni'         : nni,
        'nom'         : result.nom,
        'prenom'      : result.prenom,
        'telephone'   : result.telephone,
        'is_verified' : true,
        'is_active'   : true,
      }, onConflict: 'nni');
      return true;
    } catch (e) {
      debugPrint('syncVoterData error: $e');
      return false;
    }
  }
}
