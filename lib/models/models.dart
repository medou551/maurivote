// ══════════════════════════════════════════════════════════════════════════════
// MODÈLES DE DONNÉES — MauriVote
// Tous les modèles avec sérialisation JSON manuelle (sans génération de code
// pour que les fichiers soient utilisables sans build_runner)
// ══════════════════════════════════════════════════════════════════════════════

// ── voter.dart ───────────────────────────────────────────────────────────────
class Voter {
  final String id;
  final String nni;
  final String nom;
  final String prenom;
  final DateTime dateNaissance;
  final String sexe;
  final String communeId;
  final String wilayaId;
  final String? bureauVoteId;
  final String telephone;
  final String? photoUrl;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;

  const Voter({
    required this.id,
    required this.nni,
    required this.nom,
    required this.prenom,
    required this.dateNaissance,
    required this.sexe,
    required this.communeId,
    required this.wilayaId,
    this.bureauVoteId,
    required this.telephone,
    this.photoUrl,
    required this.isVerified,
    required this.isActive,
    required this.createdAt,
  });

  String get nomComplet => '$prenom $nom';
  String get nniMasque  => '${nni.substring(0, 3)}****${nni.substring(7)}';

  factory Voter.fromJson(Map<String, dynamic> json) => Voter(
    id:             json['id'],
    nni:            json['nni'],
    nom:            json['nom'],
    prenom:         json['prenom'],
    dateNaissance:  DateTime.parse(json['date_naissance']),
    sexe:           json['sexe'],
    communeId:      json['commune_id'],
    wilayaId:       json['wilaya_id'],
    bureauVoteId:   json['bureau_vote_id'],
    telephone:      json['telephone'],
    photoUrl:       json['photo_url'],
    isVerified:     json['is_verified'] ?? false,
    isActive:       json['is_active'] ?? true,
    createdAt:      DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'nni': nni, 'nom': nom, 'prenom': prenom,
    'date_naissance': dateNaissance.toIso8601String(),
    'sexe': sexe, 'commune_id': communeId, 'wilaya_id': wilayaId,
    'bureau_vote_id': bureauVoteId, 'telephone': telephone,
    'photo_url': photoUrl, 'is_verified': isVerified,
    'is_active': isActive, 'created_at': createdAt.toIso8601String(),
  };
}

// ── election.dart ─────────────────────────────────────────────────────────────
enum ElectionType { presidentielle, legislative, municipale, regionale, referendum }
enum ElectionStatus { planifiee, en_cours, terminee, annulee }

class Election {
  final String id;
  final String titreFr;
  final String titreAr;
  final ElectionType type;
  final int nbTours;
  final DateTime dateOuverture;
  final DateTime dateFermeture;
  final DateTime? dateResultats;
  final ElectionStatus statut;
  final int tourActuel;
  final String? descriptionFr;
  final String? descriptionAr;
  final bool isPublic;

  const Election({
    required this.id,
    required this.titreFr,
    required this.titreAr,
    required this.type,
    required this.nbTours,
    required this.dateOuverture,
    required this.dateFermeture,
    this.dateResultats,
    required this.statut,
    required this.tourActuel,
    this.descriptionFr,
    this.descriptionAr,
    required this.isPublic,
  });

  bool get isActive => statut == ElectionStatus.en_cours;
  bool get isVotable {
    final now = DateTime.now().toUtc();
    return isActive &&
        now.isAfter(dateOuverture) &&
        now.isBefore(dateFermeture);
  }

  String get typeLabel => switch (type) {
    ElectionType.presidentielle => 'Présidentielle',
    ElectionType.legislative    => 'Législative',
    ElectionType.municipale     => 'Municipale',
    ElectionType.regionale      => 'Régionale',
    ElectionType.referendum     => 'Référendum',
  };

  factory Election.fromJson(Map<String, dynamic> json) => Election(
    id:             json['id'],
    titreFr:        json['titre_fr'],
    titreAr:        json['titre_ar'],
    type:           ElectionType.values.firstWhere(
                      (e) => e.name == json['type_election'],
                      orElse: () => ElectionType.presidentielle),
    nbTours:        json['nb_tours'] ?? 2,
    dateOuverture:  DateTime.parse(json['date_ouverture']),
    dateFermeture:  DateTime.parse(json['date_fermeture']),
    dateResultats:  json['date_resultats'] != null
                      ? DateTime.parse(json['date_resultats']) : null,
    statut:         ElectionStatus.values.firstWhere(
                      (e) => e.name == (json['statut'] ?? 'planifiee'),
                      orElse: () => ElectionStatus.planifiee),
    tourActuel:     json['tour_actuel'] ?? 1,
    descriptionFr:  json['description_fr'],
    descriptionAr:  json['description_ar'],
    isPublic:       json['is_public'] ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'titre_fr': titreFr, 'titre_ar': titreAr,
    'type_election': type.name, 'nb_tours': nbTours,
    'date_ouverture': dateOuverture.toIso8601String(),
    'date_fermeture': dateFermeture.toIso8601String(),
    'statut': statut.name, 'tour_actuel': tourActuel,
    'is_public': isPublic,
  };
}

