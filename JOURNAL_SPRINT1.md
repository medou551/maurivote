# 📓 Journal de Bord — Sprint 1 (J1–J7)
## Application MauriVote — Vote Électronique Mauritanie

---

## 📅 JOUR 1 — Fondations & Infrastructure

### ⚙️ Développement
- ✅ Structure projet Flutter créée (MVVM, 50+ dossiers)
- ✅ `pubspec.yaml` avec 30+ dépendances (Supabase, Riverpod, GoRouter, fl_chart…)
- ✅ `main.dart` — initialisation Supabase + Hive + Firebase
- ✅ `app.dart` — MaterialApp + GoRouter + multilingue (ar/fr/ff)
- ✅ `app_theme.dart` — Thème Material 3, couleurs mauritaniennes (vert #1B5E20, or #F9A825)
- ✅ `app_router.dart` — Navigation GoRouter + guards d'authentification
- ✅ `constants.dart` — Toutes les constantes (NNI, OTP, wilayas, animations…)
- ✅ `splash_screen.dart` — Animation logo + vérification session
- ✅ `login_screen.dart` — Formulaire NNI avec validation
- ✅ `models/models.dart` — Voter, Election, Candidate, Vote, Bureau, Resultat
- ✅ `crypto_utils.dart` — AES-256-CBC, HMAC-SHA256, génération IVs sécurisés
- ✅ `validators.dart` — Validation NNI, téléphone mauritanien, UUID

### 🌐 Réseaux
- ✅ Projet Supabase créé (région EU-West Paris — latence optimale)
- ✅ Migration `001_schema_initial.sql` — 8 tables, types ENUM, contraintes
- ✅ RLS activé sur toutes les tables (10 politiques définies)
- ✅ Triggers PostgreSQL — log_vote_attempt (immuable), updated_at
- ✅ Vue `resultats_publics` — agrégation sécurisée sans accès direct à votes
- ✅ Edge Function `submit-vote` — Deno TypeScript, signature HMAC, anti-double-vote

### 🚀 DevOps
- ✅ Dépôt GitHub initialisé (main/develop/feature/* branching)
- ✅ `.gitignore` — protection des fichiers sensibles (.env, *.jks, clés)
- ✅ GitHub Actions `ci_cd.yml` — CI (analyze + test + build) → Staging → Production
- ✅ `.env.example` — Template complet des variables d'environnement

**Livrables J1 :** Structure projet + Schéma BDD + Pipeline CI de base

---

## 📅 JOUR 2 — Connexion Supabase + Écrans Auth + Offline

### ⚙️ Développement
- ✅ `otp_screen.dart` — 6 champs PIN, compte à rebours 120s, 3 tentatives max
- ✅ `biometric_screen.dart` — Détection empreinte/Face ID, fallback PIN
- ✅ `onboarding_screen.dart` — 3 slides (Sécurité/Simplicité/Résultats)
- ✅ `home_screen.dart` — Liste élections, filtres (Toutes/En cours/À venir/Terminées), shimmer
- ✅ `elections_viewmodel.dart` — 6 providers Riverpod
- ✅ `election_service.dart` — CRUD Supabase + cache Hive offline + prefetch
- ✅ `realtime_service.dart` — WebSocket Supabase Realtime, abonnement résultats
- ✅ `offline_service.dart` — Queue votes offline, sync auto au retour réseau
- ✅ `notification_service.dart` — Firebase Cloud Messaging, topics par élection
- ✅ `election_card.dart` — Card élection avec badge statut, barre progression
- ✅ `connectivity_banner.dart` — Bannière mode hors-ligne

### 🌐 Réseaux
- ✅ Migration `002_seed_test_data.sql` — 15 wilayas, 9 communes NKT, 4 bureaux, 2 électeurs test
- ✅ Élection présidentielle test avec 4 candidats en BDD
- ✅ Edge Function `verify-vote` — Vérification QR sans révéler le candidat
- ✅ Workflow GitHub Actions `network_validation.yml` — Tests connectivité + Edge Functions
- ✅ CORS configuré, RLS testés, rate limiting défini

### 🚀 DevOps
- ✅ Tests d'intégration ajoutés au pipeline CI
- ✅ Déploiement auto Edge Functions sur push develop
- ✅ `analysis_options.yaml` — 20+ règles lint strictes
- ✅ Alertes Slack sur échec pipeline

**Livrables J2 :** Flux auth complet + données test + Realtime service

---

## 📅 JOUR 3 — Auth Singleton + Tests J3 + Latence Réseau

### ⚙️ Développement
- ✅ `auth_service.dart` refactorisé → **Singleton SupabaseAuthService**
  - NNI → RAVEL → OTP SMS Twilio +222 → JWT → Session timeout 15 min
  - Blocage après 3 tentatives OTP échouées (30 min)
  - Refresh JWT automatique si < 5 min d'expiration
  - `recordActivity()` — mise à jour du timestamp d'inactivité
  - `resendOtp()` — renvoi sans ressaisir NNI
- ✅ `auth_viewmodel.dart` mis à jour — états blocked, blockRemaining, resendOtp
- ✅ `election_detail_screen.dart` — Candidats avec photos, biographies, bouton voter
- ✅ 57 tests unitaires dans `j3_complete_test.dart`

### 🌐 Réseaux
- ✅ Migration `003_test_rls_policies.sql` — Tests complets des 10 politiques RLS
  - Vérification accès refusé sur table votes
  - Test immuabilité audit_logs
  - Test contrainte double vote
  - Rapport de sécurité final
- ✅ `network_latency_test.sh` — Tests latence HTTPS/TLS/DNS Mauritanie → Paris
  - 5 tests : DNS, Ping, Latence HTTPS (10 mesures), SSL/TLS, sécurité API
  - Rapport auto-généré avec timestamps
- ✅ `supabase/config.toml` — Configuration Supabase CLI complète
  - Auth SMS Twilio, Edge Functions JWT, OTP sans signup

### 🚀 DevOps
- ✅ `secrets_setup.sh` — Script configuration secrets GitHub Actions
  - 15 secrets (Supabase dev/staging/prod, Twilio, Maps, Slack, Codecov…)
  - Guide interactif avec prompts sécurisés

**Livrables J3 :** Auth singleton + Tests RLS + Script latence réseau

---

## 📅 JOUR 4 — Module Vote Complet

### ⚙️ Développement
- ✅ `vote_screen.dart` — Interface de vote
  - Sélection candidat avec animation (haptic feedback)
  - Dialogue de confirmation double obligatoire
  - Soumission via VoteService (AES-256 chiffrement)
  - Gestion erreurs : double vote, élection fermée, session expirée
- ✅ `vote_receipt_screen.dart` — Reçu de vote
  - QR Code généré avec qr_flutter (format maurivote://verify/HASH)
  - Animation de succès animée (scale + fade)
  - Hash tronqué affiché (sécurité)
  - Boutons Copier + Partager + Retour accueil

**Livrables J4 :** Flux vote complet de la sélection au reçu QR

---

## 📅 JOUR 5 — Profil Électeur + Bureau de Vote

### ⚙️ Développement
- ✅ `profil_screen.dart` — Profil complet
  - Avatar avec initiale, badge "Électeur vérifié"
  - NNI masqué (1234****90), téléphone masqué
  - Sections : infos personnelles, infos électorales, paramètres
  - Lien bureau de vote, CENI, myceni.org
  - Dialogue de déconnexion confirmé
- ✅ `bureau_vote_screen.dart` — Bureau de vote
  - Placeholder carte Google Maps (intégration J12)
  - Infos bureau : nom, adresse, horaires, accessibilité PMR
  - Bouton itinéraire Google Maps (url_launcher)

**Livrables J5 :** Profil électeur complet + navigation bureau de vote

---

## 📅 JOUR 6 — Résultats Temps Réel + Graphiques

### ⚙️ Développement
- ✅ `resultats_screen.dart` — Dashboard résultats
  - Badge "En direct" avec dot animé pulsant
  - Graphique camembert fl_chart avec animations
  - Barres de progression animées (TweenAnimationBuilder)
  - Combinaison résultats statiques + WebSocket Realtime
  - Écran liste pour toutes les élections terminées

**Livrables J6 :** Dashboard résultats temps réel avec graphiques

---

## 📅 JOUR 7 — Admin CENI + Router Final + Journal

### ⚙️ Développement
- ✅ `admin_dashboard_screen.dart` — Interface CENI
  - Statistiques : 1 939 341 électeurs, 3 847 bureaux, 15 wilayas
  - Gestion des élections (liste + popup actions)
  - Actions rapides : audit logs, export CSV, notifications, rapport
  - Accès restreint par rôle `ceni_admin`
- ✅ `app_router.dart` mis à jour — Imports corrects tous les vrais écrans

### 🚀 DevOps
- ✅ `JOURNAL_SPRINT1.md` — Journal de bord complet J1–J7

---

## 📊 Bilan Sprint 1

| Indicateur | Valeur |
|---|---|
| Fichiers créés | **45+** |
| Lignes de code | **~8 500** |
| Écrans Flutter | **14** (splash, onboarding, login, otp, biometric, home, election_detail, vote, receipt, resultats, profil, bureau, admin) |
| Services Flutter | **7** (auth, vote, election, realtime, offline, notification, crypto) |
| ViewModels Riverpod | **3** (auth, elections, resultats) |
| Migrations SQL | **3** (schéma, seed, tests RLS) |
| Edge Functions Deno | **2** (submit-vote, verify-vote) |
| Workflows GitHub Actions | **2** (ci_cd, network_validation) |
| Tests unitaires | **57** |
| Politiques RLS | **10** |

## ✅ Définition of Done — Sprint 1

- [x] Authentification NNI + OTP SMS fonctionnelle
- [x] Vote chiffré AES-256 implémenté
- [x] Double vote bloqué (contrainte UNIQUE + Edge Function)
- [x] Résultats temps réel via WebSocket
- [x] Mode hors-ligne avec sync différée
- [x] Pipeline CI/CD opérationnel
- [x] RLS Supabase sur toutes les tables
- [x] 57 tests unitaires (cible 60% couverture)
- [x] Architecture MVVM documentée
- [x] Journal de sprint complet

## 🎯 Sprint 2 — Objectifs (J8–J14)

- Intégration Google Maps bureau de vote (J12)
- Multilingue complet Arabe RTL + Pulaar (J17)
- Tests d'intégration Flutter sur émulateur
- Stress test k6 1000 utilisateurs simultanés
- Monitoring Grafana + alertes Supabase
