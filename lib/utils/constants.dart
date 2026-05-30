/// Constantes globales de l'application MauriVote
class AppConstants {
  static const int sessionTimeoutMinutes = 30;
  // â”€â”€ Validation NNI â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// Format NNI mauritanien : exactement 10 chiffres
  static const nniRegex = r'^\d{10}$';
  static const nniLength = 10;

  /// Format tÃ©lÃ©phone mauritanien : +222 suivi de 8 chiffres
  static const phoneRegex = r'^\+222[0-9]{8}$';

  // â”€â”€ OTP â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const otpLength = 6;
  static const otpExpirySeconds = 120; // 2 minutes
  static const otpMaxAttempts = 3;
  static const otpBlockDurationMin = 30; // Blocage aprÃ¨s 3 Ã©checs

  // â”€â”€ Session â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const sessionTimeoutMin =
      15; // DÃ©connexion aprÃ¨s 15 min d'inactivitÃ©
  static const jwtExpirySeconds = 3600; // 1 heure

  // â”€â”€ RÃ©seau â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const apiTimeoutSeconds = 30;
  static const realtimeChannel = 'resultats';
  static const maxRetryAttempts = 3;

  // â”€â”€ Hive (stockage local) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const boxElections = 'elections_cache';
  static const boxVotesPending = 'votes_pending';
  static const boxUserPrefs = 'user_prefs';

  // â”€â”€ ClÃ©s de prÃ©fÃ©rences â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const prefLanguage = 'app_language';
  static const prefOnboardingDone = 'onboarding_done';
  static const prefBiometricEnabled = 'biometric_enabled';
  static const prefDarkMode = 'dark_mode';

  // â”€â”€ Langues supportÃ©es â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const supportedLocales = ['fr', 'ar', 'ff'];
  static const defaultLocale = 'fr';

  // â”€â”€ Types d'Ã©lections â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const electionTypes = {
    'presidentielle': 'PrÃ©sidentielle',
    'legislative': 'LÃ©gislative',
    'municipale': 'Municipale',
    'regionale': 'RÃ©gionale',
    'referendum': 'RÃ©fÃ©rendum',
  };

  // â”€â”€ Statuts des Ã©lections â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const statusPlanifiee = 'planifiee';
  static const statusEnCours = 'en_cours';
  static const statusTerminee = 'terminee';
  static const statusAnnulee = 'annulee';

  // â”€â”€ Wilayas de Mauritanie (13 wilayas + district Nouakchott) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  // â”€â”€ Animations Lottie â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const animSplash = 'assets/animations/splash.json';
  static const animVoteSuccess = 'assets/animations/vote_success.json';
  static const animLoading = 'assets/animations/loading.json';
  static const animError = 'assets/animations/error.json';
  static const animOffline = 'assets/animations/offline.json';

  // â”€â”€ Images â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const logoMauriVote = 'assets/images/logo_maurivote.png';
  static const flagMauritanie = 'assets/images/flag_mauritanie.png';
  static const placeholderUser = 'assets/images/placeholder_user.png';

  // â”€â”€ Anti-replay (nonce) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const nonceValiditySeconds = 30;

  // â”€â”€ SÃ©curitÃ© â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const aesKeySize = 32; // 256 bits
  static const aesIvSize = 16; // 128 bits
  static const hmacHashSize = 64; // SHA-256 hex = 64 chars

  // â”€â”€ Pagination â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const pageSize = 20;

  // â”€â”€ Support contact â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const supportPhone1 = '+222 22 93 47 67';
  static const supportPhone2 = '+222 32 05 50 59';
}
