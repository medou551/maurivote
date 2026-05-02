import 'constants.dart';

/// Utilitaires de validation pour MauriVote
class AppValidators {
  // ── Validation NNI ────────────────────────────────────────────────────────
  /// Valide le format du NNI mauritanien (10 chiffres exactement)
  static String? validateNni(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le NNI est obligatoire';
    }
    if (value.length != AppConstants.nniLength) {
      return 'Le NNI doit contenir exactement 10 chiffres';
    }
    if (!RegExp(AppConstants.nniRegex).hasMatch(value)) {
      return 'Le NNI ne doit contenir que des chiffres';
    }
    return null; // Valide
  }

  // ── Validation téléphone mauritanien ──────────────────────────────────────
  /// Format : +222XXXXXXXX (8 chiffres après le code pays)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le numéro de téléphone est obligatoire';
    }
    final cleaned = value.replaceAll(' ', '').replaceAll('-', '');
    if (!RegExp(AppConstants.phoneRegex).hasMatch(cleaned)) {
      return 'Format attendu : +222 XX XX XX XX';
    }
    return null;
  }

  // ── Validation code OTP ───────────────────────────────────────────────────
  static String? validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le code OTP est obligatoire';
    }
    if (value.length != AppConstants.otpLength) {
      return 'Le code OTP doit contenir ${AppConstants.otpLength} chiffres';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'Le code OTP ne contient que des chiffres';
    }
    return null;
  }

  // ── Vérification de période électorale ───────────────────────────────────
  /// Vérifie si une élection est en cours (période de vote active)
  static bool isElectionActive({
    required DateTime ouverture,
    required DateTime fermeture,
  }) {
    final now = DateTime.now().toUtc();
    return now.isAfter(ouverture) && now.isBefore(fermeture);
  }

  // ── Validation du format UUID ─────────────────────────────────────────────
  static bool isValidUuid(String? value) {
    if (value == null || value.isEmpty) return false;
    return RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(value);
  }

  // ── Validation email ──────────────────────────────────────────────────────
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email obligatoire';
    if (!RegExp(r'^[\w\-.]+@[\w\-]+\.\w+$').hasMatch(value)) {
      return 'Format email invalide';
    }
    return null;
  }
}
