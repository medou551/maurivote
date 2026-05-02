# 📓 Journal de Bord — Sprint 2 (J8–J14)
## Application MauriVote — Vote Électronique Mauritanie

---

## 📅 JOUR 8 — VoteViewModel + Edge Function check-voted

### ⚙️ Développement
- ✅ `vote_viewmodel.dart` — Provider Riverpod complet pour le vote
  - `voteStateProvider` — StateNotifier avec états: idle/loading/success/alreadyVoted/electionClosed/offline/error
  - Détection automatique du mode offline → file d'attente Hive
  - `hasVotedProvider` — FutureProvider.family pour vérifier si déjà voté
  - `HasVotedQuery` — Value object avec égalité et hashCode
  - Intégration `OfflineService` pour la synchronisation différée
- ✅ `selectedCandidateProvider` — StateProvider pour la sélection en cours

### 🌐 Réseaux
- ✅ Edge Function `check-voted/index.ts` — Vérification statut de vote
  - JWT obligatoire, voter_hash + election_id + tour en paramètres
  - Retourne `has_voted: bool` + `voted_at: timestamp` sans révéler le candidat
  - Déployée : `supabase functions deploy check-voted`

**Livrables J8 :** VoteViewModel complet + 3ème Edge Function

---

## 📅 JOUR 9 — Écran Confirmation Vote

### ⚙️ Développement
- ✅ `vote_confirmation_screen.dart` — Confirmation avant soumission finale
  - Photo du candidat (CircleAvatar avec fallback initiale)
  - 2 cases à cocher obligatoires (consentement + compréhension)
  - Avertissement visuel "vote irrévocable"
  - Animation d'entrée avec flutter_animate
  - Gestion état offline : message explicatif + queue automatique
  - `ref.listen` sur voteStateProvider → navigation auto vers le reçu
  - Coleur du bouton = couleur du parti du candidat

**Livrables J9 :** Confirmation vote avec double consentement

---

## 📅 JOUR 10 — Internationalisation Complète (AR/FR/Pulaar)

### ⚙️ Développement
- ✅ `lib/l10n/app_fr.arb` — 80+ clés de traduction en français
  - Couvre : auth, vote, résultats, profil, erreurs, navigation, types élections
  - Paramètres localisés : `{phone}`, `{tour}`, `{count}`, `{total}`
- ✅ `lib/l10n/app_ar.arb` — Traductions arabes complètes
  - Écriture RTL (droite-à-gauche)
  - Terminologie officielle mauritanienne (CENI, NNI, wilayas…)
  - Polices Cairo pour l'arabe
- ✅ `lib/l10n/app_ff.arb` — Traductions Pulaar (Fula/Peul)
  - Langue nationale de ~33% de la population mauritanienne
  - Adaptation culturelle des termes électoraux

**Commandes d'activation :**
```bash
flutter pub get
flutter gen-l10n   # Génère lib/l10n/app_localizations.dart
```

**Livrables J10 :** 3 langues × 80+ clés — AR (RTL) + FR + Pulaar

---

## 📅 JOUR 11 — Tests d'Intégration Flutter