// ── candidate.dart ────────────────────────────────────────────────────────────
class Candidate {
  final String id;
  final String electionId;
  final int numeroCandidat;
  final String nom;
  final String? parti;
  final String? partiAr;
  final String? photoUrl;
  final String? biographieFr;
  final String? biographieAr;
  final String? programmeUrl;
  final String? couleurParti;
  final int tour;
  final bool isActive;

  const Candidate({
    required this.id,
    required this.electionId,
    required this.numeroCandidat,
    required this.nom,
    this.parti,
    this.partiAr,
    this.photoUrl,
    this.biographieFr,
    this.biographieAr,
    this.programmeUrl,
    this.couleurParti,
    required this.tour,
    required this.isActive,
  });

  factory Candidate.fromJson(Map<String, dynamic> json) => Candidate(
    id:             json['id'],
    electionId:     json['election_id'],
    numeroCandidat: json['numero_candidat'],
    nom:            json['nom'],
    parti:          json['parti'],
    partiAr:        json['parti_ar'],
    photoUrl:       json['photo_url'],
    biographieFr:   json['biographie_fr'],
    biographieAr:   json['biographie_ar'],
    programmeUrl:   json['programme_url'],
    couleurParti:   json['couleur_parti'],
    tour:           json['tour'] ?? 1,
    isActive:       json['is_active'] ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'election_id': electionId,
    'numero_candidat': numeroCandidat, 'nom': nom,
    'parti': parti, 'tour': tour, 'is_active': isActive,
  };
}

// ── vote.dart ─────────────────────────────────────────────────────────────────
class VotePayload {
  final String voterHash;
  final String electionId;
  final String candidateId;
  final int tour;
  final String voteChiffre;
  final String iv;
  final String signature;
  final String recuHash;

  const VotePayload({
    required this.voterHash,
    required this.electionId,
    required this.candidateId,
    required this.tour,
    required this.voteChiffre,
    required this.iv,
    required this.signature,
    required this.recuHash,
  });

  Map<String, dynamic> toJson() => {
    'voter_hash':   voterHash,
    'election_id':  electionId,
    'candidate_id': candidateId,
    'tour':         tour,
    'vote_chiffre': voteChiffre,
    'iv':           iv,
    'signature':    signature,
    'recu_hash':    recuHash,
  };
}

// ── bureau_vote.dart ──────────────────────────────────────────────────────────
class BureauVote {
  final String id;
  final String codeBureau;
  final String nom;
  final String communeId;
  final String wilayaId;
  final String adresse;
  final double latitude;
  final double longitude;
  final int capacite;
  final bool isAccessible;
  final bool isActif;

  const BureauVote({
    required this.id,
    required this.codeBureau,
    required this.nom,
    required this.communeId,
    required this.wilayaId,
    required this.adresse,
    required this.latitude,
    required this.longitude,
    required this.capacite,
    required this.isAccessible,
    required this.isActif,
  });

  factory BureauVote.fromJson(Map<String, dynamic> json) => BureauVote(
    id:           json['id'],
    codeBureau:   json['code_bureau'],
    nom:          json['nom'],
    communeId:    json['commune_id'],
    wilayaId:     json['wilaya_id'],
    adresse:      json['adresse'],
    latitude:     (json['latitude'] as num).toDouble(),
    longitude:    (json['longitude'] as num).toDouble(),
    capacite:     json['capacite'],
    isAccessible: json['is_accessible'] ?? false,
    isActif:      json['is_actif'] ?? true,
  );
}

// ── resultat.dart ─────────────────────────────────────────────────────────────
class Resultat {
  final String electionId;
  final String candidateId;
  final int tour;
  final int nbVotes;
  final double pourcentage;
  final bool valideCeni;
  final bool valideCc;

  const Resultat({
    required this.electionId,
    required this.candidateId,
    required this.tour,
    required this.nbVotes,
    required this.pourcentage,
    required this.valideCeni,
    required this.valideCc,
  });

  factory Resultat.fromJson(Map<String, dynamic> json) => Resultat(
    electionId:  json['election_id'],
    candidateId: json['candidate_id'],
    tour:        json['tour'] ?? 1,
    nbVotes:     json['nb_votes'] ?? 0,
    pourcentage: (json['pourcentage'] as num?)?.toDouble() ?? 0.0,
    valideCeni:  json['valide_ceni'] ?? false,
    valideCc:    json['valide_cc'] ?? false,
  );
}
