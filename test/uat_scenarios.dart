// ══════════════════════════════════════════════════════════════════════════════
// SCÉNARIOS UAT — MauriVote
// User Acceptance Testing — 8 profils de testeurs mauritaniens
// Sprint 4 — J22
// ══════════════════════════════════════════════════════════════════════════════

/// Profils des 8 testeurs représentatifs
const uatProfiles = [
  UatProfile(
    id: 'T01',
    nom: 'Mohamed Ould Abdallah',
    profil: 'Homme, 45 ans, Nouakchott, arabe, fonctionnaire',
    langue: 'ar',
    device: 'Samsung Galaxy A14 (Android 13)',
    competence: 'Intermédiaire',
    objectif: 'Voter en arabe (RTL), vérifier le reçu QR',
  ),
  UatProfile(
    id: 'T02',
    nom: 'Fatimata Ba',
    profil: 'Femme, 28 ans, Kaédi, Pulaar, commerçante',
    langue: 'ff',
    device: 'Tecno Spark 10 (Android 13)',
    competence: 'Débutant',
    objectif: 'Première utilisation en Pulaar, naviguer sans aide',
  ),
  UatProfile(
    id: 'T03',
    nom: 'Aminata Diallo',
    profil: 'Femme, 22 ans, Nouakchott, française, étudiante',
    langue: 'fr',
    device: 'Xiaomi Redmi Note 12 (Android 13)',
    competence: 'Avancé',
    objectif: 'Flux complet, vérifier résultats temps réel',
  ),
  UatProfile(
    id: 'T04',
    nom: 'Ahmed Salem Ould Cheikh',
    profil: 'Homme, 68 ans, Atar, arabe, retraité',
    langue: 'ar',
    device: 'Nokia G11 (Android 12)',
    competence: 'Débutant',
    objectif: 'Accessibilité (taille police, contraste), lisibilité',
  ),
  UatProfile(
    id: 'T05',
    nom: 'Marième Mint Baba',
    profil: 'Femme, 35 ans, Rosso, française, enseignante',
    langue: 'fr',
    device: 'Huawei Y9s (Android 10)',
    competence: 'Intermédiaire',
    objectif: 'Test mode hors-ligne (zone rurale, réseau 2G)',
  ),
  UatProfile(
    id: 'T06',
    nom: 'Sidy Diaw',
    profil: 'Homme, 30 ans, Diaspora (Paris), français',
    langue: 'fr',
    device: 'iPhone 14 (iOS 17)',
    competence: 'Expert',
    objectif: 'Test iOS, vote diaspora, biométrie Face ID',
  ),
  UatProfile(
    id: 'T07',
    nom: 'Khadija Mint Ahmed',
    profil: 'Femme, 40 ans, Nouadhibou, arabe, pêcheuse',
    langue: 'ar',
    device: 'Samsung Galaxy A05 (Android 13)',
    competence: 'Débutant',
    objectif: 'Accessibilité PMR, test bureau de vote sur carte',
  ),
  UatProfile(
    id: 'T08',
    nom: 'Boubacar Traoré',
    profil: 'Homme, 25 ans, Kiffa, Pulaar, agriculteur',
    langue: 'ff',
    device: 'Infinix Hot 30 (Android 13)',
    competence: 'Intermédiaire',
    objectif: 'Test Pulaar complet, notifications FCM',
  ),
];

