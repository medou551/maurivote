import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/models.dart';

bool get isDevBypass => dotenv.env['DEV_BYPASS'] == 'true';
bool devSessionActive = false;

// ── Électeur de test ──────────────────────────────────────────────────────────
final mockVoter = Voter(
  id: 'test-voter-001',
  nni: '1234567890',
  nom: 'TEST',
  prenom: 'Électeur',
  dateNaissance: DateTime(1990, 1, 1),
  sexe: 'M',
  communeId: 'NKT-001',
  wilayaId: 'MR-14',
  bureauVoteId: 'NKT-001-001',
  telephone: '+22220000001',
  isVerified: true,
  isActive: true,
  createdAt: DateTime(2024, 1, 1),
);

// ── Élections de test ─────────────────────────────────────────────────────────
final mockElections = <Election>[
  Election(
    id: 'election-pres-2026',
    titreFr: 'Élection Présidentielle Test 2026',
    titreAr: 'الانتخابات الرئاسية التجريبية 2026',
    type: ElectionType.presidentielle,
    nbTours: 2,
    dateOuverture: DateTime.now().subtract(const Duration(hours: 1)),
    dateFermeture: DateTime.now().add(const Duration(hours: 11)),
    statut: ElectionStatus.en_cours,
    tourActuel: 1,
    descriptionFr: 'Élection présidentielle de test pour démonstration.',
    isPublic: true,
  ),
  Election(
    id: 'election-muni-2026',
    titreFr: 'Élections Municipales Nouakchott 2026',
    titreAr: 'الانتخابات البلدية نواكشوط 2026',
    type: ElectionType.municipale,
    nbTours: 1,
    dateOuverture: DateTime.now().subtract(const Duration(days: 15)),
    dateFermeture: DateTime.now().subtract(const Duration(days: 8)),
    statut: ElectionStatus.terminee,
    tourActuel: 1,
    isPublic: true,
  ),
  Election(
    id: 'election-legis-2027',
    titreFr: 'Élections Législatives 2027',
    titreAr: 'الانتخابات التشريعية 2027',
    type: ElectionType.legislative,
    nbTours: 2,
    dateOuverture: DateTime.now().add(const Duration(days: 45)),
    dateFermeture: DateTime.now().add(const Duration(days: 46)),
    statut: ElectionStatus.planifiee,
    tourActuel: 1,
    isPublic: true,
  ),
];

// ── Candidats de test ─────────────────────────────────────────────────────────
final mockCandidates = <Candidate>[
  Candidate(id: 'c1', electionId: 'election-pres-2026', numeroCandidat: 1,
      nom: 'Mohamed Ould Alpha', parti: 'Parti de la Réforme',
      partiAr: 'حزب الإصلاح', couleurParti: '#1565C0', tour: 1, isActive: true),
  Candidate(id: 'c2', electionId: 'election-pres-2026', numeroCandidat: 2,
      nom: 'Aminetou Mint Beta', parti: 'Rassemblement National',
      partiAr: 'التجمع الوطني', couleurParti: '#1B5E20', tour: 1, isActive: true),
  Candidate(id: 'c3', electionId: 'election-pres-2026', numeroCandidat: 3,
      nom: 'Sidi Ould Gamma', parti: 'Alliance Populaire',
      partiAr: 'التحالف الشعبي', couleurParti: '#E65100', tour: 1, isActive: true),
  Candidate(id: 'c4', electionId: 'election-pres-2026', numeroCandidat: 4,
      nom: 'Mariem Mint Delta', parti: 'Indépendant',
      partiAr: 'مستقل', couleurParti: '#4A148C', tour: 1, isActive: true),
];

// ── Résultats élection terminée ───────────────────────────────────────────────
final mockResultats = <Resultat>[
  Resultat(electionId: 'election-muni-2026', candidateId: 'cm1', tour: 1,
      nbVotes: 45230, pourcentage: 42.3, valideCeni: true, valideCc: true),
  Resultat(electionId: 'election-muni-2026', candidateId: 'cm2', tour: 1,
      nbVotes: 38150, pourcentage: 35.7, valideCeni: true, valideCc: false),
  Resultat(electionId: 'election-muni-2026', candidateId: 'cm3', tour: 1,
      nbVotes: 23620, pourcentage: 22.0, valideCeni: true, valideCc: false),
];

// ── Bureau de vote test ───────────────────────────────────────────────────────
const mockBureauVote = BureauVote(
  id: 'NKT-001-001',
  codeBureau: 'NKT-001-001',
  nom: 'Ecole Tevragh-Zeina A',
  communeId: 'NKT-001',
  wilayaId: 'MR-14',
  adresse: 'Rue des Ambassades, Tevragh-Zeina',
  latitude: 18.0735,
  longitude: -15.9582,
  capacite: 500,
  isAccessible: true,
  isActif: true,
);
