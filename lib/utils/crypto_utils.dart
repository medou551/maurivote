import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

/// Utilitaires cryptographiques pour MauriVote
/// - Chiffrement AES-256-GCM du vote
/// - HMAC-SHA256 pour les signatures et le hash électeur
/// - Génération sécurisée des IVs
class CryptoUtils {
  // ── Génération d'un IV aléatoire sécurisé 128 bits ──────────────────────
  static Uint8List generateIV() {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(16, (_) => random.nextInt(256)),
    );
  }

  // ── Dérivation de la clé AES-256 depuis le token de session + sel ────────
  /// La clé AES est dérivée : SHA-256(sessionToken + sel_serveur)
  /// Elle n'est jamais stockée — recalculée à chaque vote
  static Uint8List deriveAesKey(String sessionToken, String selServeur) {
    final input = utf8.encode(sessionToken + selServeur);
    final hash = sha256.convert(input);
    return Uint8List.fromList(hash.bytes);
  }

  // ── Chiffrement AES-256-CBC du candidat choisi ───────────────────────────
  /// Retourne : {vote_chiffre, iv, signature}
  static Map<String, String> chiffrerVote({
    required String candidateId,
    required String electionId,
    required String sessionToken,
    required String selServeur,
  }) {
    // 1. Générer l'IV aléatoire
    final ivBytes = generateIV();
    final iv = enc.IV(ivBytes);

    // 2. Dériver la clé AES-256
    final keyBytes = deriveAesKey(sessionToken, selServeur);
    final key = enc.Key(keyBytes);

    // 3. Construire le payload à chiffrer
    final payload = jsonEncode({
      'candidate_id': candidateId,
      'election_id': electionId,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'nonce': generateNonce(),
    });

    // 4. Chiffrement AES-256-CBC
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(payload, iv: iv);

    // 5. Signature HMAC-SHA256 du payload chiffré
    final signature = hmacSign(
      data: encrypted.base64 + iv.base64,
      key: selServeur,
    );

    return {
      'vote_chiffre': encrypted.base64,
      'iv': iv.base64,
      'signature': signature,
    };
  }

  // ── HMAC-SHA256 ──────────────────────────────────────────────────────────
  /// Signature HMAC-SHA256 : retourne le hash hex 64 caractères
  static String hmacSign({required String data, required String key}) {
    final hmac = Hmac(sha256, utf8.encode(key));
    return hmac.convert(utf8.encode(data)).toString();
  }

  // ── Hash de l'électeur (anonymisation) ──────────────────────────────────
  /// voter_hash = HMAC-SHA256(NNI + election_id, sel_serveur)
  /// Irréversible : impossible de retrouver le NNI depuis le hash
  static String hashVoter({
    required String nni,
    required String electionId,
    required String selServeur,
  }) {
    return hmacSign(
      data: nni + electionId,
      key: selServeur,
    );
  }

  // ── Hash du reçu de vote (pour QR Code) ─────────────────────────────────
  /// recu_hash = SHA-256(voter_hash + vote_chiffre + timestamp)
  static String generateRecuHash({
    required String voterHash,
    required String voteChiffre,
    required String timestamp,
  }) {
    final input = voterHash + voteChiffre + timestamp;
    return sha256.convert(utf8.encode(input)).toString();
  }

  // ── Génération d'un nonce anti-replay ────────────────────────────────────
  static String generateNonce() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  // ── Vérification de signature ────────────────────────────────────────────
  static bool verifySignature({
    required String data,
    required String signature,
    required String key,
  }) {
    final expected = hmacSign(data: data, key: key);
    // Comparaison en temps constant pour éviter les timing attacks
    if (expected.length != signature.length) return false;
    int diff = 0;
    for (int i = 0; i < expected.length; i++) {
      diff |= expected.codeUnitAt(i) ^ signature.codeUnitAt(i);
    }
    return diff == 0;
  }
}