/// Cas de test UAT — 15 scénarios
const uatTestCases = [
  UatTestCase(
    id: 'UAT-001',
    titre: 'Première installation et onboarding',
    steps: [
      'Installer l\'APK MauriVote sur le device',
      'Ouvrir l\'application pour la première fois',
      'Swiper les 3 slides d\'onboarding',
      'Appuyer sur "Commencer"',
    ],
    expected: 'L\'écran de connexion NNI s\'affiche correctement',
    critere: 'Critique',
    concerne: ['T01', 'T02', 'T03', 'T04', 'T05', 'T06', 'T07', 'T08'],
  ),
  UatTestCase(
    id: 'UAT-002',
    titre: 'Connexion avec NNI valide + OTP',
    steps: [
      'Saisir NNI valide de 10 chiffres',
      'Appuyer sur "Recevoir le code SMS"',
      'Attendre le SMS (max 30 secondes)',
      'Saisir les 6 chiffres du code OTP',
      'Appuyer sur "Valider"',
    ],
    expected: 'Accès à l\'écran d\'accueil avec les élections disponibles',
    critere: 'Critique',
    concerne: ['T01', 'T02', 'T03', 'T04', 'T05', 'T06', 'T07', 'T08'],
  ),
  UatTestCase(
    id: 'UAT-003',
    titre: 'Validation biométrie (empreinte/Face ID)',
    steps: [
      'Après connexion OTP, l\'écran biométrie s\'affiche',
      'Appuyer sur "Valider avec la biométrie"',
      'Présenter l\'empreinte ou le visage',
    ],
    expected: 'Accès accordé et navigation vers l\'accueil',
    critere: 'Haute',
    concerne: ['T03', 'T06'],
  ),
  UatTestCase(
    id: 'UAT-004',
    titre: 'Changement de langue arabe (RTL)',
    steps: [
      'Depuis l\'accueil, appuyer sur le sélecteur de langue',
      'Choisir "العربية"',
      'Observer le changement d\'interface',
    ],
    expected: 'Interface complète en arabe, écriture de droite à gauche, police Cairo',
    critere: 'Critique',
    concerne: ['T01', 'T04', 'T07'],
  ),
  UatTestCase(
    id: 'UAT-005',
    titre: 'Changement de langue Pulaar',
    steps: [
      'Sélectionner "Pulaar" dans le sélecteur de langue',
      'Vérifier les labels de navigation',
      'Vérifier les messages d\'erreur',
    ],
    expected: 'Interface en Pulaar avec textes corrects',
    critere: 'Haute',
    concerne: ['T02', 'T08'],
  ),
  UatTestCase(
    id: 'UAT-006',
    titre: 'Navigation dans la liste des élections',
    steps: [
      'Depuis l\'accueil, voir la liste des élections',
      'Tester les filtres : Toutes / En cours / À venir / Terminées',
      'Appuyer sur une élection pour voir le détail',
    ],
    expected: 'Filtres fonctionnels, détail élection avec candidats affichés',
    critere: 'Critique',
    concerne: ['T01', 'T02', 'T03', 'T04', 'T05', 'T06', 'T07', 'T08'],
  ),
  UatTestCase(
    id: 'UAT-007',
    titre: 'Flux de vote complet',
    steps: [
      'Accéder au détail d\'une élection en cours',
      'Appuyer sur "Voter maintenant"',
      'Sélectionner un candidat',
      'Appuyer sur "Confirmer mon vote"',
      'Cocher les 2 cases de confirmation',
      'Appuyer sur "Soumettre mon vote"',
    ],
    expected: 'Reçu de vote avec QR Code affiché, animation de succès',
    critere: 'Critique',
    concerne: ['T01', 'T02', 'T03', 'T05', 'T06', 'T07', 'T08'],
  ),
  UatTestCase(
    id: 'UAT-008',
    titre: 'Vérification du reçu QR',
    steps: [
      'Après avoir voté, noter le hash du reçu',
      'Appuyer sur "Copier" pour copier le hash',
      'Appuyer sur "Partager" pour partager',
      'Scanner le QR Code avec un autre appareil',
    ],
    expected: 'Hash copié dans le presse-papier, partage fonctionnel, QR Code scannable',
    critere: 'Haute',
    concerne: ['T03', 'T06'],
  ),
  UatTestCase(
    id: 'UAT-009',
    titre: 'Blocage du double vote',
    steps: [
      'Après avoir voté, retourner sur l\'élection',
      'Tenter de voter à nouveau',
    ],
    expected: 'Message "Vous avez déjà voté pour cette élection" affiché',
    critere: 'Critique',
    concerne: ['T03', 'T06'],
  ),
  UatTestCase(
    id: 'UAT-010',
    titre: 'Résultats en temps réel',
    steps: [
      'Accéder à l\'onglet Résultats',
      'Sélectionner une élection active',
      'Observer le badge LIVE et les graphiques',
      'Attendre une mise à jour (si possible)',
    ],
    expected: 'Graphique camembert + barres animées, badge EN DIRECT visible',
    critere: 'Haute',
    concerne: ['T03', 'T06'],
  ),
  UatTestCase(
    id: 'UAT-011',
    titre: 'Profil électeur',
    steps: [
      'Accéder à l\'onglet Profil',
      'Vérifier les informations personnelles',
      'Appuyer sur "Mon bureau de vote"',
    ],
    expected: 'Données affichées (NNI masqué), badge "Électeur vérifié", carte bureau',
    critere: 'Haute',
    concerne: ['T01', 'T02', 'T03', 'T04', 'T05', 'T07', 'T08'],
  ),
  UatTestCase(
    id: 'UAT-012',
    titre: 'Mode hors-ligne (réseau coupé)',
    steps: [
      'Couper le réseau Wi-Fi et données mobiles',
      'Observer la bannière "Mode hors-ligne"',
      'Naviguer dans l\'application (données en cache)',
      'Rétablir le réseau',
      'Observer la synchronisation automatique',
    ],
    expected: 'Bannière orange visible, données en cache disponibles, sync automatique',
    critere: 'Haute',
    concerne: ['T05'],
  ),
  UatTestCase(
    id: 'UAT-013',
    titre: 'Accessibilité — Taille de police et contraste',
    steps: [
      'Dans les paramètres Android, augmenter la taille de police à "Très grande"',
      'Rouvrir l\'application',
      'Vérifier la lisibilité de tous les écrans',
    ],
    expected: 'Textes lisibles, pas de troncature, boutons accessibles',
    critere: 'Haute',
    concerne: ['T04', 'T07'],
  ),
  UatTestCase(
    id: 'UAT-014',
    titre: 'OTP invalide — Gestion des erreurs',
    steps: [
      'Saisir un NNI valide',
      'Recevoir le code OTP',
      'Saisir un code incorrect (111111)',
      'Observer le message d\'erreur',
      'Saisir à nouveau le mauvais code',
      'Observer le compteur de tentatives',
    ],
    expected: 'Message d\'erreur clair, compteur 2/3 puis 3/3, blocage après 3 erreurs',
    critere: 'Haute',
    concerne: ['T01', 'T03'],
  ),
  UatTestCase(
    id: 'UAT-015',
    titre: 'Déconnexion et reconnexion',
    steps: [
      'Depuis le profil, appuyer sur "Déconnexion"',
      'Confirmer dans le dialogue',
      'Se reconnecter avec le même NNI',
    ],
    expected: 'Déconnexion propre, retour à l\'écran de login, reconnexion possible',
    critere: 'Critique',
    concerne: ['T01', 'T02', 'T03', 'T06'],
  ),
];

