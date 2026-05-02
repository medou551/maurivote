/// Constantes globales de l'application MauriVote
class AppConstants {
  // ── Validation NNI ────────────────────────────────────────────────────────
  /// Format NNI mauritanien : exactement 10 chiffres
  static const nniRegex = r'^\d{10}$';
  static const nniLength = 10;

  /// Format téléphone mauritanien : +222 suivi de 8 chiffres
  static const phoneRegex = r'^\+222[0-9]{8}$';

  // ── OTP ───────────────────────────────────────────────────────────────────
  static const otpLength           = 6;
  static const otpExpirySeconds    = 120;   // 2 minutes
  static const otpMaxAttempts      = 3;
  static const otpBlockDurationMin = 30;    // Blocage après 3 échecs

  // ── Session ───────────────────────────────────────────────────────────────
  static const sessionTimeoutMin   = 15;    // Déconnexion après 15 min d'inactivité
  static const jwtExpirySeconds    = 3600;  // 1 heure

  // ── Réseau ────────────────────────────────────────────────────────────────
  static const apiTimeoutSeconds   = 30;
  static const realtimeChannel     = 'resultats';
  static const maxRetryAttempts    = 3;

  // ── Hive (stockage local) ─────────────────────────────────────────────────
  static const boxElections        = 'elections_cache';
  static const boxVotesPending     = 'votes_pending';
  static const boxUserPrefs        = 'user_prefs';

  // ── Clés de préférences ───────────────────────────────────────────────────
  static const prefLanguage        = 'app_language';
  static const prefOnboardingDone  = 'onboarding_done';
  static const prefBiometricEnabled= 'biometric_enabled';
  static const prefDarkMode        = 'dark_mode';

  // ── Langues supportées ────────────────────────────────────────────────────
  static const supportedLocales = ['fr', 'ar', 'ff'];
  static const defaultLocale    = 'fr';

  // ── Types d'élections ─────────────────────────────────────────────────────
  static const electionTypes = {
    'presidentielle': 'Présidentielle',
    'legislative':    'Législative',
    'municipale':     'Municipale',
    'regionale':      'Régionale',
    'referendum':     'Référendum',
  };

  // ── Statuts des élections ─────────────────────────────────────────────────
  static const statusPlanifiee = 'planifiee';
  static const statusEnCours   = 'en_cours';
  static const statusTerminee  = 'terminee';
  static const statusAnnulee   = 'annulee';

  // ── Wilayas de Mauritanie (13 wilayas + district Nouakchott) ─────────────
  static const wilayas = [
    'Hodh Ech Chargui',
    'Hodh El Gharbi',
    'Assaba',
    'Gorgol',
    'Brakna',
    'Trarza',
    'Adrar',
    'Dakhlet Nouadhibou',
    'Tagant',
    'Guidimagha',
    'Tiris Zemmour',
    'Inchiri',
    'Nouakchott Nord',
    'Nouakchott Ouest',
    'Nouakchott Sud',
  ];

  // ── Animations Lottie ─────────────────────────────────────────────────────
  static const animSplash       = 'assets/animations/splash.json';
  static const animVoteSuccess  = 'assets/animations/vote_success.json';
  static const animLoading      = 'assets/animations/loading.json';
  static const animError        = 'assets/animations/error.json';
  static const animOffline      = 'assets/animations/offline.json';

  // ── Images ────────────────────────────────────────────────────────────────
  static const logoMauriVote    = 'assets/images/logo_maurivote.png';
  static const flagMauritanie   = 'assets/images/flag_mauritanie.png';
  static const placeholderUser  = 'assets/images/placeholder_user.png';

  // ── Anti-replay (nonce) ───────────────────────────────────────────────────
  static const nonceValiditySeconds = 30;

  // ── Sécurité ──────────────────────────────────────────────────────────────
  static const aesKeySize    = 32;    // 256 bits
  static const aesIvSize     = 16;    // 128 bits
  static const hmacHashSize  = 64;    // SHA-256 hex = 64 chars

  // ── Pagination ────────────────────────────────────────────────────────────
  static const pageSize = 20;

  // ── Support contact ───────────────────────────────────────────────────────
  static const ceniWebsite  = 'https://myceni.org';
  static const ceniPhone    = '+222 45 25 25 25';
  static const ceniEmail    = 'contact@ceni.mr';
}
