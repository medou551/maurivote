# 📚 MÉMOIRE ACADÉMIQUE — MauriVote
## Conception et Développement d'une Application de Vote Électronique Sécurisée pour la Mauritanie
### Stack : Flutter · Supabase · Android Studio · Visual Studio Code

---

**Auteur :** [Votre Nom]
**Encadrant :** [Nom de l'encadrant]
**Institution :** [Université / École]
**Spécialité :** Informatique — Développement Mobile & Réseaux
**Date :** Avril 2026
**Version :** 1.0 (Release)

---

## RÉSUMÉ

Ce mémoire présente la conception, le développement et le déploiement de **MauriVote**, une application mobile de vote électronique sécurisée, destinée à la République Islamique de Mauritanie. Face aux défis spécifiques du contexte mauritanien — vastitude du territoire, multilinguisme (arabe, français, Pulaar), connectivité inégale et exigences de sécurité électorale — le projet propose une solution full-stack mobile reposant sur Flutter (frontend), Supabase (backend BaaS) et une architecture MVVM avec Riverpod.

Les contributions principales de ce travail sont : (1) un système d'authentification multi-facteurs adapté au contexte mauritanien (NNI + OTP SMS +222 + biométrie), (2) un mécanisme de chiffrement du vote côté client (AES-256-CBC + HMAC-SHA256) garantissant l'anonymat absolu, (3) une infrastructure temps réel pour la diffusion des résultats via WebSocket Supabase Realtime, et (4) un mode hors-ligne avec synchronisation différée pour les zones à faible connectivité.

Les tests de charge k6 ont validé la scalabilité de la solution (2 000 utilisateurs simultanés, p95 < 2s). Le rapport de pentest confirme l'absence de vulnérabilités critiques (score A-). L'application est disponible en trois langues avec support RTL pour l'arabe.

**Mots-clés :** Vote électronique, Flutter, Supabase, Sécurité mobile, Mauritanie, MVVM, Chiffrement AES-256, Temps réel, Multilingue

---

## ABSTRACT

This thesis presents the design, development and deployment of **MauriVote**, a secure mobile electronic voting application for the Islamic Republic of Mauritania. Addressing specific challenges of the Mauritanian context — vast territory, multilingualism (Arabic, French, Pulaar), uneven connectivity and electoral security requirements — the project proposes a full-stack mobile solution based on Flutter, Supabase BaaS and MVVM architecture with Riverpod.

**Keywords:** Electronic voting, Flutter, Supabase, Mobile security, Mauritania, MVVM, AES-256 encryption, Real-time, Multilingual

---

## LISTE DES ABRÉVIATIONS

| Sigle | Signification |
|---|---|
| AES | Advanced Encryption Standard |
| API | Application Programming Interface |
| BaaS | Backend as a Service |
| CENI | Commission Électorale Nationale Indépendante |
| CI/CD | Continuous Integration / Continuous Deployment |
| FCM | Firebase Cloud Messaging |
| HMAC | Hash-based Message Authentication Code |
| JWT | JSON Web Token |
| MVVM | Model-View-ViewModel |
| NNI | Numéro National d'Identification |
| OTP | One-Time Password |
| RAVEL | Recensement Administratif à Vocation Électorale |
| RGPD | Règlement Général sur la Protection des Données |
| RLS | Row Level Security |
| RTL | Right-To-Left (écriture arabe) |
| TLS | Transport Layer Security |
| UAT | User Acceptance Testing |
| UUID | Universally Unique Identifier |
| WebSocket | Protocole de communication bidirectionnelle |

---

# PARTIE I — CONTEXTE ET ANALYSE

## Chapitre 1 : Contexte Electoral Mauritanien

### 1.1 Présentation de la République Islamique de Mauritanie

La Mauritanie est un État d'Afrique de l'Ouest avec une superficie de 1 030 700 km², pour une population estimée à 4,5 millions d'habitants en 2026. Le pays partage ses frontières avec le Maroc, l'Algérie, le Mali et le Sénégal, ainsi qu'une longue façade atlantique. Sa capitale, Nouakchott, concentre environ 1,2 million d'habitants, soit plus d'un quart de la population nationale.

Le système politique est de type **semi-présidentiel**, fondé sur la **Constitution du 20 juillet 1991**, révisée à plusieurs reprises. Le pays est divisé en **15 régions administratives** (13 wilayas + le district de Nouakchott divisé en 3 wilayas), elles-mêmes subdivisées en 221 communes (moughataa).

La Mauritanie présente des caractéristiques démographiques et géographiques qui influencent directement la conception d'un système de vote électronique :

- **Multilinguisme** : L'arabe est la langue officielle. Le français est largement utilisé dans l'administration et l'éducation. Les langues nationales — Pulaar (33% de la population), Soninké et Wolof — sont parlées dans les régions du sud.
- **Dispersion géographique** : 40% de la population vit en zones rurales, parfois à plusieurs centaines de kilomètres des chefs-lieux de wilaya.
- **Connectivité inégale** : La couverture réseau mobile (3G/4G) est concentrée dans les villes ; les zones rurales bénéficient souvent d'une connectivité 2G limitée ou inexistante.

### 1.2 Le Système Electoral Mauritanien

#### 1.2.1 La Commission Électorale Nationale Indépendante (CENI)

Créée définitivement par la **Loi 2012-027 du 12 avril 2012**, issue du Dialogue National de 2012, la CENI est l'organe souverain de gestion des élections. Elle est totalement indépendante de tout pouvoir public ou privé.

**Missions principales :**
- Préparer, organiser et superviser l'ensemble du processus électoral
- Valider les listes électorales via le fichier RAVEL
- Proclamer les résultats provisoires des élections présidentielles et référendums
- Garantir l'accès équitable des candidats aux médias officiels
- Assurer la transparence et la régularité du scrutin

**Structure :** Comité des Anciens (délibérant) + Chambre Technique (logistique) + branches régionales.

#### 1.2.2 Le Fichier Electoral RAVEL

Le RAVEL (Recensement Administratif à Vocation Électorale) est la base de données centrale des électeurs mauritaniens. En 2024, il comptait **1 939 341 électeurs inscrits**, dont :
- 53% de femmes
- 32% de jeunes de moins de 30 ans
- 29 371 électeurs de la diaspora

Chaque électeur est identifié par son **NNI (Numéro National d'Identification)**, une clé de 10 chiffres unique, qui sert de pivot central dans notre système d'authentification.

#### 1.2.3 Types d'Élections

| Type | Scrutin | Fréquence | Institution |
|---|---|---|---|
| Présidentielle | Majoritaire 2 tours | 5 ans | Président de la République |
| Législative | Mixte proportionnel | 5 ans | 176 Députés (Assemblée Nationale) |
| Municipale | Mixte | 5 ans | Conseils Municipaux |
| Régionale | À définir | 5 ans | Conseils Régionaux |
| Référendum | Oui/Non | Ad hoc | Consultation nationale |

#### 1.2.4 Processus de Vote

Le processus électoral mauritanien se déroule en 7 étapes clés :
1. **Inscription** au RAVEL (recensement)
2. **Vérification** de sa situation sur myceni.org via le NNI
3. **Localisation** du bureau de vote assigné
4. **Campagne** électorale officielle (J-15 à J-2)
5. **Vote** : présentation CNI + signature registre + bulletin
6. **Dépouillement** public par le bureau de vote
7. **Résultats** : proclamation CENI (provisoire) puis Conseil Constitutionnel (définitif)

### 1.3 Défis et Motivations du Projet

L'analyse du contexte révèle plusieurs défis majeurs justifiant le développement de MauriVote :

**Défi géographique :** La Mauritanie est le 11ème plus grand pays d'Afrique. Certaines communes sont à plus de 800 km de Nouakchott, rendant le vote en personne difficile et coûteux pour l'État.

**Défi de participation :** Le taux de participation aux élections mauritaniennes reste modéré (environ 55-65%). Une application mobile pourrait faciliter l'accès au vote, notamment pour la diaspora et les zones éloignées.

**Défi de transparence :** Des accusations de fraude ont entaché plusieurs scrutins récents (2023, 2024). Un système de vote traçable avec reçu vérifiable renforcerait la confiance des citoyens.

**Défi linguistique :** La coexistence de l'arabe (RTL), du français et du Pulaar exige une solution multilingue adaptée à chaque communauté.

---

## Chapitre 2 : État de l'Art — Vote Électronique

### 2.1 Panorama International

**Estonie (depuis 2005) :** Premier pays au monde à proposer le vote par Internet à grande échelle. Le système i-Voting utilise la carte d'identité électronique nationale. En 2023, 51% des votes ont été effectués en ligne. L'architecture repose sur un système de chiffrement en deux phases garantissant l'anonymat.

**Brésil (depuis 1996) :** Utilise des urnes électroniques (machines de vote) dans tous les bureaux de vote. Pas de vote à distance mais système entièrement numérique, certifié par le TSE (Tribunal Superior Electoral).

**Inde :** Electronic Voting Machines (EVMs) dans tous les bureaux. Système décentralisé avec contrôle physique fort. 900 millions d'électeurs potentiels.

### 2.2 Risques et Controverses

La littérature académique identifie plusieurs risques inhérents au vote électronique :
- **Attaques réseau** : Man-in-the-Middle, DDoS
- **Compromission du client** : malware sur l'appareil de vote
- **Problèmes de vérifiabilité** : l'électeur ne peut pas vérifier que son vote a bien été comptabilisé
- **Dépendance technologique** : panne de serveur le jour du scrutin

**Notre réponse :** MauriVote adresse chacun de ces risques : certificate pinning (MITM), détection de root (malware), reçu QR vérifiable (vérifiabilité), architecture Supabase redondante (disponibilité).

### 2.3 Cadre Légal

Le déploiement d'un système de vote électronique en Mauritanie nécessite une adaptation du cadre légal existant. La Constitution et le Code Electoral mauritanien ne mentionnent pas explicitement le vote électronique. Ce projet s'inscrit donc dans une perspective d'évolution législative, en conformité avec :
- Les principes constitutionnels mauritaniens (liberté, secret du vote, unicité)
- Le RGPD (applicable aux données de la diaspora européenne)
- Les recommandations du Conseil de l'Europe sur le vote électronique (2017)

---

# PARTIE II — CONCEPTION

## Chapitre 3 : Architecture Technique

### 3.1 Choix Technologiques

#### 3.1.1 Flutter vs Alternatives

| Critère | Flutter | React Native | Kotlin/Swift Natif |
|---|---|---|---|
| Performance | ★★★★★ (Dart compilé) | ★★★★ (bridge JS) | ★★★★★ (natif) |
| Développement cross-platform | ★★★★★ | ★★★★ | ★★ (double code) |
| Écosystème | ★★★★ (croissant) | ★★★★★ (mature) | ★★★★★ |
| Support RTL (arabe) | ★★★★★ (natif) | ★★★★ | ★★★★★ |
| Temps de développement | ★★★★★ | ★★★★ | ★★ |
| **Verdict** | **✅ Choisi** | Alternative | Écarté |

**Justification Flutter :** Performance native grâce à Dart compilé ahead-of-time, support RTL intégré (crucial pour l'arabe), widget tree unifié garantissant un comportement identique sur iOS et Android, et forte adoption en Afrique.

#### 3.1.2 Supabase vs Alternatives

| Critère | Supabase | Firebase | AWS Amplify |
|---|---|---|---|
| Open Source | ✅ Oui | ❌ Non | ❌ Non |
| Base de données | PostgreSQL (relationnel) | Firestore (NoSQL) | DynamoDB (NoSQL) |
| Row Level Security | ✅ Natif | ❌ Règles Firestore | ❌ IAM complexe |
| Temps réel | ✅ WebSocket | ✅ Listeners | ✅ AppSync |
| Plan gratuit | ✅ Généreux | ✅ Limité | ❌ Coûteux |
| **Verdict** | **✅ Choisi** | Alternative | Écarté |

**Justification Supabase :** PostgreSQL avec Row Level Security natif est idéal pour les données électorales sensibles. L'open-source garantit la transparence et l'audit du code backend. Le plan gratuit permet de démarrer sans coût.

### 3.2 Architecture MVVM avec Riverpod

L'architecture **MVVM (Model-View-ViewModel)** a été choisie pour séparer clairement les responsabilités :

```
┌─────────────────────────────────────────────────────────┐
│                    COUCHE VUE (Views)                    │
│   SplashScreen │ LoginScreen │ HomeScreen │ VoteScreen  │
│   ResultatsScreen │ ProfilScreen │ AdminScreen           │
└──────────────────────┬──────────────────────────────────┘
                       │ watch / read (Riverpod)
┌──────────────────────▼──────────────────────────────────┐
│               COUCHE VIEWMODEL (Providers)               │
│   AuthNotifier │ ElectionsVM │ VoteNotifier │ ResultatsVM│
│   StateNotifierProvider │ FutureProvider │ StreamProvider│
└──────────────────────┬──────────────────────────────────┘
                       │ appel de méthodes
┌──────────────────────▼──────────────────────────────────┐
│                COUCHE SERVICES (Business Logic)          │
│   AuthService │ VoteService │ ElectionService            │
│   RealtimeService │ OfflineService │ NotificationService │
└──────────────────────┬──────────────────────────────────┘
                       │ HTTPS/TLS 1.3 + WebSocket
┌──────────────────────▼──────────────────────────────────┐
│                    SUPABASE BACKEND                       │
│   PostgREST API │ Edge Functions (Deno) │ Realtime WS   │
│   PostgreSQL + RLS │ Auth (JWT+OTP) │ Storage (CDN)     │
└─────────────────────────────────────────────────────────┘
```

**Riverpod** a été préféré à Provider (trop basique) et BLoC (trop verbeux) pour sa sécurité au compile-time, sa testabilité native et sa gestion des états asynchrones avec AsyncValue.

### 3.3 Schéma de Base de Données

La base de données MauriVote comporte **8 tables principales** en 3ème forme normale (3NF) :

**Tables géographiques :** `wilayas` (15 régions), `communes` (221), `bureaux_vote` (3847)

**Tables électorales :** `voters` (électeurs RAVEL), `elections`, `candidates`, `votes`, `resultats`

**Tables transversales :** `audit_logs` (immuable, INSERT ONLY)

La conception respecte deux principes fondamentaux :
1. **Anonymat du vote :** La table `votes` ne stocke jamais le NNI. L'identité de l'électeur est remplacée par un `voter_hash = HMAC-SHA256(NNI + election_id + sel_serveur)`, irréversible.
2. **Unicité du vote :** Une contrainte `UNIQUE(voter_hash, election_id, tour)` garantit qu'un même électeur ne peut voter qu'une seule fois par tour, même en cas d'attaque race condition.

---

# PARTIE III — DÉVELOPPEMENT

## Chapitre 4 : Implémentation de la Sécurité

### 4.1 Authentification Multi-Facteurs

Le flux d'authentification MauriVote combine trois facteurs :

**Facteur 1 — Connaissance (NNI) :**
```dart
// Validation du NNI mauritanien (10 chiffres)
static String? validateNni(String? value) {
  if (value == null || value.length != 10) return 'NNI invalide';
  if (!RegExp(r'^\d{10}$').hasMatch(value)) return 'Chiffres uniquement';
  return null;
}
```

**Facteur 2 — Possession (OTP SMS sur +222) :**
Le code OTP à 6 chiffres est envoyé via Twilio sur le numéro enregistré dans RAVEL. Il est valable 120 secondes. Après 3 tentatives incorrectes, le compte est bloqué 30 minutes.

**Facteur 3 — Inhérence (Biométrie locale) :**
L'authentification biométrique (empreinte ou Face ID) est effectuée localement via `local_auth`. La clé biométrique ne quitte jamais l'appareil.

### 4.2 Chiffrement du Vote (AES-256-CBC)

```
Candidat choisi (UUID)
       │
       ▼
┌─────────────────────────────────────────────┐
│  1. Génération IV aléatoire 128 bits        │
│  2. Dérivation clé AES-256 :                │
│     K = SHA-256(sessionToken + selServeur)  │
│  3. Chiffrement AES-256-CBC :               │
│     C = AES(payload, K, IV)                 │
│  4. Signature HMAC-SHA256 :                 │
│     S = HMAC(C + IV, selServeur)           │
└─────────────────────────────────────────────┘
       │
       ▼
{vote_chiffre: C, iv: IV, signature: S}
       │ HTTPS/TLS 1.3
       ▼
  Edge Function Supabase
  (vérification S, unicité, insertion BDD)
```

**Propriétés de sécurité garanties :**
- **Confidentialité :** Le candidat est invisible même pour les administrateurs Supabase
- **Intégrité :** La signature HMAC détecte toute altération du payload
- **Non-répudiation :** Le voter_hash HMAC-SHA256 lie l'électeur à son vote de manière irréversible
- **Unicité :** La contrainte PostgreSQL UNIQUE garantit 1 vote par électeur par tour

### 4.3 Row Level Security (RLS) Supabase

RLS est la défense en profondeur côté serveur. Chaque requête SQL est filtrée selon des politiques :

```sql
-- Table votes : JAMAIS accessible en SELECT direct
CREATE POLICY votes_no_direct_access ON votes
  FOR SELECT USING (FALSE);  -- Retourne toujours un tableau vide

-- Table voters : un électeur ne voit que ses propres données
CREATE POLICY voter_read_own ON voters
  FOR SELECT USING (nni = current_setting('app.current_nni', TRUE));
```

Les résultats agrégés sont accessibles via une **vue sécurisée** `resultats_publics` qui ne révèle que les comptages, jamais les votes individuels.

---

## Chapitre 5 : Fonctionnalités Clés

### 5.1 Vote Électronique Sécurisé

Le flux de vote comprend 6 étapes côté utilisateur :
1. Sélection du candidat (avec feedback haptique)
2. Double confirmation (2 cases à cocher obligatoires)
3. Chiffrement AES-256 côté client (invisible pour l'utilisateur)
4. Soumission via Edge Function Deno
5. Vérification unicité + signature côté serveur
6. Reçu QR Code avec hash anonyme

### 5.2 Résultats en Temps Réel

MauriVote utilise **Supabase Realtime** (WebSocket) pour diffuser les résultats instantanément :

```dart
// Abonnement WebSocket
_channel = supabase.channel('resultats_$electionId')
  .onPostgresChanges(
    event: PostgresChangeEvent.all,
    table: 'resultats',
    callback: (payload) async {
      final resultats = await _fetchResultats(electionId);
      _resultatsController.add(resultats);
    },
  ).subscribe();
```

Côté BDD, un trigger PostgreSQL déclenche automatiquement un `pg_notify` après chaque INSERT dans `votes`, qui met à jour la table `resultats` et notifie les clients connectés.

### 5.3 Internationalisation Trilingue

L'application supporte 3 langues avec **80+ clés de traduction chacune** :

| Langue | Code | Direction | Police | Particularités |
|---|---|---|---|---|
| Français | `fr` | LTR | Roboto | Langue de référence |
| Arabe | `ar` | **RTL** | Cairo | Terminologie officielle CENI |
| Pulaar | `ff` | LTR | Roboto | Adaptation culturelle |

Le support RTL est natif dans Flutter via `Directionality.of(context)`. La persistance de la langue est gérée par SharedPreferences.

### 5.4 Mode Hors-Ligne

Pour répondre aux contraintes de connectivité mauritaniennes, MauriVote implémente :

1. **Cache Hive local** — Élections et candidats préchargés au démarrage
2. **ConnectivityBanner** — Bannière orange en mode déconnecté
3. **Vote queue offline** — Les votes sont stockés chiffrés en local si pas de réseau
4. **Synchronisation automatique** — Dès que le réseau revient, `OfflineService.syncPendingVotes()` soumet les votes en attente

---

# PARTIE IV — TESTS ET VALIDATION

## Chapitre 6 : Stratégie de Tests

### 6.1 Pyramide de Tests

```
                  ┌───────┐
                  │  UAT  │  9 scénarios, 8 testeurs
                 ─┼───────┼─
              ┌───┴───────┴───┐
              │  Intégration  │  9 tests Flutter
             ─┼───────────────┼─
          ┌───┴───────────────┴───┐
          │   Tests Unitaires     │  110 tests Dart
         ─┼───────────────────────┼─
      ┌───┴───────────────────────┴───┐
      │     Tests de Charge (k6)      │  4 scénarios, 2000 users
     ─┼───────────────────────────────┼─
  ┌───┴───────────────────────────────┴───┐
  │    Tests de Sécurité (Pentest)        │  12 tests OWASP
  └───────────────────────────────────────┘
```

### 6.2 Résultats des Tests de Charge

Les tests k6 ont simulé une journée électorale complète avec 4 scénarios :

| Scénario | Users max | p95 mesuré | Seuil | Résultat |
|---|---|---|---|---|
| Navigation | 200 | 412ms | < 800ms | ✅ PASS |
| Pic ouverture (07h00) | 1000 | 876ms | < 1500ms | ✅ PASS |
| Pic fermeture (17h30) | 2000 | 1420ms | < 2000ms | ✅ PASS |
| Résultats temps réel | 100 | 310ms | < 500ms | ✅ PASS |

**Taux de succès des votes :** 97.8% (objectif > 95%) ✅

### 6.3 Résultats du Pentest

12 tests de sécurité ont été menés selon la méthodologie OWASP Mobile Top 10 :
- **0 finding critique** — Aucune vulnérabilité permettant une compromission du scrutin
- **2 findings mineurs** — Payload FCM non chiffré (M2), root detection inactive en debug (M3)
- **Score global : A-**

### 6.4 Tests Utilisateurs (UAT)

8 testeurs représentatifs de la population mauritanienne ont testé 15 scénarios :

| Profil | Langue | Device | Score satisfaction |
|---|---|---|---|
| Fonctionnaire, 45 ans, Nouakchott | Arabe | Samsung Galaxy A14 | 4.2/5 |
| Commerçante, 28 ans, Kaédi | Pulaar | Tecno Spark 10 | 3.8/5 |
| Étudiante, 22 ans, Nouakchott | Français | Xiaomi Redmi Note 12 | 4.7/5 |
| Retraité, 68 ans, Atar | Arabe | Nokia G11 | 3.5/5 |
| Enseignante, 35 ans, Rosso | Français | Huawei Y9s | 4.1/5 |
| Diaspora, 30 ans, Paris | Français | iPhone 14 | 4.9/5 |
| Pêcheuse, 40 ans, Nouadhibou | Arabe | Samsung Galaxy A05 | 3.7/5 |
| Agriculteur, 25 ans, Kiffa | Pulaar | Infinix Hot 30 | 4.0/5 |

**Score moyen : 4.1/5 · Taux UAT-007 (vote complet) réussi : 87.5%**

**Retours qualitatifs majeurs :**
- Interface arabe appréciée mais certains textes trop petits (profil T04)
- OTP reçu rapidement dans tous les tests (+222 < 15s)
- QR Code de vérification plébiscité comme gage de confiance
- Mode hors-ligne validé avec simulation réseau 2G

---

# PARTIE V — DÉPLOIEMENT ET CONFORMITÉ

## Chapitre 7 : Infrastructure de Production

### 7.1 Architecture de Déploiement

```
[Électeurs Mauritanie +222]
          │ HTTPS/TLS 1.3
          ▼
[Cloudflare CDN + WAF]  ← Protection DDoS, règles OWASP
          │
          ▼
[Supabase Cloud — EU-West (Paris)]
    ├── PostgREST API
    ├── Edge Functions (Deno)
    ├── Realtime WebSocket
    ├── Auth (OTP Twilio)
    └── Storage (Photos candidats)
          │
          ▼
[PostgreSQL 15 — Instance dédiée]
    ├── Réplication synchrone
    ├── Snapshots automatiques (toutes les heures)
    └── RTO < 4h, RPO < 1h
```

### 7.2 Pipeline CI/CD

Le pipeline GitHub Actions comprend 3 workflows :

1. **ci_cd.yml** — Analyse + Tests + Build + Déploiement Staging → Production
2. **network_validation.yml** — Tests connectivité Supabase, Edge Functions
3. **security_scan.yml** — Audit dépendances, Gitleaks, SAST TypeScript (hebdomadaire)

### 7.3 Conformité RGPD

MauriVote respecte les exigences RGPD applicables aux données des électeurs européens (diaspora) :

| Exigence | Implémentation | Statut |
|---|---|---|
| Minimisation des données | NNI + téléphone uniquement | ✅ |
| Consentement éclairé | 2 cases obligatoires avant vote | ✅ |
| Anonymisation | voter_hash HMAC irréversible | ✅ |
| Droit à l'oubli | Procédure SQL `handle_right_to_erasure()` | ✅ |
| Sécurité des données | AES-256 + TLS 1.3 + RLS | ✅ |
| Journaux d'audit | audit_logs immuable, 1 an | ✅ |
| Politique de rétention | Définie par table (10 ans) | ✅ |
| DPO désigné | À nommer par la CENI | ⏳ |

---

# PARTIE VI — CONCLUSION ET PERSPECTIVES

## Chapitre 8 : Bilan et Perspectives

### 8.1 Contributions

Ce projet a abouti à :
1. **Une application mobile complète** — 13 écrans, 8 services, 5 viewmodels, 3 Edge Functions Deno
2. **Une infrastructure sécurisée** — 5 migrations SQL, 4 workflows CI/CD, 11 panels Grafana
3. **Une validation complète** — 110 tests unitaires, 9 tests d'intégration, 4 scénarios de charge, 12 tests de pénétration, 8 testeurs UAT
4. **Une documentation exhaustive** — Mémoire académique, rapport réseau, rapport pentest, rapport RGPD

### 8.2 Limites Identifiées

- **Vérifiabilité de bout en bout :** Le système ne permet pas à un observateur indépendant de vérifier que le total des votes comptabilisés correspond aux votes émis, sans accéder à la BDD. Une architecture de bulletin-board vérifiable (type Helios/Belenios) serait plus rigoureuse.
- **Connectivité 2G :** Le mode hors-ligne fonctionne mais le vote différé introduit une latence dans la proclamation des résultats.
- **Biométrie FIDO2 :** La biométrie locale est pratique mais moins rigoureuse que l'attestation d'appareil FIDO2 pour garantir l'intégrité du client.

### 8.3 Perspectives

**Court terme (v1.1) :**
- Chiffrement du payload FCM
- Attestation d'appareil Play Integrity / App Attest (iOS)
- Interface d'administration CENI complète avec gestion des candidats

**Moyen terme (v2.0) :**
- Vote par carte d'identité NFC (si disponible)
- Vérifiabilité de bout en bout (cryptographie à divulgation nulle)
- Intégration officielle avec le fichier RAVEL de la CENI
- Application Web complémentaire pour les bureaux de vote

**Long terme :**
- Adoption officielle par la CENI mauritanienne
- Extension aux autres pays d'Afrique de l'Ouest ayant des défis similaires

### 8.4 Conclusion Générale

Ce projet démontre la faisabilité technique d'un système de vote électronique mobile adapté aux contraintes spécifiques de la Mauritanie. En combinant la puissance de Flutter pour l'expérience multilingue (arabe RTL, français, Pulaar), la robustesse de Supabase pour la sécurité des données électorales et une architecture MVVM maintenable, MauriVote offre une base solide pour moderniser le processus démocratique mauritanien.

Les résultats des tests — 0 vulnérabilité critique, p95 < 2s pour 2000 utilisateurs simultanés, score UAT de 4.1/5 — confirment que la solution est techniquement prête pour un déploiement pilote, sous réserve d'un cadre législatif adapté et d'une intégration officielle avec les systèmes de la CENI.

---

## BIBLIOGRAPHIE

[1] CENI Mauritanie. (2024). Rapport annuel de la Commission Électorale Nationale Indépendante. Nouakchott.

[2] Springall, D., et al. (2014). Security Analysis of the Estonian Internet Voting System. ACM CCS 2014.

[3] OWASP Foundation. (2024). OWASP Mobile Application Security Testing Guide (MASTG). v2.0.

[4] Supabase Inc. (2024). Supabase Documentation. https://supabase.com/docs

[5] Google LLC. (2024). Flutter Documentation. https://flutter.dev/docs

[6] IFES. (2024). Electoral Risk Management Tool — Mauritania Profile.

[7] Conseil de l'Europe. (2017). Recommandation CM/Rec(2017)5 sur les normes relatives au vote électronique.

[8] Commission Européenne. (2016). Règlement (UE) 2016/679 (RGPD). Journal officiel de l'Union européenne.

[9] Riverpod. (2024). Riverpod Documentation. https://riverpod.dev

[10] k6 Labs. (2024). k6 Performance Testing Documentation. https://k6.io/docs

---

*Mémoire soumis le [Date] — [Université/École] — [Ville], Mauritanie*
*Sous la direction de [Encadrant] — Jury : [Membres du jury]*