/// Grille de collecte des retours UAT
const uatFeedbackQuestions = [
  'Sur une échelle de 1 à 5, notez la facilité d\'utilisation de l\'application',
  'La connexion par NNI + SMS vous semble-t-elle sécurisée ? (Oui/Non)',
  'L\'interface dans votre langue est-elle compréhensible ? (1-5)',
  'Avez-vous eu des difficultés lors du vote ? Si oui, lesquelles ?',
  'Le reçu de vote vous rassure-t-il sur la prise en compte de votre vote ? (Oui/Non)',
  'Utiliseriez-vous cette application lors d\'une vraie élection ? (Oui/Non/Peut-être)',
  'Quel est l\'aspect à améliorer en priorité ?',
  'Score global de satisfaction (1-10)',
];

/// Classe représentant un profil de testeur
class UatProfile {
  final String id, nom, profil, langue, device, competence, objectif;
  const UatProfile({
    required this.id, required this.nom, required this.profil,
    required this.langue, required this.device,
    required this.competence, required this.objectif,
  });
}

/// Classe représentant un cas de test UAT
class UatTestCase {
  final String id, titre, expected, critere;
  final List<String> steps;
  final List<String> concerne;
  const UatTestCase({
    required this.id, required this.titre, required this.steps,
    required this.expected, required this.critere, required this.concerne,
  });
}

/// Résultats UAT agrégés (à remplir après les tests)
class UatResults {
  final Map<String, int> satisfactionScores = {};
  final Map<String, bool> testsPassed = {};
  final Map<String, String> feedbacks = {};

  /// Taux de réussite global
  double get passRate {
    if (testsPassed.isEmpty) return 0;
    final passed = testsPassed.values.where((v) => v).length;
    return passed / testsPassed.length;
  }

  /// Score moyen de satisfaction
  double get avgSatisfaction {
    if (satisfactionScores.isEmpty) return 0;
    return satisfactionScores.values.reduce((a, b) => a + b) /
        satisfactionScores.length;
  }
}