### 🧪 Tests
- ✅ `integration_test/app_test.dart` — 9 tests d'intégration
  - T01 : Démarrage app → Splash Screen visible
  - T02 : Onboarding → 3 slides navigables par swipe
  - T03 : Login → validation NNI incorrect affiche erreur
  - T04 : Login → NNI avec lettres filtré automatiquement
  - T05 : OTP Screen → structure de l'interface
  - T06 : ConnectivityBanner → présent dans le widget tree
  - T07 : Thème → couleur primaire verte mauritanienne (#1B5E20)
  - T08 : Locale → français par défaut
  - T09 : BottomNavigationBar → 3 onglets
  - PERF01 : Démarrage en moins de 5 secondes
  - PERF02 : Scroll ListView sans crash

**Exécution :**
```bash
flutter test integration_test/app_test.dart -d emulator-5554
```

**Livrables J11 :** 9 scénarios d'intégration + 2 tests de performance

---

## 📅 JOUR 12 — Tests de Charge k6 + Simulation Journée Électorale

### 🌐 Réseaux + Tests
- ✅ `tests/load/k6_vote_load_test.js` — Tests de charge complets
  - **4 scénarios simultanés** :
    - `navigation_load` : 200 users × 9 min (lecture élections/candidats)
    - `pic_ouverture` : Montée à 1000 users (simulation 07h00)
    - `pic_fermeture` : Montée à 2000 users (simulation 17h30)
    - `resultats_realtime` : 100 users × 40 min (polling résultats)
  - **Métriques personnalisées k6** : vote_success_rate, vote_errors_total, vote_duration_ms
  - **Seuils de qualité** : p95 < 2s, p99 < 3s, erreurs < 1%, votes OK > 95%
  - **Rapport JSON automatique** généré en fin de test
  - Mix réaliste : 70% navigation / 30% votes

**Exécution :**
```bash
k6 run \
  --env SUPABASE_URL=$SUPABASE_URL \
  --env SUPABASE_ANON_KEY=$ANON_KEY \
  --env TEST_ELECTION_ID=$UUID \
  --env TEST_JWT=$JWT \
  tests/load/k6_vote_load_test.js
```

**Livrables J12 :** Tests de charge 4 scénarios + métriques + rapport auto

---

## 📅 JOUR 13 — Monitoring Grafana + Dashboard Production

### 🚀 DevOps
- ✅ `tests/monitoring/grafana_dashboard.json` — Dashboard Grafana complet
  - **11 panels** couvrant :
    - Votes/minute en temps réel (timeseries)
    - Latence p95 Edge Function submit-vote (gauge)
    - Taux de succès des votes (stat)
    - Connexions PostgreSQL actives vs maximum
    - Requêtes REST API + erreurs 5xx
    - Votes totaux par candidat (bargauge)
    - Tentatives double vote bloquées
    - Violations RLS (alerte si > 0)
    - Électeurs connectés simultanément (WebSocket)
    - Stockage Supabase utilisé
    - Participation par wilaya (table colorée)
  - Annotations automatiques : ouverture/fermeture bureaux de vote
  - Refresh : 30 secondes

**Import Grafana :**
```bash
# Via API Grafana
curl -X POST http://grafana:3000/api/dashboards/import \
  -H "Content-Type: application/json" \
  -d @tests/monitoring/grafana_dashboard.json
```

**Livrables J13 :** Dashboard Grafana 11 panels + annotations électorales

---

## 📅 JOUR 14 — Tests Sprint 2 + Revue + Journal

### 🧪 Tests
- ✅ `test/j8_j14_sprint2_test.dart` — Tests unitaires Sprint 2
  - **VotePayload** : 5 tests (sérialisation, voter_hash 64 chars, recu_hash unique, candidat absent du chiffré, 30 IVs distincts)
  - **HasVotedQuery / CandidateQuery** : 6 tests (égalité, hashCode, valeurs par défaut)
  - **VoteState** : 5 tests (initial, copyWith, offline, statuts distincts)
  - **Election — cas limites** : 7 tests (frontières isVotable, type inconnu, statut inconnu, tous typeLabel)
  - **Validators supplémentaires** : 5 tests (email, frontières de temps)
  - **Flux vote complet simulé** : 3 tests end-to-end (payload valide, électeurs distincts, élections distinctes)

**Total Sprint 2 :** 31 nouveaux tests unitaires

**Livrables J14 :** Tests Sprint 2 + Journal complet

---

## 📊 Bilan Sprint 2

| Indicateur | Sprint 1 | +Sprint 2 | Total |
|---|---|---|---|
| Fichiers | 45 | +15 | **60** |
| Lignes de code | 8 462 | +3 100 | **~11 560** |
| Écrans Flutter | 12 | +1 (confirmation) | **13** |
| ViewModels | 3 | +1 (vote) | **4** |
| Edge Functions | 2 | +1 (check-voted) | **3** |
| Tests unitaires | 57 | +31 | **88** |
| Tests intégration | 0 | +9 | **9** |
| Fichiers ARB (i18n) | 0 | +3 | **3 langues** |
| Scénarios k6 | 0 | +4 | **4 scénarios** |
| Panels Grafana | 0 | +11 | **11** |

## ✅ Définition of Done — Sprint 2

- [x] VoteViewModel complet avec gestion offline
- [x] Confirmation vote avec double consentement
- [x] 3 langues complètes : FR + AR (RTL) + Pulaar — 80+ clés chacune
- [x] Edge Function check-voted déployée
- [x] 9 tests d'intégration Flutter
- [x] Tests de charge k6 — 4 scénarios, jusqu'à 2000 users simultanés
- [x] Dashboard Grafana production — 11 panels
- [x] 88 tests unitaires au total (+31 ce sprint)
- [x] Journal de sprint complet

## 🎯 Sprint 3 — Objectifs (J15–J21)

- Résultats temps réel WebSocket validés et optimisés
- Carte choroplèthe des résultats par wilaya (flutter_map + GeoJSON)
- Tests de pénétration (OWASP ZAP, Burp Suite)
- Mode hors-ligne complet avec retry automatique
- Interface admin CENI — création/modification d'élections
- Rapport de sécurité réseau complet
